#!/usr/bin/env python3
#
#  torille.py
#  Provides Python API to Toribash (i.e. can control the characters)
#
#  Author: Anssi "Miffyli" Kanervisto, 2018
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#  
import socket
import math
import numpy as np
import random as r
import subprocess
from multiprocessing import Lock
import sys
import os
from collections import OrderedDict
import pprint
from filelock import FileLock
import warnings
from copy import deepcopy

def create_random_actions():
    """ Return random actions for ToribashControl """
    ret = [[],[]]
    for plridx in range(2):
        for jointidx in range(ToribashConstants.NUM_CONTROLLABLES):
            ret[plridx].append(r.randint(1,4))
    return ret

def check_linux_sanity():
    """ 
    A helper function that checks Linux environment
    for requirements, and warns/throws accordingly
    """

    # Check that we have a valid display to render into.
    # We rather avoid running over SSH
    display = os.getenv("DISPLAY")
    if display is None:
        raise Exception("No display detected. "+
            "Toribash won't launch without active display. "+
            "If you have a monitor attached, set environment variable "+
            "DISPLAY to point at it (e.g. `export DISPLAY=:0`)")
    if display[0] != ":":
        warnings.warn(
            "Looks like you have X-forwarding enabled. "+
            "This makes Toribash very slow and sad. "+
            "Consider using virtual screen buffer like Xvfb. "+
            "More info at the Github page https://github.com/Miffyli/ToriLLE"
        )

    # Check Wine version: We need recent enough version, otherwise
    # game won't run
    wine_version = None
    try:
        wine_version = subprocess.check_output(("wine", "--version")).decode()[:-1]
    except FileNotFoundError:
        raise Exception("Recent version of Wine is required to run Toribash. "+
                        "Tested to work on Wine version 3.0.3")
    if wine_version is not None:
        major_version = int(wine_version[5])
        if wine_version[0] == 1:
            raise Exception(
                "Detected Wine version 1.x. "+
                "Toribash does not run on old versions of Wine. "+
                "Toribash is tested to work on Wine versions 3.0.3"
            )

class ToribashConstants:
    """ 
    Class for holding general constants.
    These are not designed to be modified during runtime
    """
    # Port where Toribashes connect to
    PORT = 7788
    # Global timeout (in seconds) for connections
    TIMEOUT = 300
    # Buffer size (for recv)
    BUFFER_SIZE = 8096
    # Line ending character
    MESSAGE_END = "\n".encode()

    # "Limb" or "Bodypart"
    NUM_LIMBS = 21
    NUM_JOINTS = 20
    # Add hand_grips
    NUM_CONTROLLABLES = NUM_JOINTS+2
    NUM_JOINT_STATES = 4
    # Number of setting variables
    NUM_SETTINGS = 19

    # Bodypart x,y,z + Joint states + hand grips + injuries
    STATE_LENGTH = (NUM_LIMBS*3*2) + NUM_JOINTS*2 + 4 + 2

    # Path to Toribash supplied with the wheel package
    # This should be {this file}/toribash/toribash.exe
    my_dir = os.path.dirname(os.path.realpath(__file__))
    TORIBASH_EXE = os.path.join(my_dir, "toribash", "toribash.exe")

class ToribashState:
    """ 
    Class for storing and processing the state representations
    from Toribash 
    """
    def __init__(self, state):
        # Limb locations
        # For both players, for all limbs, x,y,z coordinates
        self.limb_positions = np.zeros((2,ToribashConstants.NUM_LIMBS,3))
        # Joint states (including hands)
        # For both players
        self.joint_states = np.zeros((2,ToribashConstants.NUM_CONTROLLABLES))
        # Amount of injury of players 
        # For both players
        self.injuries = np.zeros((2,))
        
        self.process_list(state)
        
    def process_list(self, state_list):
        """ Updates state representations according to given list of 
        variables from Toribash """
        # Indexes from  state_structure.md
        # Limbs
        self.limb_positions[0] = np.array(state_list[:63]).reshape(
                                        (ToribashConstants.NUM_LIMBS,3))
        self.limb_positions[1] = np.array(state_list[86:149]).reshape(
                                        (ToribashConstants.NUM_LIMBS,3))
        # Joint states (inc. hand grips)
        self.joint_states[0] = np.array(state_list[63:85], dtype=np.int)
        self.joint_states[1] = np.array(state_list[149:171], dtype=np.int)
        # Injuries
        self.injuries[0] = state_list[85]
        self.injuries[1] = state_list[171]

class ToribashSettings:
    """ Class for storing and processing settings for Toribash """
    
    # Default settings
    DEFAULT_SETTINGS = OrderedDict([
        ("matchframes", 500),
        ("turnframes", 10), 
        ("engagement_distance", 100),
        ("engagement_height", 0),
        ("engagement_rotation", 0),
        ("gravity_x", 0.0),
        ("gravity_y", 0.0),
        ("gravity_z", -9.81),
        ("damage", 0),
        ("dismemberment_enable", 1),
        ("dismemberment_threshold", 100),
        ("fractures_enable", 0),
        ("fractures_threshold", 0),
        ("disqualification_enabled", 0), 
        ("disqualification_flags", 0),           
        ("disqualification_timeout", 0),  
        ("dojo_type", 0),
        ("dojo_size", 0),
        ("replay_file", None)
    ])
    
    def __init__(self, **kwargs):
        """ Create new settings, kwargs can be used to define settings """
        self.settings = []
        
        # Get settings from function call, otherwise get them from 
        # default settings
        for k,v in ToribashSettings.DEFAULT_SETTINGS.items():
            self.settings.append(kwargs.get(k,v))
    
    def validate_settings(self):
        """ 
        Checks that current given settings are valid for Toribash.
        Otherwise Toribash will go quiet, pout and then disappear :(
        """
        # First 18 should be numbers
        for i,value in enumerate(self.settings[:18]):
            if not type(value) in (float, int): 
                raise ValueError(("Setting {} was not of correct type: "+
                    "Expected float/int, got {}").format(
                        list(ToribashSettings.DEFAULT_SETTINGS.keys())[i], 
                        type(value)
                    )
                )
        
        # 2nd value (turnframes) should be from interval [2,matchframes]
        if self.settings[1] < 2 or self.settings[1] > self.settings[0]:
            raise ValueError("Setting 'turnframes' should be from interval "+
                          "[2,matchframes].")

        # 19th value should be a string or None
        if self.settings[18] is not None: 
            if type(self.settings[18]) != str:
                raise ValueError("Setting 'replay_file' should be str or None,"+
                                 " got %s" % type(self.settings[18])
                )
            
            # Remove commas from 19th value
            if "," in self.settings[18]:
                warnings.warn("Commas ',' are not supported in settings. "+
                              "Removing.")
                self.settings[18] = self.settings[18].replace(",", "")
    
    def set(self, key, value):
        """ Set given setting to value """
        self.settings[list(ToribashSettings.DEFAULT_SETTINGS.keys()
                           ).index(key)] = value
        
    def get(self, key):
        """ Get current value of the setting """
        return self.settings[list(ToribashSettings.DEFAULT_SETTINGS.keys()
                                  ).index(key)]
    
    def __str__(self):
        return pprint.pformat(dict([(k,v) for k,v in zip(
                                    ToribashSettings.DEFAULT_SETTINGS.keys(),
                                    self.settings)]))
    
class ToribashControl:
    """ Main class controlling one instance of Toribash """
    def __init__(self, 
                 settings=None, 
                 draw_game=False,
                 executable=ToribashConstants.TORIBASH_EXE, 
                 port=ToribashConstants.PORT):
        """ 
        Parameters:
            settings: ToribashSettings instance. Uses these settings if 
                      provided, else defaults to default settings.
            draw_game: If True, will render the game and limit the FPS.
                       Defaults to False.
            executable: String of path to the toribash.exe launching the game.
                        Defaults to path used with pip-installed package.
            port: Port used to listen for connections from Toribash.
                  Defaults to ToribashConstants.PORT.
                  NOTE: You have to change port in Toribash Lua script as well!
                        (in {toribash dir}/data/script/remotecontrol.lua )
        """
        self.executable_path = executable
        # Make sure exe exists
        if not os.path.isfile(self.executable_path):
            raise ValueError("Toribash executable path is not a file: %s" % 
                             self.executable_path)
        self.process = None
        self.connection = None
        self.port = port

        # Lets create FileLock file next to toribash.exe
        # Actual FileLock will be done in init() to keep
        # this object pickleable (serializable)
        self.lock_file = os.path.join(os.path.dirname(executable), ".launchlock")

        self.draw_game = draw_game
        self.settings = settings
        if self.settings is None:
            self.settings = ToribashSettings()

        # Used as a watchdog to make sure 
        # anybody calling using this interface
        # calls `reset` at appropiate times
        self.requires_reset = False
    
    def _check_if_initialized(self):
        if self.process is None:
            raise ValueError("Controlled not initialized with `init()`")
    
    def init(self):
        """ 
        Actual init: Launch the game process, wait for connection and
        and settings for the first game
        """
        # Use global filelock to avoid mixing up Toribash instances with 
        # corresponding Python scripts if we have multiple Toribashes running.
        # Create lock here to make code pickle-able before call to init.
        init_lock = FileLock(self.lock_file, 
                             timeout=ToribashConstants.TIMEOUT)
        with init_lock:
            if sys.platform == "linux":
                # Sanity check launching on Linux
                check_linux_sanity()
                # Add wine command explicitly for running on Linux
                self.process = subprocess.Popen(("nohup", "wine", self.executable_path), 
                                             stdout=subprocess.DEVNULL, 
                                             stderr=subprocess.DEVNULL)
            else:
                self.process = subprocess.Popen((self.executable_path,), 
                                                stdout=subprocess.DEVNULL, 
                                                stderr=subprocess.DEVNULL)
            # Create socket for waiting for Toribash to connect
            s = socket.socket()
            # This allows rebinding to same address multiple times on *nix
            # Otherwise you will get "address in use" if you launch multiple
            # Toribash instances on same computer
            # From Stackoverflow #6380057
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s.bind(("",self.port))
            s.settimeout(ToribashConstants.TIMEOUT)
            s.listen(1)
            conn, addr = s.accept()
            # Close the listener socket
            s.close()
            
            # Set the timeout for connection 
            conn.settimeout(ToribashConstants.TIMEOUT)
            self.connection = conn
        # Send handshake 
        self._send_comma_list([int(self.draw_game)])
        # Send initial settings
        self.settings.validate_settings()
        self._send_comma_list(self.settings.settings)

    def close(self):
        """ Close the running Toribash instance and clean up """
        self._check_if_initialized()
        self.connection.close()
        # No need to be gentle here
        self.process.kill()

    def _recv_line(self, s):
        """ 
        Call recv till data ends with ToribashConstant.MESSAGE_END
        """
        # First wait till there is something to read
        ret = s.recv(ToribashConstants.BUFFER_SIZE)
        # Now check if we had "\n", and continue reading till we have it
        while ret[-1:] != ToribashConstants.MESSAGE_END:
            ret += s.recv(ToribashConstants.BUFFER_SIZE)
        return ret
    
    def _recv_state(self):
        """ 
        Read state from Toribash
        Returns:
            State: List of floats representing the state of the game 
            Terminal: Boolean indicating if this is the final state of game
        """
        s = self._recv_line(self.connection).decode()
        terminal = s.startswith("end")
        if terminal:
            # Remove first three characters + comma to parse the state
            s = s[4:]
            # Allow calling reset next
            self.requires_reset = True
        s = list(map(float, s.split(",")))
        # Make sure we got list of correct length
        if len(s) != ToribashConstants.STATE_LENGTH:
            raise ValueError(("Got state of invalid size. Expected %d, got %d"+
                             "\nState: %s") %
                             (ToribashConstants.STATE_LENGTH, len(s), s))
        return s, terminal
        
    def _send_comma_list(self, data):
        """ 
        Send given list to Toribash as comma-separated list
        Parameters:
            data: List of values to be sent
        """
        # We need to add end of line for the luasocket "*l"
        data = ",".join(map(str, data)) + "\n"
        self.connection.sendall(data.encode())
        
    def get_state(self):
        """ 
        Return state of the game (in prettier format)
        Returns:
            state: ToribashState representing the received state
            terminal: If the ToribashState is terminal state
        """
        self._check_if_initialized()
        
        s, terminal = self._recv_state()
        s = ToribashState(s)
        return s, terminal
    
    def reset(self):
        """ 
        Reset the game by sending settings for next round
        Returns:
            state: ToribashState representing the state of new game
        """
        self._check_if_initialized()

        # Make sure we are allowed to do a reset
        if not self.requires_reset:
            raise Exception("Calling `reset()` is only allowed "+
                            "after terminal states")

        # Validate settings
        self.settings.validate_settings()

        self._send_comma_list(self.settings.settings)
        s,terminal = self.get_state()
        self.requires_reset = False
        return s
    
    def validate_actions(self, actions):
        """ 
        Check the validity of given actions (correct shape, correct range, 
        etc) and throw errors accordingly
        Parameters:
            actions: List of shape 2 x (NUM_JOINTS+2), specifying joint states 
                     and hand gripping for both players.
        Returns:
            None. Raises an error if action is not valid
        """
        # Make sure we have lists
        if type(actions) != list and type(actions) != tuple:
            raise ValueError("Actions should be a List (e.g. not numpy array)")
        
        # Check we have actions for both players
        # Should probably check types of the elements too..
        if len(actions) != 2:
            raise ValueError("Actions should be a List of two lists")
        
        # Check that we have correct number of states
        if (len(actions[0]) != ToribashConstants.NUM_CONTROLLABLES or 
                len(actions[1]) != ToribashConstants.NUM_CONTROLLABLES):
            raise ValueError("Actions should be a List of shape 2 x %d"%
                             NUM_CONTROLLABLES)
        
        # Check that all joint states are in {1,2,3,4}
        for i in range(ToribashConstants.NUM_CONTROLLABLES):
            # Check both players at the same time
            if (actions[0][i] > 4 or actions[0][i] < 1 or actions[1][i] > 4 or
                    actions[1][i] < 1):
                raise ValueError("Joint states should be in {1,2,3,4}")
    
    def make_actions(self, actions):
        """ 
        Send given list of actions to the server.
        Parameters:
            actions: List of shape 2 x NUM_CONTROLLABLES, specifying joint states 
                     and hand gripping for both players.
        """
        self._check_if_initialized()

        # Make sure we are allowed to make actions
        if self.requires_reset:
            raise Exception("`reset()` must called after terminal state")
        
        # Validate actions, let it throw errors
        self.validate_actions(actions)
        
        # Create deepcopy of the actions list 
        # because we are about to modify it
        actions = deepcopy(actions)

        # Modify hand grips to be {0,1} rather than {1,2,3,4}
        # Map {1,2} -> 0 , {3,4} -> 1
        actions[0][-2] = 0 if actions[0][-2] < 3 else 1 
        actions[0][-1] = 0 if actions[0][-1] < 3 else 1 
        actions[1][-2] = 0 if actions[1][-2] < 3 else 1 
        actions[1][-1] = 0 if actions[1][-1] < 3 else 1 

        # Concat lists into one 
        actions = actions[0]+actions[1]

        self._send_comma_list(actions)
    
    def get_state_dim(self):
        """ Return size of state space per character """
        return ToribashConstants.NUM_LIMBS*3
    
    def get_num_joints(self):
        """ Return number of controllable joints """
        return ToribashConstants.NUM_CONTROLLABLES
    
    def get_num_joint_states(self):
        """ Return number of states each joint can have """
        return ToribashConstants.NUM_JOINT_STATES
    
    def __del__(self):
        """ 
        Destructor to close running Toribash process.
        There is no point in keeping Toribash alive without the controller...
        """
        if self.process is not None:
            self.close()

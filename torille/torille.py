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

class ToribashConstants:
    """ Class for holding general constants """
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
    NUM_SETTINGS = 18

    # Bodypart x,y,z + Joint states + hand grips + injuries
    STATE_LENGTH = (NUM_LIMBS*3*2) + NUM_JOINTS*2 + 4 + 2

    # Path to Toribash supplied with the wheel package
    # This should be {this file}/toribash/toribash.exe
    my_dir = os.path.dirname(os.path.realpath(__file__))
    TORIBASH_EXE = os.path.join(my_dir, "toribash", "toribash.exe")

class ToribashState:
    """ Class for storing and processing the state representations
    from Toribash """
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
        ("dojo_size", 0)
    ])
    
    def __init__(self, **kwargs):
        """ Create new settings, kwargs can be used to define settings """
        self.settings = []
        
        # Get settings from function call, otherwise get them from 
        # default settings
        for k,v in ToribashSettings.DEFAULT_SETTINGS.items():
            self.settings.append(kwargs.get(k,v))
    
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
    def __init__(self, settings=None, 
                 executable=ToribashConstants.TORIBASH_EXE, 
                 port=ToribashConstants.PORT):
        """ 
        Parameters:
            settings: ToribashSettings instance. Uses these settings if 
                      provided, else defaults to default settings.
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

        # Lets create FileLock file next to toribash.exe
        # Actual FileLock will be done in init() to keep
        # this object pickleable (serializable)
        self.lock_file = os.path.join(os.path.dirname(executable), ".launchlock")

        self.settings = settings
        if self.settings is None:
            self.settings = ToribashSettings()
    
    def _check_if_initialized(self):
        if self.process is None:
            raise ValueError("Controlled not initialized with init()")
    
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
            # TODO processes won't die on Windows when Python exits,
            # even with tricks from Stackoverflow #12843903
            if sys.platform == "linux":
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
        # Send initial settings
        self._send_comma_list(self.settings.settings)

    def close(self):
        """ Close the running Toribash instance and clean up """
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
        """ Read state from Toribash
        Returns:
            State: List of floats representing the state of the game 
            Terminal: Boolean indicating if this is the final state of game
        """
        s = self._recv_line(self.connection).decode()
        terminal = s.startswith("end")
        if terminal:
            # Remove first three characters + comma to parse the state
            s = s[4:]
        s = list(map(float, s.split(",")))
        # Make sure we got list of correct length
        if len(s) != ToribashConstants.STATE_LENGTH:
            raise ValueError(("Got state of invalid size. Expected %d, got %d"+
                             "\nState: %s") %
                             (ToribashConstants.STATE_LENGTH, len(s), s))
        return s, terminal
        
    def _send_comma_list(self, data):
        """ Send given list to Toribash as comma-separated list
        Parameters:
            data: List of values to be sent
        """
        # We need to add end of line for the luasocket "*l"
        data = ",".join(map(str, data)) + "\n"
        self.connection.sendall(data.encode())
        
    def get_state(self):
        """ Return state of the game (in prettier format)
        Returns:
            state: ToribashState representing the received state
            terminal: If the ToribashState is terminal state
        """
        self._check_if_initialized()
        
        s, terminal = self._recv_state()
        s = ToribashState(s)
        return s, terminal
    
    def reset(self, settings=None):
        """ Reset the game by sending settings for next round
        Returns:
            state: ToribashState representing the state of new game
        """
        self._check_if_initialized()
        
        self._send_comma_list(self.settings.settings)
        s,terminal = self.get_state()
        return s
    
    def validate_actions(self, actions):
        """ Check the validity of given actions (correct shape, correct range, 
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
        
        # Modify hand grips to be {0,1} rather than {1,2,3,4}
        # Map {1,2} -> 0 , {3,4} -> 1
        actions[0][-2] = 0 if actions[0][-1] < 3 else 1 
        actions[1][-1] = 0 if actions[0][-2] < 3 else 1 
        actions[0][-2] = 0 if actions[1][-1] < 3 else 1 
        actions[1][-1] = 0 if actions[1][-2] < 3 else 1 
    
    def make_actions(self, actions):
        """ Send given list of actions to the server.
        Parameters:
            actions: List of shape 2 x (NUM_JOINTS+2), specifying joint states 
                     and hand gripping for both players.
        """
        self._check_if_initialized()
        
        # Validate actions, let it throw errors
        self.validate_actions(actions)
        
        # Concat lists into one 
        actions = actions[0]+actions[1]

        self._send_comma_list(actions)
    
    def step(self, actions):
        """ OpenAI-Gym-like step function. Executes actions and returns 
        new state and if state is terminal
        Parameters:
            actions: List of shape 2 x (NUM_JOINTS+2), specifying joint states 
                     and hand gripping for both players.
                     If None, do not attempt sending actions.
        Returns:
            state: ToribashState representing the state of game
            reward: None (for OpenAI-gym compatability) 
            terminal: Boolean indicating if provided state is final
            info: None (for OpenAI-Gym compatability)
        """
        self._check_if_initialized()
        
        if not actions is None:
            self.make_actions(actions)
        s, terminal = self.get_state()
        return s, None, terminal, None
    
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
        """ Destructor to close running Toribash process.
        There is no point in keeping Toribash alive without the controller..."""
        if self.process is not None:
            self.close()

def create_random_actions():
    """ Return random actions """
    ret = [[],[]]
    for plridx in range(2):
        for jointidx in range(ToribashConstants.NUM_CONTROLLABLES):
            ret[plridx].append(r.randint(1,4))
    return ret
    
def test_control(num_instances, verbose=False):
    from time import time
    from threading import Lock
    
    verbose_print = lambda s: print(s) if verbose else None
    
    controllers = []
    
    verbose_print("Waiting connections from toribashes...")
    for i in range(num_instances):
        controller = ToribashControl()
        controller.settings.set("matchframes", 1000)
        controller.settings.set("turnframes", 1)
        controller.settings.set("engagement_distance", 1000)
        controller.init()
        controllers.append(controller)

    last_time = time()
    n_steps = 0
    num_rounds = 0
    while num_rounds < 2:
        states = []
        # Wait for state from all instances
        for i in range(num_instances):
            s,terminal = controllers[i].get_state()
            if terminal: 
                s = controllers[i].reset()
                num_rounds += 1
            states.append(s)
        verbose_print("Got states")
        for i in range(num_instances):
            actions = create_random_actions()
            controllers[i].make_actions(actions)
        verbose_print("Sent actions")
        n_steps += num_instances
        if n_steps >= 5000:
            print("FPS: %.2f" % (n_steps/(time()-last_time)))
            last_time = time()
            n_steps = 0
    for controller in controllers:
        controller.close()
    
if __name__ == '__main__':
    test_control(1)

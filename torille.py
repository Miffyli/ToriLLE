#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  toribash_control.py
#  Provides Python API to Toribash (i.e. can control the characters)
#
#  Author: Anssi "Miffyli" Kanervisto, 2018
#  
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
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
import numpy as np
import random as r
import subprocess
from multiprocessing import Lock
import sys

# Platform we are running on
PLATFORM = sys.platform

# Port where Toribashes connect to
PORT = 7788
# Global timeout (in seconds) for connections
TIMEOUT = 30
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

# Bodypart x,y,z + Joint states + hand grips + injuries
STATE_LENGTH = (NUM_LIMBS*3*2) + NUM_JOINTS*2 + 4 + 2

# This lock is used to avoid overlapping listening of incoming 
# connections
# TODO Wait... does this actually work with processes tho?
toribash_launch_lock = Lock()

class ToribashState:
    """ Class for storing and processing the state representations
    from Toribash """
    def __init__(self, state):
        # Limb locations
        # For both players, for all limbs, x,y,z coordinates
        self.limb_positions = np.zeros((2,NUM_LIMBS,3))
        # Joint states
        # For both players
        self.joint_states = np.zeros((2,NUM_JOINTS))
        # Hand grips for both players
        self.hand_grips = np.zeros((2,2))
        # Amount of injury of players
        self.plr0_injury = None
        self.plr1_injury = None
        
        self.process_list(state)
        
    def process_list(self, state_list):
        """ Updates state representations according to given list of 
        variables from Toribash """
        # Indexes from  state_structure.md
        # Limbs
        self.limb_positions[0] = np.array(state_list[:63]).reshape(
                                                            (NUM_LIMBS,3))
        self.limb_positions[1] = np.array(state_list[86:149]).reshape(
                                                            (NUM_LIMBS,3))
        # Joint states
        self.joint_states[0] = np.array(state_list[63:83], dtype=np.int)
        self.joint_states[1] = np.array(state_list[148:168], dtype=np.int)
        # Hand grips
        self.hand_grips[0] = np.array(state_list[83:85], dtype=np.int)
        self.hand_grips[1] = np.array(state_list[168:170], dtype=np.int)
        # Injuries
        self.plr0_injury = state_list[85]
        self.plr1_injury = state_list[170]
        
class ToribashControl:
    """ Main class controlling one instance of Toribash """
    def __init__(self, executable):
        """ 
        Parameters:
            executable: String of path to the toribash.exe launching the game
        """
        self.executable_path = executable
        self.process = None
        self.connection = None
    
    def _check_if_initialized(self):
        if self.process is None:
            raise ValueError("Controlled not initialized with init()")
    
    def init(self):
        """ Actual init: Launch the game and wait for connection to be 
            made
        """
        # Make sure we are not listening for overlapping connections
        with toribash_launch_lock:
            # TODO processes won't die on Windows when Python exits,
            # even with tricks from Stackoverflow #12843903
            self.process = subprocess.Popen((self.executable_path,), 
                                             stdout=subprocess.DEVNULL, 
                                             stderr=subprocess.DEVNULL)
            # Create socket for waiting for Toribash to connect
            s = socket.socket()
            # This allows rebinding to same address multiple times on *nix
            # From Stackoverflow #6380057
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s.bind(("",PORT))
            s.settimeout(TIMEOUT)
            s.listen(1)
            conn, addr = s.accept()
            # Close the listener socket
            s.close()
            
            # Set the timeout for connection 
            conn.settimeout(TIMEOUT)
            self.connection = conn
    
    def close(self):
        """ Close the running Toribash instance and clean up """
        self.connection.close()
        # No need to be gentle here
        self.process.kill()
    
    def _recv_line(self, s):
        """ Call recv till data ends with "\n"
        NOTE: This only expects "\n" to be at the end of message
        """
        # First wait till there is something to read
        ret = s.recv(BUFFER_SIZE)
        # Now check if we had "\n", and continue reading till we have it
        while ret[-1:] != MESSAGE_END:
            ret += s.recv(BUFFER_SIZE)
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
        if len(s) != STATE_LENGTH:
            raise ValueError(("Got state of invalid size. Expected %d, got %d"+
                             "\nState: %s") %
                             (STATE_LENGTH, len(s), s))
        return s, terminal
        
    def _send_comma_list(self, data):
        """ Send given list to Toribash as comma-separated list
        Parameters:
            actions: List of length 44 (22 limbs per player) representing the 
                     actions players should take
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
    
    def reset(self):
        """ Reset the game by sending settings for next round
        Returns:
            state: ToribashState representing the state of new game
        """
        self._check_if_initialized()
        
        # TODO implement proper sending of settings
        self.connection.sendall("\n".encode())
        s,terminal = self.get_state()
        return s
    
    def make_actions(self, actions):
        """ Send given list of actions to the server.
        Parameters:
            actions: List of shape 2 x (NUM_JOINTS+2), specifying joint states 
                     and hand gripping for both players.
        """
        self._check_if_initialized()
        
        # Make sure we have lists
        if type(actions) != list and type(actions) != tuple:
            raise ValueError("Actions should be a list (e.g. not numpy array)")
        
        # TODO add sanity checking that all actions are in {1,2,3,4}
        # (Game just jams if feeded forward)
        
        # Make sure hand states are {0,1}
        if (actions[0][-1] > 1 or actions[0][-2] > 1 or actions[1][-1] > 1 or
                    actions[0][-2] > 1):
            raise ValueError("Hand joint received state above 1 (last two "+
                             "states per player)")
        try:
            actions = actions[0]+actions[1]
            if len(actions) != 2*NUM_CONTROLLABLES:
                raise ValueError()
        except Exception as e:
            raise ValueError("Actions should be a List of shape 2 x %d " % 
                             NUM_CONTROLLABLES)

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
        
        self.make_actions(actions)
        s, terminal = self.get_state()
        return s, None, terminal, None
    
    def get_state_dim(self):
        """ Return size of state space per character """
        return NUM_LIMBS*3
    
    def get_num_joints(self):
        """ Return number of controllable joints """
        return NUM_CONTROLLABLES
    
    def get_num_joint_states(self):
        """ Return number of states each joint can have """
        return NUM_JOINT_STATES
    
def create_random_actions():
    """ Return random actions """
    ret = [[],[]]
    for plridx in range(2):
        for jointidx in range(NUM_JOINTS):
            ret[plridx].append(r.randint(1,4))
        ret[plridx].append(r.randint(0,1))
        ret[plridx].append(r.randint(0,1))
    return ret
    
def test_control(toribash_exe, num_instances, verbose=False):
    from time import time
    import subprocess
    verbose_print = lambda s: print(s) if verbose else None
    
    controllers = []
    
    verbose_print("Waiting connections from toribashes...")
    for i in range(num_instances):
        controller = ToribashControl(toribash_exe)
        controller.init()
        controllers.append(controller)

    last_time = time()
    n_steps = 0
    num_rounds = 0
    while num_rounds < 100:
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
	test_control(r"D:\Games\Toribash-5.2\toribash.exe", 1)
    #test_control("/home/anssk/.wine/drive_c/Games/Toribash-5.2/toribash.exe", 8)

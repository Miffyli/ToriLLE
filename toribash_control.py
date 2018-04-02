#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  toribash_control.py
#  Provides Python API to Toribash (i.e. can control the characters)
#
#  Copyright 2018 Anssi "Miffyli" Kanervisto
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

# Global timeout (in seconds) for connections
TIMEOUT = 10
# Buffer size (for recv)
BUFFER_SIZE = 8096
# Line ending character
MESSAGE_END = "\n".encode()

# "Limb" or "Bodypart"
NUM_LIMBS = 21
NUM_JOINTS = 20
# Add hand_grips
NUM_ACTIONS = NUM_JOINTS+2

# Bodypart x,y,z + Joint states + hand grips + injuries
STATE_LENGTH = (NUM_LIMBS*3*2) + NUM_JOINTS*2 + 4 + 2

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
    def __init__(self, connection):
        """ 
        Parameters:
            connection: Socket object representing TCP connection with Toribash
                        instance
        """
        self.connection = connection
        # Set the timeout time for connections
        self.connection.settimeout(TIMEOUT)
    
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
        #s = self.connection.recv(BUFFER_SIZE).decode()
        s = self._recv_line(self.connection).decode()
        terminal = s.startswith("end")
        if terminal:
            # Remove first three characters + comma to parse the state
            s = s[4:]
        s = list(map(float, s.split(",")))
        # Make sure we got list of correct length
        if len(s) != STATE_LENGTH:
            print("Recv: "+str(self.connection.recv(BUFFER_SIZE)))
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
        s, terminal = self._recv_state()
        s = ToribashState(s)
        return s, terminal
    
    def reset(self):
        """ Reset the game by sending settings for next round
        Returns:
            state: ToribashState representing the state of new game
        """
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
        if type(actions) != list and type(actions) != tuple:
            raise ValueError("Actions should be a list (e.g. not numpy array)")
        try:
            actions = actions[0]+actions[1]
            if len(actions) != 2*NUM_ACTIONS:
                raise ValueError()
        except Exception as e:
            raise ValueError("Actions should be list of shape 2 x %d " % 
                             NUM_ACTIONS)
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
        self.make_actions(actions)
        s, terminal = self.get_state()
        return s, None, terminal, None
        
def create_random_actions():
    """ Return random actions """
    ret = [[],[]]
    for plridx in range(2):
        for jointidx in range(NUM_JOINTS):
            ret[plridx].append(r.randint(1,4))
        ret[plridx].append(r.randint(0,1))
        ret[plridx].append(r.randint(0,1))
    return ret
    
def test_control(verbose=False):
    from time import time
    verbose_print = lambda s: print(s) if verbose else None
    
    s = socket.socket()
    s.bind(("",7777))
    s.listen(1)
    verbose_print("Waiting for connections...")
    conn, addr = s.accept()
    verbose_print("Connected. Creating ToribashControl...")
    controller = ToribashControl(conn)
    last_time = time()
    n_steps = 0
    while 1:
        s,terminal = controller.get_state()
        verbose_print("Got state")
        if terminal:
            verbose_print("Got terminal state. Resetting")
            s = controller.reset()
        actions = create_random_actions()
        verbose_print("Sending actions")
        controller.make_actions(actions)
        n_steps += 1
        if n_steps == 1000:
            print("FPS: %.2f" % (n_steps/(time()-last_time)))
            last_time = time()
            n_steps = 0
    
    
if __name__ == '__main__':
	test_control()


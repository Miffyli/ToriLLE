#!/usr/bin/env python3
#
#  uke_nevsd.py
#  ToriLLE Gym environments for single player but info on both players
#
#  Shout-out to GitHub user "ppaquette" for Gym-Doom, which was used 
#  as a base here.
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

import gym 
from gym import spaces
from .gym_env import ToriEnv
from .. import torille
from math import log10
import numpy as np
import sys
import random as r

def reward_destroy_uke(old_state, new_state):
    """ Returns reward on damaging the other player (Uke) """
    reward = new_state.injuries[1] - old_state.injuries[1]
    if reward > 1:
        reward = log10(reward) / 4
    return reward

def reward_destroy_uke_with_penalty(old_state, new_state):
    """ 
    Returns reward on damaging Uke, 
    but adds penalty for receiving damage.
    This is same as duo_envs.reward_player1_pov
    """
    reward = new_state.injuries[1] - old_state.injuries[1]
    penalty = new_state.injuries[0] - old_state.injuries[0]
    reward = reward - penalty
    if reward != 0:
        # Make it log scale, even for negative values
        reward = ((1 if reward > 0 else -1) * log10(abs(reward))) / 4
    return reward

class UkeToriEnv(ToriEnv):
    """ 
    An extension to ToriEnv designed for controlling only one body,
    but receiving observation on both bodies 
    """
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.reward_func = kwargs["reward_func"]
        self.random_uke = kwargs["random_uke"]

        # Create action space only for the first player
        if sys.platform == "win32":
            self.action_space = spaces.MultiDiscrete((
                [[0,torille.ToribashConstants.NUM_JOINT_STATES-1]]*
                torille.ToribashConstants.NUM_CONTROLLABLES
            ))
            # observation space for both players
            self.observation_space = spaces.Box(low=-30, high=30, 
                                shape=(torille.ToribashConstants.NUM_LIMBS*3*2,))
        else:
            self.action_space = spaces.MultiDiscrete((
                [torille.ToribashConstants.NUM_JOINT_STATES]*
                torille.ToribashConstants.NUM_CONTROLLABLES
            ))
            # observation space for both players
            self.observation_space = spaces.Box(low=-30, high=30, dtype=np.float32, 
                                shape=(torille.ToribashConstants.NUM_LIMBS*3*2,))

    def _preprocess_observation(self, state):
        # Give observation for both players
        obs = state.limb_positions.ravel()
        return obs

    def _preprocess_action(self, action):
        # Add +1 to limb actions (to make [0,3] -> [1,4])
        if type(action) != list:
            action = list(action)
        for i in range(torille.ToribashConstants.NUM_CONTROLLABLES):
            action[i] += 1

        if not self.random_uke:
            # Add "hold" actions for the (immobile) opponent
            action = [action, [3]*torille.ToribashConstants.NUM_CONTROLLABLES]
            # Make hand grip actions for uke to be 0 (no grip)
            # Otherwise he will be stickier than tar
            action[1][-2] = 1
            action[1][-1] = 1
        else:
            # Add random actions for uke
            action = [action, [r.randint(1,4) for i in 
                        range(torille.ToribashConstants.NUM_CONTROLLABLES)]]
        return action

    def _reward_function(self, old_state, new_state):
        return self.reward_func(old_state, new_state)

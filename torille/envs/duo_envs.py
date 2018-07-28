#!/usr/bin/env python3
#
#  duo_envs.py
#  ToriLLE Gym environments with duo tasks (e.g. combat )
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
from math import log10, log
import numpy as np
import sys

def reward_player1_pov(old_state, new_state):
    """ 
    Reward function from the point-of-view of the player 1:
        + reward for damaging player 2
        - reward for receiving damage
    Negate of this is reward for plr2
    """
    plr2_injury_delta = new_state.injuries[1] - old_state.injuries[1]
    plr1_injury_delta = new_state.injuries[0] - old_state.injuries[0]
    reward = plr2_injury_delta - plr1_injury_delta
    if reward != 0:
        # Make it log scale, even for negative values
        reward = ((1 if reward > 0 else -1) * log10(abs(reward))) / 4
    return reward

def reward_cuddles(old_state, new_state):
    """ 
    Reward for players being close to each other (distance between
    center-of-masses are close to each other).
    Add penalty for damage caused to either side.

    Why? Because learning methods (AI?) need some love too!
    """
    reward = 0
    # Distance between center of masses
    coms = new_state.limb_positions.mean(axis=1)
    coms_dist = np.sqrt(np.sum((coms[1]-coms[0])**2))
    # Give reward relative to inverse of 
    # coms_distance, scaled properly
    reward += log10(1/coms_dist)

    # Penalty for injury
    plr2_injury_delta = new_state.injuries[1] - old_state.injuries[1]
    plr1_injury_delta = new_state.injuries[0] - old_state.injuries[0]
    penalty = plr1_injury_delta + plr2_injury_delta
    if penalty > 0: 
        penalty = log10(penalty) / 4
    reward -= penalty

    return reward

class DuoToriEnv(ToriEnv):
    """ An extension to ToriEnv designed for controlling both players"""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.reward_func = kwargs["reward_func"]

        # Create action/observation space again, but this time ravel'd

        if sys.platform == "win32":
            self.action_space = spaces.MultiDiscrete((
                    [[0,torille.ToribashConstants.NUM_JOINT_STATES-1]]*
                    torille.ToribashConstants.NUM_CONTROLLABLES*2)
            )
            # For both players, position of all joints
            self.observation_space = spaces.Box(low=-30, high=30, 
                        shape=(torille.ToribashConstants.NUM_LIMBS*3*2,))
        else:
            self.action_space = spaces.MultiDiscrete((
                    [torille.ToribashConstants.NUM_JOINT_STATES]*
                    torille.ToribashConstants.NUM_CONTROLLABLES*2)
            )
            # For both players, position of all joints
            self.observation_space = spaces.Box(low=-30, high=30, dtype=np.float32, 
                        shape=(torille.ToribashConstants.NUM_LIMBS*3*2,))

        

    def _preprocess_observation(self, state):
        # Give positions of both players
        obs = state.limb_positions.ravel()
        return obs

    def _preprocess_action(self, action):
        # Add +1 to limb actions (to make [0,3] -> [1,4])
        if type(action) != list:
            action = list(action)
        for i in range(torille.ToribashConstants.NUM_CONTROLLABLES*2):
            action[i] += 1
        # Split into two lists
        action = [action[:torille.ToribashConstants.NUM_CONTROLLABLES],
                  action[torille.ToribashConstants.NUM_CONTROLLABLES:]]
        return action

    def _reward_function(self, old_state, new_state):
        return self.reward_func(old_state, new_state)

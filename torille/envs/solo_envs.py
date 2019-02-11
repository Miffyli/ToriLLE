#!/usr/bin/env python3
#
#  solo_envs.py
#  ToriLLE Gym environments with solo tasks (e.g. run-away, self-destruct)
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
import numpy as np


def reward_self_destruct(old_state, new_state):
    """ Returns reward for plr0 receiving damage """
    reward = new_state.injuries[0] - old_state.injuries[0]
    reward = reward / 5000
    return reward


def reward_stay_safe(old_state, new_state):
    """ Returns reward for plr0 NOT receiving damage """
    # Injury can only increase
    reward = -(old_state.injuries[0] - new_state.injuries[0])
    reward = reward / 5000
    return -reward


def reward_run_away(old_state, new_state):
    """
    Returns reward for plr0 for running away from center of the arena.
    Center of arena is conveniently between players
    """
    # Use head as a position metric (hip would probably be better, oh well)
    old_pos = old_state.limb_positions[0, 0]
    new_pos = new_state.limb_positions[0, 0]
    # Amount moved away from center
    # (we want further away to be positive)
    moved = np.sqrt(np.sum(new_pos ** 2)) - np.sqrt(np.sum(old_pos ** 2))
    return moved


class SoloToriEnv(ToriEnv):
    """ An extension to ToriEnv designed for controlling only one body """

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.reward_func = kwargs["reward_func"]

        self.action_space = spaces.MultiDiscrete((
            [torille.constants.NUM_JOINT_STATES] *
            torille.constants.NUM_CONTROLLABLES
        ))
        # Only one player
        self.observation_space = spaces.Box(
            low=-30, high=30, dtype=np.float32,
            shape=(torille.constants.NUM_LIMBS * 3,)
        )

    def _preprocess_observation(self, state):
        # Only give player1 positions as observation
        # Player1's positions w.r.t player1
        obs = state.get_normalized_locations()[0, 0]
        # Replaced groin's "z" with absolute "z" (height from ground),
        # so that agent knows how much above the ground it is
        obs[4, 2] = state.limb_positions[0, 4, 2]
        obs = obs.ravel()
        return obs

    def _preprocess_action(self, action):
        # Add +1 to limb actions (to make [0,3] -> [1,4])
        if type(action) != list:
            action = list(action)
        for i in range(torille.constants.NUM_CONTROLLABLES):
            action[i] += 1
        # Add "hold" actions for the (immobile) opponent
        action = [action, [3] * torille.constants.NUM_CONTROLLABLES]
        # Make hand grip actions for uke to be 0 (no grip)
        # Otherwise he will be stickier than tar
        action[1][-2] = 1
        action[1][-1] = 1
        return action

    def _reward_function(self, old_state, new_state):
        return self.reward_func(old_state, new_state)

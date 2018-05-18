#!/usr/bin/env python3
#
#  gym_env.py
#  ToriLLE available as OpenAI Gym Environment
#
#  Shoutout to GitHub user "ppaquette" for Gym-Doom, which was used 
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
from controller import torille
import numpy as np
import sys

class ToriEnv(gym.Env):
    def __init__(self, **kwargs):
        self.toribash_exe = kwargs["toribash_exe"]
        self.settings = torille.ToribashSettings(**kwargs)
        self.game = torille.ToribashControl(self.toribash_exe, self.settings)

        # Previous state (ToribashState)
        # Used for reward function
        self.old_state = None

        # True if this object was created and there has been no calls to
        # ´step´ function.
        # This is to make sure first call to controller will be get_state()
        self.just_created = True

        # {1,2,3,4} for joints, {0,1} for hands. For both players
        if sys.platform == "win32":
            # For some reason Gym has completely different implementations for 
            # spaces.MultiDiscrete on Windows vs. Linux...
            # Windows wants [[1,4],[1,4], ... , [0,1], [0,1]]
            # We make it [[0,3], [0,3], ... [0,1], [0,1]] to stay similar 
            self.action_space = spaces.MultiDiscrete(([[0,torille.NUM_JOINT_STATES-1]]*torille.NUM_JOINTS + [[0,1]]*2)*2)
        else:
            self.action_space = spaces.MultiDiscrete(([torille.NUM_JOINT_STATES]*torille.NUM_JOINTS + [1]*2)*2)

        # For both players, position of all joints
        self.observation_space = spaces.Box(low=-30, high=30, shape=(2,torille.NUM_LIMBS*3))

        self.game.init()

    def _preprocess_observation(self, state):
        """ 
        Preprocess ToribashState into more Numpyish
        Parameters:
            state: ToribashState
        Returns:
            observation: Object according to observation space
        """
        raise NotImplementedError

    def _preprocess_action(self, action):
        """ 
        Preprocess actions from agents into appropiate actions for Toribash
        Parameters:
            action: Action according to action space
        Returns: 
            action: An appropiate action object for Torille (List of two Lists)"""
        raise NotImplementedError

    def _reward_function(self, old_state, new_state):
        """ 
        Calculates reward 
        Parameters:
            old_state: Old (previous) observation. None if `new_obs` is 
                       first observation
            new_state: Current observation
        Returns:
            reward: Reward signal (float)
        """
        raise NotImplementedError

    def _step(self, action):
        if self.just_created:
            # We cannot send action as a first call to controller
            # We should instead call `reset`.
            # Inform and fail
            raise Exception("`step` function was called "+
                "before calling `reset`. Call `reset` after creating "+
                "environment to get the first observation.")
        action = self._preprocess_action(action)
        self.game.make_actions(action)
        # Get new state
        state, terminal = self.game.get_state()
        # Compute reward (something we will define in other classes)
        reward = self._reward_function(self.old_state, state)
        # Remember to update the old state
        self.old_state = state
        # "obs" here is in the Gym format. "state" is ToribashState
        obs = self._preprocess_observation(state)
        return obs, reward, terminal, None

    def _reset(self):
        obs = None
        if self.just_created:
            # The env was just created and we need to start 
            # by returning an observation.
            state, terminal = self.game.get_state()
            obs = self._preprocess_observation(state)
            # Remember to update the state here as well
            self.old_state = state
            self.just_created = False
        else:
            # Reset episode
            state = self.game.reset()
            # Get the state and return it 
            obs = self._preprocess_observation(state)
            self.old_state = state
        return obs

    def _render(self, close=None):
        # TODO what is the close param? Some windows thing?
        # TODO can this be done in some way?
        print("ToriEnv._render not implemented")
        return None

    def _close(self, close=None):
        self.game.close()

    def _seed(self, seed=None):
        # Can't set the seed in Toribash
        raise NotImplementedError

class TestToriEnv(ToriEnv):
    """ A testing environment. Not to be used with anything useful """
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        # {1,2,3,4} for joints, {0,1} for hands
        if sys.platform == "win32":
            # For some reason Gym has completely different implementations for 
            # spaces.MultiDiscrete on Windows vs. Linux...
            # Windows wants [[1,4],[1,4], ... , [0,1], [0,1]]
            # We make it [[0,3], [0,3], ... [0,1], [0,1]] to stay similar 
            self.action_space = spaces.MultiDiscrete(([[0,torille.NUM_JOINT_STATES-1]]*torille.NUM_JOINTS + [[0,1]]*2))
        else:
            # Linux wants [[4,4,4, ..., 1, 1]]
            self.action_space = spaces.MultiDiscrete(([torille.NUM_JOINT_STATES]*torille.NUM_JOINTS + [1]*2))
        # Only one player
        self.observation_space = spaces.Box(low=-30, high=30, shape=(torille.NUM_LIMBS*3))

    def _preprocess_observation(self, state):
        obs = state.limb_positions[0].ravel()
        return obs

    def _preprocess_action(self, action):
        # Add +1 to limb actions (to make [0,3] -> [1,4])
        for i in range(torille.NUM_JOINTS):
            action[i] += 1
        action = [action, [1]*torille.NUM_CONTROLLABLES]
        return action

    def _reward_function(self, old_state, new_state):
        return 0
        
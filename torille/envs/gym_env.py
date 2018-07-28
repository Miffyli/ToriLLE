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
from .. import torille
import numpy as np
import sys

class ToriEnv(gym.Env):
    """ 
    A base (abstract) environment for Toribash environments.
    """
    def __init__(self, **kwargs):
        self.settings = torille.ToribashSettings(**kwargs)
        self.game = torille.ToribashControl(settings=self.settings)

        # Previous state (ToribashState)
        # Used for reward function
        self.old_state = None

        # True if this object was created and there has been no calls to
        # ´step´ function.
        # This is to make sure first call to controller will be get_state()
        self.just_created = True

        # {1,2,3,4} for joints, {0,1} for hands. For both players
        # Also space does not accept dtype on Windows...
        if sys.platform == "win32":
            # For some reason Gym has completely different implementations for 
            # spaces.MultiDiscrete on Windows vs. Linux...
            # Windows wants [[1,4],[1,4], ...]
            # We make it [[0,3], [0,3], ...] for consistency
            self.action_space = spaces.MultiDiscrete((
                    [[0,torille.ToribashConstants.NUM_JOINT_STATES-1]]*
                    torille.ToribashConstants.NUM_CONTROLLABLES)*2
            )
            # For both players, position of all joints
            self.observation_space = spaces.Box(low=-30, high=30, 
                        shape=(2,torille.ToribashConstants.NUM_LIMBS*3))
        else:
            self.action_space = spaces.MultiDiscrete((
                    [torille.ToribashConstants.NUM_JOINT_STATES]*
                    torille.ToribashConstants.NUM_CONTROLLABLES)*2
            )
            # For both players, position of all joints
            self.observation_space = spaces.Box(low=-30, high=30, dtype=np.float32, 
                        shape=(2,torille.ToribashConstants.NUM_LIMBS*3))

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
            action: An appropiate action object for Torille (List of two Lists)
        """
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

    def step(self, action):
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

    def reset(self):
        obs = None
        if self.just_created:
            # Initialize game here to make it pickable before init
            self.game.init()
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

    def set_draw_game(self, visibility):
        """ 
        Sets flag for drawing the game. Must be called before first reset()
        (drawing = render characters, limit FPS)
        Parameters:
            visibility: True = game will be drawn. 
        """
        if not self.just_created:
            raise Exception("Can't change rendering after first `reset()`")
        else:
            self.game.draw_game = visibility

    def render(self, **kwargs):
        raise NotImplementedError("See `set_draw_game` for displaying game")

    def close(self, **kwargs):
        self.game.close()

    def seed(self, seed=None):
        # Can't set the seed in Toribash
        raise NotImplementedError
        
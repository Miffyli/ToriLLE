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

# TODO how to organize directory structure?
# TODO how to give settings?

# TODO how does this work? Can this share lock across processes?
class DoomLock:
    class __DoomLock:
        def __init__(self):
            self.lock = multiprocessing.Lock()

    instance = None

    def __init__(self):
        if not DoomLock.instance:
            DoomLock.instance = DoomLock.__DoomLock()

    def get_lock(self):
        return DoomLock.instance.lock

class ToriEnv(gym.Env):
    metadata = {}

    def __init__(self):
        # TODO this will be the TorilleController
        self.game = None

        # Previous state (ToribashState)
        # Used for reward function
        self.old_state = None

        # TODO remnant
        self.lock = (DoomLock()).get_ock()
        # TODO define spaces correctly
        self.action_space = spaces.MultiDiscrete([[0, 1]] * 38 + [[-10, 10]] * 2 + [[-100, 100]] * 3)
        self.observation_space = spaces.Box(low=0, high=255, shape=(self.screen_height, self.screen_width, 3))
    
    def init(self):
        """ Initialize game here (e.g. game.init ) """

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

    def _configure(self, lock=None, **kwargs):
        # TODO this is just a remnant from gym doom
        # Curious to know how the locking works
        # Multiprocessing lock
        if lock is not None:
            self.lock = lock

    def _step(self, action):
        action = self._preprocess_action(action)
        state, _, terminal, _ = self.game.step(action)
        reward = self._reward_function(self.old_state, state)
        obs = self._preprocess_observation(state)
        return obs, reward, terminal, None

    def _reset(self):
        state = self.game.reset()
        obs = self._preprocess_observation(state)
        self.old_state = state
        return obs

    def _render(self):
        # TODO can this be done in some way?
        raise NotImplementedError

    def _close(self):
        self.game.close()

    def _seed(self, seed=None):
        # Can't set the seed in Toribash
        raise NotImplementedError


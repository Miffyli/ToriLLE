#!/usr/bin/env python3
# 
# competitive_toribash.py
# Implements competitive 1v1 setup for Toribash
# using the rules used in competitive Toribash

from torille.envs.gym_env import ToriEnv
#from torille.envs import reward_player1_pov
from gym import spaces
import torille
import numpy as np
import random as r
import math as m
from pprint import pprint

def toribash_win_reward(old_state, new_state):
    """ 
    +1/-1 reward based on who won the game, from the POV of player1:
        +1 if player1 won the game
        -1 if player1 lost the game
        0 if game was tie or game has not ended
    """
    if new_state.winner is not None:
        if new_state.winner == 1:
            # Player1 won the game
            return 1
        elif new_state.winner == 2:
            # Player2 won the game
            return -1
        elif new_state.winner == 0:
            # Game was tie
            return 0
        else:
            raise ValueError("state.winner was %d" % new_state.winner)
    # Game has not ended yet
    return 0

class CompetitiveEnv(ToriEnv):
    """ An extension to ToriEnv designed for controlling both players"""
    
    # Starting x,y,z of groin of both players
    # in aikidobigdojo.tbm mod. Players do not start from
    # perfectly mirrored positions from center, so we have
    # to use this instead
    STARTING_GROIN_COORDS = np.array([
        [1,  0.44999999, 1.49000001],
        [1, -0.64999992, 1.49000001],
    ])
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.player2_step = kwargs["player2_step"]
        self.player2_reset = kwargs["player2_reset"]
        self.player2_obs = None
        self.reward_func = kwargs["reward_func"]
        
        self.verbose = kwargs.get("verbose", False)

        # Only for one player, another one gets actions from
        # the callback
        self.action_space = spaces.MultiDiscrete((
                [torille.constants.NUM_JOINT_STATES]*
                 torille.constants.NUM_CONTROLLABLES)
        )

        # Only for the player1
        self.observation_space = spaces.Box(low=-30, high=30, dtype=np.float32, 
                    shape=(torille.constants.NUM_LIMBS * 3 * 2 + 4,))
        
        self.settings.set("custom_settings", 0)
        self.settings.set("mod", "aikidobigdojo.tbm")
        
    def _preprocess_observation(self, state):
        """
        Return two observations: One for each player.
        Center locations around hip bones of respective player
        """
        
        normalized_locations = state.get_normalized_locations()
        player1_obs, player2_obs = normalized_locations 

        # Flip player2 observation so that the controlled character's positions are
        # first
        player2_obs = player2_obs[::-1]

        player1_obs = player1_obs.ravel()
        player2_obs = player2_obs.ravel()
        
        # Add absolute "z"
        # Add distance from center
        player1_obs = np.append(player1_obs, [state.limb_positions[0, 4, 2], 
                                              m.sqrt(np.sum((state.limb_positions[0, 4] - CompetitiveEnv.STARTING_GROIN_COORDS[0])**2))])
        player2_obs = np.append(player2_obs, [state.limb_positions[1, 4, 2], 
                                              m.sqrt(np.sum((state.limb_positions[1, 4] - CompetitiveEnv.STARTING_GROIN_COORDS[1])**2))])
        # Add how many steps next turn will be
        # Add how much game is still left
        player1_obs = np.append(player1_obs, [1 - state.match_frame/state.match_length, state.frames_next_turn/state.match_length])
        player2_obs = np.append(player2_obs, [1 - state.match_frame/state.match_length, state.frames_next_turn/state.match_length])

        # Normalize little bit to avoid too high values
        player1_obs = player1_obs / 3
        player2_obs = player2_obs / 3
        
        if self.verbose:
            print("[CompEnv] Difference of obsevations")
            print(np.round(player1_obs - player2_obs, 3))
        
        return player1_obs, player2_obs

    def _preprocess_action(self, action):
        # Add +1 to limb actions (to make [0,3] -> [1,4])
        # Action is already two separate lists
        for plr in range(2):
            for i in range(torille.constants.NUM_CONTROLLABLES):
                action[plr][i] += 1

        return action

    def _reward_function(self, old_state, new_state):
        return self.reward_func(old_state, new_state)

    def reset(self):
        obs = super().reset()
        self.player2_reset()
        self.player2_obs = obs[1]

        return obs[0]

    def step(self, action):
        # Ask player2 for an action as well
        player2_action = self.player2_step(self.player2_obs)
        
        action = [list(action), player2_action]
        
        if self.verbose:
            print("[CompEnv] Actions")
            pprint(action)

        obs, reward, terminal, info = super().step(action)

        # Observation is from _preprocess_observation,
        # split accordingly
        self.player2_obs = obs[1]

        return obs[0], reward, terminal, info

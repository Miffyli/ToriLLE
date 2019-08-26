
from stable_baselines import PPO2
from stable_baselines.common.policies import MlpLstmPolicy
from stable_baselines.common.vec_env import DummyVecEnv, SubprocVecEnv
from stable_baselines.bench import Monitor
from torille import envs
from torille.utils import create_random_actions
from competitive_env import CompetitiveEnv
import gym
import random
from argparse import ArgumentParser
import tensorflow as tf
import os
import time
import numpy as np
from glob import glob
from pprint import pprint
from datetime import datetime
import sys

# Core implementation of the self-play:
# CompetitiveEnv takes in function that returns actions for player 2 in the
# Toribash environment (hence it is "part of the environment"). Player 1 learns
# as usual.

parser = ArgumentParser("Train stable-baselines agents on Toribash with self-play")
parser.add_argument("--timesteps", type=int, default=int(3 * 1e10), help="How long to train")
parser.add_argument("--ent_coef", type=float, default=0.001, help="Entropy coefficient for PPO")
parser.add_argument("--steps_per_batch", type=int, default=128, help="Number of steps per environment per update")
parser.add_argument("--time_between_snapshots", type=int, default=21600 help="Time in seconds between saving snapshots (default: 3h)") # 3 hours
parser.add_argument("--num_envs", type=int, default=4)
parser.add_argument("--load_model", type=str, help="If given, load this model instead of starting from random")

# Where main (current) version of the agent is stored
MAIN_MODEL = "model.pkl"
# Prefix of snapshot models (older versions)
SNAPSHOT_PREFIX = "model_snapshot"

class TorilleWrapper(gym.Wrapper):
    """ Ad-hoc wrapper for many things with torille """
    def step(self, action):
        # Fix info being None -> info = {}
        obs, reward, done, _ = self.env.step(action)
        return obs, reward, done, {}

    def reset(self, **kwargs):
        obs = self.env.reset(**kwargs)
        return obs

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

def create_env():
    """ For SubProcEnv """
    # Load current model for the agent
    # Dirty hack: When starting script for the first time, this model is not available.
    #             Skip loading it up (would crash code later) so main code can 
    #             save some version of the agent.
    #             One error here: We will load different initial parameters
    #             than what learning agent may have on startup.
    if os.path.isfile(MAIN_MODEL):
        opponent_ppo = PPO2.load(MAIN_MODEL)

        # Create assign ops for the oppoennt
        with opponent_ppo.graph.as_default():
            update_ops = []
            update_placeholders = []
            for param in opponent_ppo.params:
                placeholder = tf.placeholder(dtype=param.dtype, shape=param.shape)
                update_ops.append(param.assign(placeholder))
                update_placeholders.append(placeholder)
            # Throw them into the agent to have them around the code
            opponent_ppo.param_update_ops = update_ops
            opponent_ppo.param_update_phs = update_placeholders
        
        # Include the hidden state in the opponent agent
        opponent_ppo.hidden_state = None
        opponent_ppo.use_random_agent = False

    def player2_actions(obs):
        # We have to padd with zeroes.
        # Hardcoded magical numbers.
        if not opponent_ppo.use_random_agent:
            obs = np.pad(obs[None], ((0,3), (0,0)), 'constant')
            action, opponent_ppo.hidden_state = opponent_ppo.predict(obs, state=opponent_ppo.hidden_state)
            return list(action[0])
        else:
            return list(map(lambda x: x-1, create_random_actions()[0]))

    def player2_reset():
        opponent_ppo.hidden_state = None
        # With small chance, update the opponent
        if random.random() < 0.01:
            rand = random.random()
            if rand < 0.2:
                # Just random agent
                print("---Loading random agent---")
                opponent_ppo.use_random_agent = True
            elif rand < 0.4:
                # Load some previous model
                print("---Loading old params---")
                opponent_ppo.use_random_agent = False
                model_files = glob(SNAPSHOT_PREFIX + "*")
                # If no snapshots available, load newest ones
                load_file = MAIN_MODEL
                if len(model_files) > 0:
                    load_file = random.choice(model_files)
                opponent_ppo.load_parameters(load_file)
            else:
                # Load most recent params
                print("---Loading new params---")
                opponent_ppo.load_parameters(MAIN_MODEL)
                opponent_ppo.use_random_agent = False

    env = CompetitiveEnv(reward_func=toribash_win_reward,
                         player2_step=player2_actions,
                         player2_reset=player2_reset)
    env = TorilleWrapper(env)

    return env

def run_experiment(args):
    global last_snapshot_time
    last_snapshot_time = time.time()
    
    def test_callback(_locals, _globals):
        global last_snapshot_time
        # Save model
        _locals['self'].save(MAIN_MODEL)
        # If enough time has passed, save snapshot
        if (time.time() - last_snapshot_time) > args.time_between_snapshots:
            timestamp = datetime.now()
            filename = "{}_{}_{}_{}_{}.pkl".format(
                SNAPSHOT_PREFIX, timestamp.day, timestamp.month, timestamp.hour, timestamp.minute
            )
            _locals['self'].save(filename)
            last_snapshot_time = time.time()

    # Create envs
    envs = [create_env for i in range(args.num_envs)]
    vecEnv = SubprocVecEnv(envs)

    # Standard 2 x 128 network with sigmoid activations
    # Note: with net_arch, pi and value use same layers
    policy_kwargs = dict(act_fun=tf.nn.sigmoid, net_arch=[128, "lstm"], n_lstm=128)

    model = None
    if args.load_model is None:
        model = PPO2(MlpLstmPolicy, vecEnv, policy_kwargs=policy_kwargs, 
                     ent_coef=args.ent_coef, n_steps=args.steps_per_batch, 
                     nminibatches=args.num_envs//2, 
                     verbose=1)
    else:
        print("Loading parameters from ", args.load_model)
        model = PPO2.load(args.load_model, env=vecEnv)

    # Save for opponents to load up this model
    # Dirty hack: If MAIN_MODEL did not exist yet, save it and exit code to have 
    #             some version of the model on the disk for opponent models.
    #             Note: On next startup, learning agent will have different learning
    #                   parameters than opponents, until opponents change their parameters
    if not os.path.isfile(MAIN_MODEL):
        model.save(MAIN_MODEL)
        print("\nPPO model structure saved on disk. Run this code again to start learning\n")
    else:
        model.save(MAIN_MODEL)
        model.learn(total_timesteps=args.timesteps, callback=test_callback)

if __name__ == "__main__":
    args = parser.parse_args()
    run_experiment(args)

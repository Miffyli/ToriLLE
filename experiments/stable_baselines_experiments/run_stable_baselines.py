from stable_baselines import PPO2, TRPO
from stable_baselines.common.policies import MlpPolicy
from stable_baselines.common.vec_env import DummyVecEnv, SubprocVecEnv
from stable_baselines.bench import Monitor
from torille import envs
import gym
import random
from argparse import ArgumentParser
import tensorflow as tf
import os
import time

parser = ArgumentParser("Run stable-baselines on torille")
parser.add_argument("env")
parser.add_argument("agent", choices=["ppo", "trpo"])
parser.add_argument("experiment_name")
parser.add_argument("--timesteps", type=int, default=int(3 * 1e6))
parser.add_argument("--randomize_engagement", action="store_true")
parser.add_argument("--turnframes", type=int, default=5)
parser.add_argument("--ent_coef", type=float, default=0.01)
parser.add_argument("--steps_per_batch", type=int, default=1024)
parser.add_argument("--num_envs", type=int, default=1)

class TorilleWrapper(gym.Wrapper):
    """ Ad-hoc wrapper for many things with torille """
    def __init__(self, env, record_every_episode, record_name, randomize_settings):
        super().__init__(env)

        self.record_every_episode = record_every_episode
        self.record_name = record_name
        self.randomize_settings = randomize_settings
        self.num_episodes = 0

    def step(self, action):
        # Fix info being None -> info = {}
        obs, reward, done, _ = self.env.step(action)
        return obs, reward, done, {}

    def reset(self, **kwargs):
        obs = self.env.reset(**kwargs)
        self.num_episodes += 1

        # Ad-hoc settings for destroyuke
        self.env.settings.set("custom_settings", 1)
        for key,values in self.randomize_settings.items():
            self.env.settings.set(key, random.randint(*values))
        if (self.num_episodes % self.record_every_episode) == 0:
            self.env.settings.set("replay_file", "%s_%d" % (self.record_name, self.num_episodes))
        else:
            self.env.settings.set("replay_file", None)
        return obs

def run_experiment(args):
    
    randomization_settings = {
        "engagement_distance": (100,100),
        "turnframes": (args.turnframes, args.turnframes)
    }

    if args.randomize_engagement: 
        randomization_settings["engagement_distance"] = (100, 200)
    
    vecEnv = None
    if args.num_envs == 1:
        # Create dummyvecenv
        env = gym.make(args.env)
        env = Monitor(TorilleWrapper(env, 100, args.experiment_name, randomization_settings), args.experiment_name)
        vecEnv = DummyVecEnv([lambda: env])  # The algorithms require a vectorized environment to run
    else:
        vecEnv = []
        
        def make_env():
            env = gym.make(args.env)
            unique_id = str(time.time())[-6:]
            experiment_env_name = args.experiment_name + ("_env%s" % unique_id)
            return Monitor(TorilleWrapper(env, 100, experiment_env_name, randomization_settings), 
                           experiment_env_name)
        
        for i in range(args.num_envs):
            vecEnv.append(make_env)
        
        vecEnv = SubprocVecEnv(vecEnv)

    steps_per_env = args.steps_per_batch // args.num_envs

    # Standard 2 x 64 network with sigmoid activations
    policy_kwargs = dict(act_fun=tf.nn.sigmoid, net_arch=[64, 64])
    model = None
    if args.agent == "ppo":
        model = PPO2(MlpPolicy, vecEnv, policy_kwargs=policy_kwargs, 
                     ent_coef=args.ent_coef, n_steps=steps_per_env,
                     verbose=1)
    elif args.agent == "trpo":
        model = TRPO(MlpPolicy, vecEnv, policy_kwargs=policy_kwargs, 
                     entcoeff=args.ent_coef, timesteps_per_batch=steps_per_env,
                     verbose=1)

    model.learn(total_timesteps=args.timesteps)

if __name__ == "__main__":
    args = parser.parse_args()
    run_experiment(args)

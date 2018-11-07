#!/usr/bin/env python3
# 
# ppo_turnframes.py
# Trains PPOs on Toribash DestroyUke-v1
# environment with different turnframes
# Author: Anssi "Miffyli" Kanervisto

# Make sure we are not using GPUs 
# (only hinders performance with small networks)
import os
os.environ["CUDA_VISIBLE_DEVICES"] = ""

import gym
import torille.envs
import random as r
from tensorforce.agents import *
import time
import json
import argparse
import numpy as np

NUM_STEPS = 5000000

# Randomize distance to opponent to make things
# less trivial
ENGAGEMENT_DISTANCE_RANGE = (100,200)

parser = argparse.ArgumentParser()
parser.add_argument("ppo_config", help="PPO config to load")
parser.add_argument("turnframes", type=int, help="Number of turnframes to use")
parser.add_argument("report_freq", type=int, help="Number of games between reports")
parser.add_argument("logfile", help="Output file for logs")
args = parser.parse_args()

turnframes = args.turnframes
report_freq = args.report_freq
assert turnframes > 1 and turnframes < 1000

# Create and initialize environment
env = gym.make("Toribash-DestroyUke-v1")

# Set the new setting for turnframes
env.settings.set("turnframes", turnframes)

with open(args.ppo_config, 'r') as fp:
    agent_config = json.load(fp=fp)

with open("./mlp_config.json", 'r') as fp:
    network_spec = json.load(fp=fp)

agent = Agent.from_spec(
    spec = agent_config,
    kwargs=dict(
            states=dict(type='float', shape=(126,)),
            actions=dict(type='int', shape=(22,), num_actions=4),
            network=network_spec
        )
)

# Print the settings
print("--- Settings ---\n"+str(env.settings))
print("--- Agent ---\n"+str(agent_config))
print("--- Training starts ---")

# Main loop
start_time = time.time()
report_rewards = []
step_ctr = 0
episode_ctr = 0
logfile = open(args.logfile, "w")
logname = os.path.basename(args.logfile).split(".")[0]

while step_ctr < NUM_STEPS:
    # Randomize starting distance between players
    env.settings.set("engagement_distance", r.randint(ENGAGEMENT_DISTANCE_RANGE[0], ENGAGEMENT_DISTANCE_RANGE[1]))
    # Record gameplay every now and then
    if (episode_ctr % report_freq) == 0:
        env.settings.set("replay_file", logname+("_episode_%d" % episode_ctr))
    else: 
        env.settings.set("replay_file", None)
    state = env.reset()
    sum_reward = 0
    terminal = False
    while not terminal:
        actions = agent.act(state)
        # Get the current state and info if the episode was terminal
        state, reward, terminal, _ = env.step(actions)
        step_ctr += 1
        sum_reward += reward
        agent.observe(reward=reward, terminal=terminal)
    report_rewards.append(sum_reward)
    episode_ctr += 1

    if (episode_ctr % report_freq) == 0:
        mean_reward = sum(report_rewards)/len(report_rewards)
        std_reward = np.std(report_rewards)
        max_reward = max(report_rewards)
        min_reward = min(report_rewards)
        log = "Time: {:>7} Ep: {:>6} Steps: {:>8} MinR: {:>6.2f} MeanR: {:>6.2f} MaxR: {:>6.2f} StdR: {:>6.2f}".format(
              int(time.time()-start_time), 
              episode_ctr, 
              step_ctr, 
              min_reward,
              mean_reward,
              max_reward, 
              std_reward)
        print(log)
        logfile.write(log+"\n")
        logfile.flush()
        report_rewards.clear()

logfile.close()
# Close the environment
env.close()

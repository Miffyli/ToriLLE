#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  gym_example.py
#  A minimalistic example running ToriLLE OpenAI Gym Environment 
#
#  Author: Anssi "Miffyli" Kanervisto, 2018
import gym
from envs import SoloToriEnv
import random as r

# Path to the toribash.exe executable.
# Note: Remember add required Toribash files to the game path
# On Windows use r"..." strings to 'fix' the issues with backslashes
GAME_EXECUTABLE = r"D:\Games\Toribash-5.22\toribash.exe"

# How many games will be played
NUM_EPISODES = 5

# Create and initialize environment
env = gym.make("Toribash-RunAway-v0")

# You can change the settings from the ones set by environment
# BUT: These only apply on next call to "reset()", and you
# may not call reset whenever you please!
# env.settings.set("matchframes", 1000)

# Print the settings
print("--- Settings ---\n"+str(env.settings))

# Main loop
number_of_episodes = 0
turn_number = 0

# Initial reset (You _have_ to start by calling `reset` first!)
first_obs = env.reset()
while number_of_episodes < NUM_EPISODES:
    # Come up with some actions. Here we just take random actions
    actions = env.action_space.sample()

    # Get the current state and info if the episode was terminal
    state, reward, terminal, _ = env.step(actions)
    
    # If state was terminal (game has ended), restart the episode
    # and get the new state.
    # With default settings (no disqualification), this corresponds to 
    # playing for 'matchframes' number of frames
    if terminal: 
        # Begin a new game and receive the initial state
        state = env.reset()
        # Keep count of played episodes
        number_of_episodes += 1
        turn_number = 0
        print("\n--- New episode ---\n")
    
    # Print out some info
    print("\n--- Turn %d, Episode %d ---" % (turn_number, number_of_episodes))
    print("Player 1 limb positions: "+str(state))
    print("Reward: "+str(reward))

    turn_number += 1

# Close the environment
env.close()

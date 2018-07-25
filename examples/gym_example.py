#!/usr/bin/env python3
#
#  gym_example.py
#  A minimalistic example running ToriLLE OpenAI Gym Environment 
#
#  Author: Anssi "Miffyli" Kanervisto, 2018
import gym
import torille.envs
import random as r

# How many games will be played
NUM_EPISODES = 5

# If game should be shown (also limits FPS)
DRAW_GAME = True

# Create and initialize environment
env = gym.make("Toribash-RunAway-v0")
# Set visibility/drawing
env.set_draw_game(DRAW_GAME)

# You can change the settings from the ones set by environment
# BUT: These only apply on next call to "reset()", and you
# may not call reset whenever you please!
env.settings.set("matchframes", 1000)

# Record replay file of the game for later playback
# by setting this to something else than "None"/None.
# This will record replay file under [toribash directory]/replay
# at the end of the episode.
# Note: Remember to change this setting between episodes!
#       Otherwise your replays will be overwritten!
#env.settings.set("replay_file", "replay_filename")

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

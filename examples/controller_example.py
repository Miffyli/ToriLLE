#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  basic_example.py
#  A minimalistic example running ToribashController
#
#  Author: Anssi "Miffyli" Kanervisto, 2018
from ..controller.torille import ToribashControl
from threading import Lock
import random as r

# How many games will be played
NUM_EPISODES = 5

# If game should be rendered or not
DRAW_GAME = True

# This function will be used to create random actions
def create_random_actions():
    """ Return random actions """
    ret = [[],[]]
    # Actions for both players
    for plridx in range(2):
        # There are 22 joints which require action from {1,2,3,4}
        for jointidx in range(22):
            ret[plridx].append(r.randint(1,4))
    return ret    
    
# Create ToribashController. This won't launch the game yet
controller = ToribashControl(draw_game = DRAW_GAME)

# Set some settings. You can find more info on these from Toribash forums / game
# How long one game is
controller.settings.set("matchframes", 1000)
# How many frames one action will be repeated for
# AKA "frame skip", "action repeat"
controller.settings.set("turnframes", 1)
# How far two players will spawn
controller.settings.set("engagement_distance", 1000)

# Print the settings
print("--- Settings ---\n"+str(controller.settings))

# This will launch the game (takes bit of time)
controller.init()

# Main loop
number_of_episodes = 0
turn_number = 0
while number_of_episodes < NUM_EPISODES:
    # Get the current state and info if the episode was terminal
    state, terminal = controller.get_state()
    
    # If state was terminal (game has ended), restart the episode
    # and get the new state.
    # With default settings (no disqualification), this corresponds to 
    # playing for 'matchframes' number of frames
    if terminal: 
        # Begin a new game and receive the initial state
        state = controller.reset()
        # Keep count of played episodes
        number_of_episodes += 1
        turn_number = 0
        print("\n--- New episode ---\n")

    # Create some actions based on state. Here we only take random actions
    actions = create_random_actions()
    
    # Send the actions to Toribash for execution
    # Game will progress for one turn, and wait for next get_state()
    controller.make_actions(actions)
    
    # Print out some info
    print("\n--- Turn %d, Episode %d ---" % (turn_number, number_of_episodes))
    print("Player 1 limb positions: "+str(state.limb_positions[0]))
    print("Player 1 joint states: "+str(state.joint_states[0]))
    print("Player 1 injury: "+str(state.injuries[0]))

    turn_number += 1

# Close the environment
controller.close()

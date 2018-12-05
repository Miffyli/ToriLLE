#!/usr/bin/env python3
#
#  controller_example.py
#  A minimalistic example running ToribashController
#
#  Author: Anssi "Miffyli" Kanervisto, 2018
from torille import ToribashControl
import random as r

# How many games will be played
NUM_EPISODES = 5

# If game should be rendered or not
DRAW_GAME = True

# Create ToribashController. This won't launch the game yet
controller = ToribashControl(draw_game = DRAW_GAME)

# Set some settings. You can find more info on these from Toribash forums / game
# First, we need to enable custom settings
controller.settings.set("custom_settings", 1)
# How long one game is 
controller.settings.set("matchframes", 1000)
# How many frames one action will be repeated for
# AKA "frame skip", "action repeat"
controller.settings.set("turnframes", 2)
# How far two players will spawn
controller.settings.set("engagement_distance", 200)
# Record replay file of the game for later playback
# by setting this to something else than "None"/None.
# This will record replay file under [toribash directory]/replay
# at the end of the episode.
# Note: Remember to change this setting between episodes!
#       Otherwise your replays will be overwritten!
#controller.settings.set("replay_file", "replay_filename")

# Print the settings
print("--- Settings ---\n"+str(controller.settings))

# This function will be used to create random actions
def create_random_actions():
    """ Return random actions """
    ret = [[],[]]
    # Actions for both players
    for plridx in range(2):
        # Get number of controllable joints from Toribash
        for jointidx in range(controller.get_num_joints()):
            ret[plridx].append(r.randint(1,4))
    return ret  

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
        # Print the winner of the game
        print("Game over. Winner: %d" % state.winner)
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
    print("Player 1 limb positions:\n"+str(state.limb_positions[0]))
    print("Player 1 limb velocities:\n"+str(state.limb_velocities[0]))
    print("Player 1 groin rotations:\n"+str(state.groin_rotations[0]))
    print("Player 1 joint states: "+str(state.joint_states[0]))
    print("Player 1 injury: "+str(state.injuries[0]))
    print("Match length: "+str(state.match_length))
    print("Frames played: "+str(state.match_frame))
    print("Frames next turn: "+str(state.frames_next_turn))
    turn_number += 1
    input()
    
# Close the environment
controller.close()

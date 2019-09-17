#!/usr/bin/env python3
#
#  replay_example.py
#  A minimalistic example of going through an
#  existing replay file
#
#  Author: Anssi "Miffyli" Kanervisto, 2019
from torille import ToribashControl

# Path to the replay file inside Toribash's "replay" folder.
# Make sure this file exists!
# You can find bunch of cool replays along with Toribash installation
REPLAY_FILE = "0headkick.rpl"

# You can enjoy the replay file being played
DRAW_GAME = False

# Create ToribashController. This won't launch the game yet
controller = ToribashControl(draw_game=DRAW_GAME)
controller.init()

# `init()` begins a new game, and we need to reach end
# of the episode to be able to start with a replay
controller.finish_game()

# Read the replay file and go through it.
# We will end up with list of ToribashStates
states = controller.read_replay(REPLAY_FILE)

print("Obtained %d ToribashStates" % len(states))

# Close the environment
controller.close()

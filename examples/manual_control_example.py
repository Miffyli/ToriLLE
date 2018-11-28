#!/usr/bin/env python3
#
#  manual_control_example.py
#  A minimalistic example of running random agent
#  on manually launched control script (manual_remotecontrol.lua)
#
#  Author: Anssi "Miffyli" Kanervisto, 2018
from torille import ManualToribashControl
from torille.constants import NUM_CONTROLLABLES
import random as r

def create_random_actions():
    """ 
    Returns random actions for one player
    """
    ret = []
    # Actions for both players
    for jointidx in range(NUM_CONTROLLABLES):
        ret.append(r.randint(1,4))
    return ret  

# Create the controller
controller = ManualToribashControl()

# Connect to the Toribash instance.
# Note that you have to manually start the "manual_remotecontrol.lua"
# script in Toribash.
controller.connect_to_toribash()

# Main loop for one game. 
# Note that ManualToribashControl only plays one game and 
# then disconnects
turn_number = 0
while True:
    # Get the current state and info if the episode was terminal
    state, terminal = controller.get_state()
    
    # If state was terminal, quit
    # (ToribashManualControl plays only one game at a time)
    if terminal:
        break

    # Create some actions based on state. Here we only take random actions
    actions = create_random_actions()
    
    # Send the actions to Toribash for execution
    # Game will progress for one turn, and wait for next get_state()
    controller.make_actions(actions)
    
    # Print out some info
    print("\n--- Turn %d" % turn_number)
    print("Player 1 limb positions:\n"+str(state.limb_positions[0]))
    print("Player 1 limb velocities:\n"+str(state.limb_velocities[0]))
    print("Player 1 groin rotations:\n"+str(state.groin_rotations[0]))
    print("Player 1 joint states: "+str(state.joint_states[0]))
    print("Player 1 injury: "+str(state.injuries[0]))
    turn_number += 1

# Close the connection.
# ToribashManualControl already does this under the hood, but
# does not hurt to make sure it is closed
controller.close()

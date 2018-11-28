# Manual Torille

To play Toribash remotely in multiplayer mode, 
`manual_remotecontrol.lua` provides simpler but manual 
version of regular remotecontrol. This requires human player to launch
the Lua script from game, and also separately launching the remote 
controller code. It also requires human player to press SPACE
to proceed a turn.

This is designed to be used with multiplayer mode.

### Installation

Toribash requires somewhat modern version for multiplayer game to work,
as well as an account (only requires an username and password). 

**As of writing (28.11.2018): Multiplayer does not work on Linux Wine!**

1) Install Toribash the normal way
2) Copy following files:
  * From `toribash-codes`, copy `socket/` and `socket.lua` to main Toribash install directory.
  * From `toribash-codes/data/script` copy `manual_remotecontrol.lua` and `startup.lua` to `[Toribash directory]/data/script`, and overwrite.

### Usage

The manual remote control has protocol similar to regular remote control.
except only one player is controlled (hence takes actions only for one player).

To play one game of Toribash with the remote control:

1) Launch Toribash, enter a game (multiplayer or not) and launch `manual_remotecontrol.lua` script in Toribash
2) Launch your remote control code (e.g. `examples/manual_control_example.py`)
3) The remote control code now sets character's actions, **but you have to manually proceed to next turn**. 
4) Remote controlling ends once episode finishes, i.e. you have to launch Lua script again manually to play another round.



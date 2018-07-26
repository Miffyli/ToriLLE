# Hacking & contributing to ToriLLE

This guide aims to offer quick trip to how to add and modify things in ToriLLE.

There are two parts that need modifying:

1. Toribash Lua script `remotecontrol.lua`
2. The controller (e.g. the Python code `torille.py`). Not discussed here, as it is mostly trivial processing of the data.

## Toribash Lua script

Toribash codes reside in `toribash-codes` directory at root of this repository.

All interaction with Toribash is done via its Lua scripting capabilities.
Scripts are stored in `[toribash folder]/data/scripts` folder, and the main script used by ToriLLE is 
`remotecontrol.lua`. 
Additional Lua files remove UI elements and other startup things we do not want.
Lua library luasocket is used to handle communication over TCP/IP. 

Modifying this side consists mainly of getting/setting the information you want with
Lua functions, and then using opened socket `s` to send/receive data to/from remote end. 

Useful links:
* [Chat options/settings](http://forum.toribash.com/showthread.php?t=317900) 
* [Raw list of (older) Toribash Lua functions](http://forum.toribash.com/showthread.php?t=317900)
* Check `[toribash folder]/data/scripts/sdk` for examples on different Lua functions Toribash has.

## Communication

See `protocol/` for detailed explanations on the messages between controller and Toribash Lua scripts.

Note that all messages should end with `\ņ` character both ways. TCP/IP may break single message into
multiple packets occasionally, so you may have to manually read till `\n` character is read (had to do with Python)

Be careful when coding these Lua scripts: Toribash may not print any errors on invalid calls and such,
so be sure to double-check your code before you call it a day! 

Data is sent and received as comma-separated lists, ending to `\n`. No variable-names/keys were included
to save on the bandwidth.

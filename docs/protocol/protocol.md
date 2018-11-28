Protocol for Toribash remote controlling
========================================

**All communication is in UTF-8 encoded strings**

**All communication (`send`s) must end with `\n`**

Terms
-----
* Toribash: One running instance of Toribash game
* Controller: The software/piece of code which will control Toribash
* Player1: One of the players. This one is referred as "player" in Toribash documentation.
* Player2: One of the players. This one is referred as "uke" in Toribash documentation.

Overview (pseudo-codes)
-----------------------
### Toribash
```python
connection = connect_to_controller()
render_settings = recv_render_settings()
apply_render_settings()
settings = recv_settings()
apply_settings()
while connection_alive:
    send_state()
    actions = recv_actions()
    apply_actions(actions)
    
    proceed_to_next_state()
    
    if end_of_round:
        send_winner_and_state_and_end()
        settings = recv_settings()
        apply_settings(settings)
        new_game()
```

### Controller
```python
connection = wait_for_connection()
send_render_settings([1 or 0])
send_settings([some settings])
while connection_alive:
    state = recv_state()
    if state == "end":
        read_winner()
        send_settings([some settings])
    else:
        send_actions([some actions])
```

Establishing connection
-----------------------
* Toribash must launch `remotecontrol.lua` script. This is done on launching Toribash if provided `profile.tbs` is present next to ´toribash.exe`
* Toribash will TCP connect to `CONNECT_IP` at port `CONNECT_PORT` (specified in `remotecontrol.lua`)
* Controller listens for TCP connections at port `CONNECT_PORT` for `TIMEOUT` seconds (specified in `remotecontrol.lua`)
* If connection is made:
* Toribash waits for data from controller
* Toribash attempts to parse received data as decimal 1 or 0
* Toribash applies rendering settings accordingly (1 = render game, 0 = no rendering)
* Toribash moves to "Receive settings"

Receive settings
----------------
* Toribash waits for data from controller
* Toribash attempts to parse received data as settings (`settings_structure.md`)
* Toribash applies settings
* Toribash starts a new game and proceeds to "Sharing state" 

Sharing state
-------------
* At start of new turn, Toribash builds comma-separated string of state (`state_structure.md`)
* Toribash sends this string to controller
* Toribash proceeds to "receive action"

Receive action
--------------
* Toribash waits for `TIMEOUT` seconds for data from controller (specified in `remotecontrol.lua`) 
* If data is read from connection, Toribash attempts to parse actions according to specifications (`action_structure.md`)
* Toribash updates joint states according to received actions
* Toribash proceeds to next state (i.e. presses [SPACEBAR] to proceed specified amount of time)
* __If round ended__, Toribash proceeds to "Game finished"
* __Else__ Toribash proceeds to "Sharing state"

Game finished
-------------
* Toribash sends message a message, winner and state to signal end of game:
  * Message begins with "end:"
  * Next one-digit integer specifies winner (0 = tie, 1 = player1 won, 2 = player2 won)
  * Rest of the message is standard state
* Toribash moves to "Receive settings"

Quitting
--------
* All communications have timeout of `TIMEOUT` seconds. If no data is received in that time,
  Toribash will kill the connection and stop receiving further commands
* Controller process may kill Toribash process without issues at any point

Error situations
----------------
* As of writing, Toribash **does not** sanity check for wrong type of data structures (e.g. too many / not enough items in state, actions outside of {1,2,3,4})
    * If such information is sent, Toribash LUA script will crash and won't proceed, and socket TIMEOUT will eventually be triggered.
    
Notes
-----
* Always read till `\n` character is received at the end of message! LUA socket send 
seems to split the packet into multiple chunks often.

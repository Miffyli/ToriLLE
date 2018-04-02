Protocol for Toribash remote controlling
========================================

** All communication is in UTF-8 encoded strings **

** All communication (`send`s) must end with `\n` **

Terms
-----
* Toribash: One running instance of Toribash game
* Server: The software/piece of code which will control Toribash

Overview (pseudo-codes)
-----------------------
### Toribash
```python
connection = connect_to_server()
while connection_alive:
    send_state()
    actions = recv_actions()
    apply_actions(actions)
    
    proceed_to_next_state()
    
    if end_of_round:
        send_state_and_end()
        settings = recv_settings()
        apply_settings(settings)
        new_game()
```

### Server
```python
connection = wait_for_connection()
while connection_alive:
    state = recv_state()
    if state == "end"
        send_settings([some settings])
    else:
        send_actions([some actions])
```

Establishing connection
-----------------------
* Toribash must launch `remotecontrol.lua` script 
* Toribash will TCP connect to `CONNECT_IP` at port `CONNECT_PORT` (specified in `remotecontrol.lua`)
* Server listens for TCP connections at port `CONNECT_PORT`
* If connection is made, this is considered handshake and start of remote control
* Toribash now starts a new game and proceeds to "Sharing state"

Sharing state
-------------
* At start of new turn, Toribash builds comma-separated string of state (`state_structure.txt`)
* Toribash sends this string to server
* Toribash proceeds to "receive action"

Receive action
--------------
* Toribash waits for `TIMEOUT` seconds for data from server (specified in `remotecontrol.lua`) 
* If data is read from connection, Toribash attempts to parse actions according to specifications (`action_structure.txt`)
* Toribash updates joint states according to received actions
* Toribash proceeds to next state (i.e. presses [SPACEBAR] to proceed specified amount of time)
* __If round ended__, Toribash proceeds to "Game finished"
* __Else__ Toribash proceeds to "Sharing state"

Game finished
-------------
* Toribash sends message and state to signal end of game ("end" as the first item in the list).
* Toribash waits for data from server
* Toribash attempts to parse received data as settings (`settings_structure.txt`)
* Toribash applies settings
* Toribash proceeds to "Sharing state" with new game

Quitting
--------
* All communications have timeout of `TIMEOUT` seconds. If no data is received in that time,
  Toribash will kill the connection and stop receiving further commands
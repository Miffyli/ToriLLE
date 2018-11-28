Protocol for Toribash manual remote controlling
===============================================

**All communication is in UTF-8 encoded strings**

**All communication (`send`s) must end with `\n`**

Terms
-----
* Toribash: One running instance of Toribash game
* Controller: The software/piece of code which will control Toribash
* Player1: One of the players. This one is referred as "player" in Toribash documentation.

Overview (pseudo-codes)
-----------------------
### Toribash
```python
connection = connect_to_controller()
while game has not ended:
    send_state()
    actions = recv_actions()
    apply_actions(actions)
    
    if end_of_round:
        send_winner_and_state_and_quit()
```

### Controller
```python
connection = wait_for_connection()
while connection_alive:
    state = recv_state()
    if state == "end"
        read_winner()
        quit()
    else:
        send_actions([some actions])
```

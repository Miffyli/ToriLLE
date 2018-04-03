# ToriLLE
Toribash Learning Environment

# Todos
### Fixes/Problems/Bugs:

- "Daily reward" blocks the game on startup 
    - Does not prevent running the code, but code runs slow
    - Maybe could be closed with another close_manu()?
- Move all settings in the drawer hook
    - Create new function for these
- Create Toribash instance from Python and moderate it
- Episode restart is rather slow, especially if all instances reboot at once
    - Could this be better if e.g. we move all files to ram?
- Something else seems to be slowing down things too
    - With "set matchframes 1000", results on 16-core machine with sync code:
        - 4 instances: 500 FPS
        - 8 instances: 700 FPS
        - 16 instances: 1000 FPS
    - Seems to hang for a moment every now and then, even not between
      episodes

### Feature/soon-to-be-done TODOs:

- Add rotations to the state representation?
- Specify settings set at the beginning of the episode 
    - Define settings structure
    - engagement distance
    - game mode?
    - gravity? 
- Add more options (via make_cmd etc). 
    - Could make game lighter etc
    - Resolution ("/res w h")
- Make changing gamemod possible
    - E.g. sumo
    - Is this really needed?
    
### Future TODOs:

- Add swords and other items
- Add description of the environment
- Add possibility to use rendered images?

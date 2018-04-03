# ToriLLE
Toribash Learning Environment

# Todos
### Fixes/Problems/Bugs:

- "Daily reward" blocks the game on startup 
    - Does not prevent running the code, but code runs slow
    - Maybe could be closed with another close_manu()?
- Move all settings in the drawer hook
    - Create new function for these
- Episode restart is rather slow, especially if all instances reboot at once
    - Could this be better if e.g. we move all files to ram?
- Something else seems to be slowing down things too
    - "/opt autoupdate 0" seems to help with this issue
    - There still seems to be some sort of disk I/O every now and then
    - Seems to hang for a moment every now and then, even not between episodes
    - Benchmarking: Calculate time it took to get 5000 steps
    - Note: Synchronous
    - FPS = Frames per Second, but here "Frame" = Taking one action
    - With "set matchframes 1000" and "set turnframes 1":
        - 16-core Ubuntu (2.1Ghz, Titan XP)
            - 1 instance:   FPS
            - 4 instances:  FPS
            - 8 instances:  FPS
            - 16 instances:  FPS
        - 4-core Windows 10 (4.5Ghz, RX 480)
            - 1 instance:   300 FPS
            - 4 instances:  700 FPS
            - 8 instances:  850 FPS
            - 12 instances: 800-1000 FPS
            - 16 instances: Crash
    - With "set matchframes 100" and "set turnframes 1":
        - 16-core Ubuntu (2.1Ghz, Titan XP)
            - 4 instances: 
            - 8 instances: 
            - 16 instances: 
        - 4-core Windows 10 (4.5Ghz, RX 480)
            - 1 instance:   280 FPS
            - 4 instances:  650 FPS
            - 8 instances:  700-800  FPS
            - 12 instances: 700 FPS
            - 16 instances: Crash
    - With "set matchframes 1000" and "set turnframes 10":
        - 16-core Ubuntu (2.1Ghz, Titan XP)
            - 4 instances: 
            - 8 instances: 
            - 16 instances: 
        - 4-core Windows 10 (4.5Ghz, RX 480)
            - 1 instance:   75  FPS
            - 4 instances:  175 FPS
            - 8 instances:  200 FPS
            - 12 instances:  FPS
            - 16 instances: Crash
    - With "set matchframes 100" and "set turnframes 1". RAM-disk:
        - 16-core Ubuntu (2.1Ghz, Titan XP)
            - 4 instances: 
            - 8 instances: 
            - 16 instances: 
        - 4-core Windows 10 (4.5Ghz, RX 480)
            - 1 instance:   250 FPS
            - 4 instances:  430 FPS
            - 8 instances:   FPS
            - 12 instances:  FPS
            - 16 instances: Crash
- Running code on server without screen (e.g. csdeepen over SSH)
    - Even with ' xvfb-run -s "-screen 0 1400x900x24" bash ' there are errors
    - Maybe try " wine explorer /desktop=Halo,1400x1050 " trick?     
- Toribash instances do not close on Windows when Python script exits. Manually terminate processes.
- Start by sending settings

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

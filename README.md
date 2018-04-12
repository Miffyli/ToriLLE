# ToriLLE
Toribash Learning Environment

# Todos
### Fixes/Problems/Bugs:

- "Daily reward" blocks the game on startup 
    - Does not prevent running the code, but code runs slow
    - Maybe could be closed with another close_manu()?
- Running code on server without screen (e.g. csdeepen over SSH)
    - Even with ' xvfb-run -s "-screen 0 1400x900x24" bash ' there are errors
    - Maybe try " wine explorer /desktop=Halo,1400x1050 " trick?     
- Toribash instances do not close on Windows when Python script exits. Manually terminate processes.
- Start by sending settings
- Add sanity checking for sending actions (game jams without any errors if wrong type of actions are sent)
- Even with locking, trying to run multiple processes on Ubuntu throws "socket in use"

### Feature/soon-to-be-done TODOs:

- Consider moving hand joint thing to somewhere else?
    - Causes confusion when it is {0,1} while others are {1,2,3,4}
    - Maybe normalize these somehow?
- Move all settings in the drawer hook
    - Create new function for these
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
- Something else seems to be slowing down things too
    - "/opt autoupdate 0" seems to help with this issue
    - There still seems to be some sort of disk I/O every now and then
    - Seems to hang for a moment every now and then, even not between episodes
    - Benchmarking: Calculate time it took to get 5000 steps
    - Note: Synchronous
    - Minimizing window helps
    - FPS = Frames per Second, but here "Frame" = Taking one action
    - With "set matchframes 1000" and "set turnframes 1":
        - 16-core Ubuntu (2.1Ghz, Titan XP)
            - 1 instance:   200 FPS
            - 4 instances:  400 FPS
            - 8 instances:  500 FPS
            - 16 instances:  FPS
        - 4-core Windows 10 (4.5Ghz, RX 480)
            - 1 instance:   300 FPS
            - 4 instances:  700 FPS
            - 8 instances:  850 FPS
            - 12 instances: 800-1000 FPS
            - 16 instances: Crash
        - 4-core Ubuntu (3.5Ghz, headless / software rendering)
            - 1 instance:   150 FPS (180 FPS with resolution 80x60x24 )
            - 4 instances:  280 FPS (300 FPS with resolution 80x60x24)
            
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
            - 1 instance:   50 FPS
            - 4 instances:  100 FPS
            - 8 instances:  120 FPS
            - 16 instances: 
        - 4-core Windows 10 (4.5Ghz, RX 480)
            - 1 instance:   75  FPS
            - 4 instances:  175 FPS
            - 8 instances:  200 FPS
            - 12 instances:  FPS
            - 16 instances: Crash
    - With "set matchframes 100" and "set turnframes 1". RAM-disk:
        - 4-core Windows 10 (4.5Ghz, RX 480)
            - 1 instance:   250 FPS
            - 4 instances:  430 FPS
            - 8 instances:   FPS
            - 12 instances:  FPS
            - 16 instances: Crash
     
- Episode restart is rather slow, especially if all instances reboot at once
    - Could this be better if e.g. we move all files to ram?

### Future TODOs:

- Add swords and other items
- Add description of the environment
- Add possibility to use rendered images?

# Running on Linux (tested Ubuntu 16.04)
Windows binaries run well with Wine.

## Headless on Linux
Game won't launch without a display (requires OpenGL).
Using Xvfb you can create a virtual display, e.g.

`xvfb-run -s "-screen 0 800x600x24" path_to_toribash_exe`

### Troubleshooting for headless
- Nvidia drivers do not work well with Xvfb. You will likely get some errors about GLX.
    - But fear not, you "only" have to reinstall drivers/CUDA without OpenGL files if you need the drivers:
    - This gist covers the reinstallation: https://gist.github.com/8enmann/931ec2a9dc45fde871d2139a7d1f2d78
        - **However** on Ubuntu 16.04 you may get "pre-install script failed" or "build error" messages:
            - Download other version of drivers than suggested 384.59. For me version 387.34 installed correctly.
            - (Possibly optional) Check if you have `/usr/lib/nvidia/pre-install` file. If it only has `exit 1`, rename/remove this file.

# Related projects

- Similar control structure (game <-> lua <-> sockets <-> Python/etc) is used in [MarioFlow](https://docs.google.com/document/d/1p4ZOtziLmhf0jPbZTTaFxSKdYqE91dYcTNqTVdd6es4) by SethBling for controlling player in Super Mario Kart.
# ToriLLE
Toribash Learning Environment

# Setup (14.4.2018)
**This will override `data/scripts/startup.lua` file in Toribash.**
1. Copy contents of `toribash` directory into Toribash game folder (`profile.tbs` should be next to `toribash.exe`)
2. Launch the game. It should stay stuck in white screen for a period of time (attempts to connect to controller).
   This will also set up some settings for faster execution.

# Useful links

* Some options: http://forum.toribash.com/showthread.php?t=317900
* LUA functions: https://github.com/trittimo/ToriScriptAPI/blob/master/docs/toribash_docs.txt
* Bodypart list: http://forum.toribash.com/showthread.php?t=9391
* Previous attempts at machine learning on Toribash: 
  * http://forum.toribash.com/showthread.php?t=170100
  * http://forum.toribash.com/showthread.php?t=167355
  * http://forum.toribash.com/showthread.php?t=25263
  * https://www.researchgate.net/profile/Jonathan_Byrne/publication/228848637_Optimising_offensive_moves_in_toribash_using_a_genetic_algorithm/links/0046351420d5001396000000.pdf

# Todos
### Fixes/Problems/Bugs:

- "Daily reward" blocks the game on startup 
    - Does not prevent running the code, but code runs slow
    - Maybe could be closed with another close_manu()?
- Toribash instances do not close on Windows when Python script exits. Manually terminate processes.

### Feature/soon-to-be-done TODOs:

- Consider moving hand joint thing to somewhere else?
    - Causes confusion when it is {0,1} while others are {1,2,3,4}
    - Maybe normalize these somehow?
- Add rotations to the state representation?
- Make changing gamemod possible
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
- A2C does not seem to work, at least in this environment  
- Add possibility to "display window" and run the game at reasonable speed

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

## Troubleshooting for headless
- Nvidia drivers do not work well with Xvfb. You will likely get some errors about GLX.
    - But fear not, you "only" have to reinstall drivers/CUDA without OpenGL files if you need the drivers:
    - This gist covers the reinstallation: https://gist.github.com/8enmann/931ec2a9dc45fde871d2139a7d1f2d78
        - **However** on Ubuntu 16.04 you may get "pre-install script failed" or "build error" messages:
            - Download other version of drivers than suggested 384.59. For me version 387.34 installed correctly.
            - (Possibly optional) Check if you have `/usr/lib/nvidia/pre-install` file. If it only has `exit 1`, rename/remove this file.

# Related projects

- Similar control structure (game <-> lua <-> sockets <-> Python/etc) is used in [MarioFlow](https://docs.google.com/document/d/1p4ZOtziLmhf0jPbZTTaFxSKdYqE91dYcTNqTVdd6es4) by SethBling for controlling player in Super Mario Kart.
# ToriLLE
Toribash Learning Environment

## Requirements
* Numpy
* FileLock

## Setup (14.4.2018)
**This will override `data/scripts/startup.lua` file in Toribash.**
1. Copy contents of `toribash` directory into Toribash game folder (`profile.tbs` should be next to `toribash.exe`)
2. Launch the game. It should stay stuck in white screen for a period of time (attempts to connect to controller).
   This will also set up some settings for faster execution.

Minimizing the Toribash game speeds up execution. 

## Notes
- Launching a Toribash instance requires a lock to avoid mixing up connections with controller,
hence booting up multiple Toribashes at same time will take time!

## Useful links

* Some options: http://forum.toribash.com/showthread.php?t=317900
* LUA functions: https://github.com/trittimo/ToriScriptAPI/blob/master/docs/toribash_docs.txt
* Bodypart list: http://forum.toribash.com/showthread.php?t=9391
* Previous attempts at machine learning on Toribash: 
  * http://forum.toribash.com/showthread.php?t=170100
  * http://forum.toribash.com/showthread.php?t=167355
  * http://forum.toribash.com/showthread.php?t=25263
  * https://www.researchgate.net/profile/Jonathan_Byrne/publication/228848637_Optimising_offensive_moves_in_toribash_using_a_genetic_algorithm/links/0046351420d5001396000000.pdf

## Todos
### Fixes/Problems/Bugs:

- Toribash instances do not close on Windows when Python script exits. Manually terminate processes.
- Some settings do not seem to be adjustable from commands (e.g. shaders). Provide appropiate config file?
- Make Toribash windows go minimized on launch (increases fps)
- Add possibility to get default options (torille.get_default.settings)
- Add gym-like calls? (make, get action space, etc)
- Consider increasing TIMEOUT time (some agents may take long time to boot)
- Consider using simple filelocking for locking
- Add possibility to change the port and listening address

### Feature/soon-to-be-done TODOs:

- Add state-machine-like checking for better error reporting
- Make gym-env
- Add rotations to the state representation?
- Make changing gamemod possible
- Make Torille pip-installable (maybe even include Toribash binary?)
    - Permission from hampa to share it
    - Contents of following directories can be removed:
        - "custom"
        - "replay"
        - "Extra Content"
        - "data/script/torishop"
        - "data/script/atmo"
        - "data/script/clans"
        - "data/sounds"
    - (500MB -> 40MB)
- Something else seems to be slowing down things too
    - Machines: 
        - Windows 10 with 3770k 4.5Ghz and 2700x 4.3Ghz (RX 480, SSD). 
        - Ubuntu with W-2125 4.5Ghz (1080, M.2 SSD) and 16-core Xeon 2.1Ghz (Titan XP, M.2 SSD).
        - Ubuntu uses Nvidia drivers for on-monitor playing, software-based OpenGL for headless.
        - In-display playing is done with game window(s) minimized
    - Asynchronous processes, windows minimized. Measured in chunks of 10s
    - Engagement distance 1000 (no contact)
    - FPS: Frames per second (frame = one "tick" of Toribash time)
    - PPS: Predictions per second (Prediction = Getting one state and giving actions)
    - With "set matchframes 1000" and "set turnframes 1":
        - 16-core Ubuntu (2.1Ghz, Titan XP, SSD, in-display/nvidia drivers)
            - 1 instance:   200  FPS/PPS
            - 2 instances:  390  FPS/PPS
            - 4 instances:  650  FPS/PPS
            - 8 instances:  1300 FPS/PPS
            - 16 instances: 2800 FPS/PPS
            - 32 instances: 3700 FPS/PPS
        - 4-core Windows 10 (4.5Ghz, RX 480)
            - 1 instance:   430  FPS/PPS
            - 2 instances:  830  FPS/PPS
            - 4 instances:  1350 FPS/PPS
            - 8 instances:  1600 FPS/PPS
        - 4-core Ubuntu (4.5Ghz, GTX 1080, SSD)
            - 1 instance:   250  FPS/PPS
            - 2 instances:  520  FPS/PPS
            - 4 instances:  1108 FPS/PPS
            - 8 instances:  1600 FPS/PPS
    - With "set matchframes 1000" and "set turnframes 10":
        - 16-core Ubuntu (2.1Ghz, Titan XP, SSD, in-display/nvidia drivers)
        - 4-core Windows 10 (4.5Ghz, RX 480, HDD)
            - 1 instance:   100 PPS, 1000 FPS
            - 2 instances:  200 PPS, 2000 FPS
            - 4 instances:  325 PPS, 3250 FPS
            - 8 instances:  410 PPS, 4110 FPS
        - 4-core Ubuntu (4.5Ghz, GTX 1080, SSD)
            - 1 instance:   70  PPS, 700 FPS
            - 2 instances:  130 PPS, 1300 FPS
            - 4 instances:  270 PPS, 2700 FPS
            - 8 instances:  400 PPS, 4000 FPS
    - With "set matchframes 100" and "set turnframes 10":
        - Some disk I/O going on here (in Windows task manager). Episode restart?
        - 16-core Ubuntu (2.1Ghz, Titan XP, SSD, in-display/nvidia drivers)
        - 4-core Windows 10 (4.5Ghz, RX 480, HDD)
            - 1 instance:   68  PPS, 680  FPS
            - 2 instances:  120 PPS, 1200 FPS
            - 4 instances:  154 PPS, 1540 FPS
            - 8 instances:  170 PPS, 1700 FPS
        - 4-core Ubuntu (4.5Ghz, GTX 1080, SSD)
            - 1 instance:   50  PPS,  500 FPS
            - 2 instances:  95  PPS,  950 FPS
            - 4 instances:  195 PPS, 1950 FPS
            - 8 instances:  300 PPS, 3000 FPS
- Episode restart is rather slow, especially if all instances reboot at once
    - Could this be better if e.g. we move all files to ram?
- A2C does not seem to work, at least in this environment 
- Add possibility to "display window" and run the game at reasonable speed ("render=True")

### Future TODOs:
- Add swords and other items
- Add description of the environment
- Add possibility to use rendered images?

## Running on Linux (tested Ubuntu 16.04)
Windows binaries tested to work on Wine 3.0. **Note that distribution's own version may be outdated!**
Follow installation instrunctions [here](https://wiki.winehq.org/Download) to install appropiate version.

### Headless on Linux
Game won't launch without a display (requires OpenGL).
Using Xvfb you can create a virtual display, e.g.

`xvfb-run -s "-screen 0 80x60x24" path_to_toribash_exe`

or by separately running the Xvfb server

```
Xvfb :0 -screen 0 80x60x24 &
DISPLAY=:0 path_to_toribash.exe
```

This will run the game with software OpenGL renderer, reducing the FPS with ~25%.

### Troubleshooting for headless
- Nvidia drivers do not work well with Xvfb. You will likely get some errors about GLX.
    - But fear not, you "only" have to reinstall drivers/CUDA without OpenGL files if you need the drivers:
    - This gist covers the reinstallation: https://gist.github.com/8enmann/931ec2a9dc45fde871d2139a7d1f2d78
        - **However** on Ubuntu 16.04 you may get "pre-install script failed" or "build error" messages:
            - Download other version of drivers than suggested 384.59. For me version 387.34 installed correctly.
            - (Possibly optional) Check if you have `/usr/lib/nvidia/pre-install` file. If it only has `exit 1`, rename/remove this file.

## Related projects

- Similar control structure (game <-> lua <-> sockets <-> Python/etc) is used in [MarioFlow](https://docs.google.com/document/d/1p4ZOtziLmhf0jPbZTTaFxSKdYqE91dYcTNqTVdd6es4) by SethBling for controlling player in Super Mario Kart.

## Special thanks / Acknowledgements
- hampa and Dranix for invaluable help with configuring Toribash and lua scripts (also for developing the game in the first place!)
- Siim Põder (user "windo" on GitHub) for original [toribash-evolver](https://github.com/windo/toribash-evolver) code
- box (Toribash user) for comments during inception of this project

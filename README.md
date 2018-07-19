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

## Project structure
- **`./torille/`**: Python codes for the learning environment (inc. Gym environment)
  - **`./torille/toribash`**: This will include stripped version of the game when installed from python package
- **`./toribash-codes/`**: Files required for Toribash to make this learning environment work 
- **`./examples/`**: Python examples on how to use this library (inc. Gym environment example)
- **`./docs/`**: Detailed documentation of the inner workings (Python code reference, details of protocol between Python and Toribash)

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

- Update documentation
- Update/check license stuff
- Add .gif intro page
- Check/refine examples
- Refine directory structure
- Remove "v0" from env names? (Also remember to update the paper)

### Feature/soon-to-be-done TODOs:

- Make Toribash windows go minimized on launch (increases fps)
- More gym envs (especially one-v-one combat)
- Non-deterministic envs: Random starts, no-op starts, etc
- Add support for making replay?
- Add rotations to the state representation?
- Make changing gamemod possible
- Make Torille pip-installable (maybe even include Toribash binary?)
    - Permission from hampa to share it
    - Contents of following directories can be removed:
        - "custom"
        - "replay"
        - "Extra Content"
        - "customise"
        - "data/script/torishop"
        - "data/script/atmo"
        - "data/script/clans"
        - "data/sounds"
    - (500MB -> 40MB)

### Some ideas for future features:
- Add support for custom levels and items (e.g. swords)
- Add possibility to use rendered image rather than direct information

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

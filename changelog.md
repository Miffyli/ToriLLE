### 8.11.2018 v0.9.9

* Fixed Gym environments changing actions list in-place during call to `step`
* Added info on game winner to ending state
* Added rotation matrix of players' groins to game state
* Added velocities of body parts to game state
* Added "get_normalized_locations" function to game state
* Added normalization to Gym environments
* Added new duo-combat environment with winning reward (rather than injury reward)
* Torille now attempts to make stderr.txt file read-only to avoid huge files (on Linux/Darwin)

* Added code of new experiments to `experiments` folder


### 20.8.2018 v0.9.5

* Added support for Mac/OSX (with Windows binaries, *durr*)

### 20.8.2018 v0.9.3 and v0.9.4

* Fixed Gym environments on Windows

### 28.7.2018 v0.9.2

* Restructured Gym environments and added some more
* Added limit for turnframes [2,matchframes]. Later turnframes=1 might be made possible
* Fixed "static" frames at the start of learning: First few states were always the same
* Added sanity check for available displays on Linux (for $DISPLAY="")
* FPS on Windows 10 improved by ~10% 

### 27.7.2018 v0.9.1

* Removed resolution changes. This caused crashing on some Linux systems with Wine and windows
* Fixed Wine version checking

### 26.7.2018 v0.9.0

Initial public release.
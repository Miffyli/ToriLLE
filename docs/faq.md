# FAQ / Troubleshooting /  misc. docs

## How to hide the Toribash window that pops up?

This is not possible (currently) to do via Lua commands. This could be doable 
with access to the game's source by setting window hidden on creation.

## Hot do I run Toribash on remote Linux computers with display (e.g. over SSH)?

Set `DISPLAY` variable to point at attached display (usually `:0`). E.g:

`export DISPLAY=:0`

On Linux the environment variable `DISPLAY` specifies which screen buffer
should be used. When connecting over SSH this may be empty (no display) 
or something with `localhost`, indicating X-forwarding. Toribash
requires a valid display to create buffers. First case will prevent
Toribash from launching, while second one slows down Toribash considerably.

## How do I run Toribash on headless Linux servers (e.g. over SSH)?

Running on headless servers require virtual buffer like Xvfb.
After installing Xvfb you can create virtual buffer with following:

```
Xvfb :10 -screen 0 80x60x24 &
```

This will create new display with id `:10`. You then need to set sessions
display to this new one with 

```
export DISPLAY=:10
```

You can also launch game alone with `DISPLAY=:0 path_to_toribash.exe`
or even skip the first part with ``xvfb-run -s "-screen 0 80x60x24" your_launch_command`,
but we found explicitly setting the session's `DISPLAY` variable to be most convenient.

## Xvfb and Nvidia drivers

Nvidia drivers do not want to play nice with Xvfb: You can create a virtual buffer with
Xvfb, but OpenGL won't work in that display (throws mysterious errors).

To work around this you have to re-install Nvidia drivers without OpenGL drivers.
[This gist](https://gist.github.com/8enmann/931ec2a9dc45fde871d2139a7d1f2d78) shows step by step how it is done.
However you may want to select more up to date Nvidia driver version than "384.59" used in the gist 
(on Ubuntu 16.04, 384.59 did not even install correctly and we had to use 387.34).

After this running Toribash in Xvfb should work, but the game will be rendered using 
software rasterizer. This will slow down the game less than 50% (enough speed to still
make it comfortable for training agents over night). 

## How to render game on screen / watch gameplay?

For `ToribashControl`, give `draw_game=True` as a parameter when creating new object.

For Gym environments you can use `env.set_draw_game(True)` before first `reset()`.

This will enable most of the rendering, increase game window resolution and limit game's FPS
for easier watching.

These can only be set before launching the game.

## Recording and playing replays / How can I watch game on headless server? 

Your best bet is to store replays of your game by setting `replay_file` in `ToribashSettings`, copying saved
replays from `toribash/replay` directory (next to `toribash.exe`) and play them on different machine with Toribash game.

You can play replays by placing `.rpl` files under `[toribash_directory]/replay`, launching the game, navigating to 
`Options -> replays` and selecting your replay from there.

Replays take around 2.8MB with `matchframes=1000` and `turnframes=1`, and 1MB with `matchframes=1000` and `turnframes=5`

## Hand-grip actions (docs say they take {0,1}, but Python library takes {1,2,3,4}. What's up with this?)

Under the hood ToriLLE takes two kinds of joint states: Normal joint states {1,2,3,4} and hand-grip states {0,1}. 
To streamline things Python library takes in integer in {1,2,3,4} for hand-grips as well, but maps {1,2} => 0 and {3,4} => 1.

## Why does launching multiple `ToribashControl` instances take time?

To avoid mixing Toribash processes with corresponding `ToribashControl` instances, launching instances 
uses FileLock to prevent multiple instances being launched together.

This can fail if `ToribashControl` instances are using different Toribash executables.

## I installed Wine on MacOS but ToriLLE can't find it.

Installing Wine on MacOS may not add `wine` to `PATH`. Since different ways of installing
Wine may put it under different directories, you have to manually add appropiate path 
to `PATH`. Here is one example (note that directory may be different for you):

`export PATH=$PATH:"/Applications/Wine Stable.app/Contents/Resources/wine/bin/"`

## What is this "stderr.txt" and why should I worry about it?

Toribash dumps errors to "stderr.txt" file next to the main executable. This also includes some debug logging that 
happens between rounds. If Toribash is ran for days and thousands games in row, this file size increases to gigabytes.

ToriLLE Python code attempts to set this file read-only to prevent Toribash from writing to the file.

## Toribash launches with large window / limited FPS, or trying to launch vanilla Toribash has weird settings?

With Steam version of Toribash / Toribash 5.4, settings file of for Toribash is stored in user's home directory under
`Saved Games/Toribash/custom.cfg`. If this file exists, Toribash loads it instead of the local custom/default.cfg file.

You have to manually reset this file according to your needs.



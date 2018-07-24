# FAQ / misc. docs

## How to hide the window that pops up?

This is not possible (currently) to do via Lua commands. This could be doable 
with access to the game's source by setting window hidden on creation.

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



<p align="center">
  <img alt="Mating-ritual of two random agents" src="https://github.com/Miffyli/ToriLLE/raw/master/images/toribash.gif">
</p>

# ToriLLE
Toribash Learning Environment. Extra "L" to make words more memorable for Finns ("Torille" = "To the marketplace").

ToriLLE provides learning agents an interface to video-game [Toribash](http://www.toribash.com/), a humanoid fighting game.
Toribash provides environment for MuJoCo-like humanoid control, specifically aimed for competitive gameplay. This makes
ToriLLE suitable for e.g. self-play experiments. 

ToriLLE comes with a Python interface and pre-made OpenAI Gym environment with various tasks. Following white-paper includes baseline experiments and benchmarks conducted using ToriLLE: [https://arxiv.org/abs/1807.10110](https://arxiv.org/abs/1807.10110)

## Requirements
Tested to work on Windows 10 and Ubuntu 16.04. Tested on Python versions 3.5 and 3.6, and will likely not work on 2.7. 

* Numpy (Python)
* FileLock (Python)
* [Wine](https://wiki.winehq.org/Download) (For Linux. **Requires modern version. Tested on 3.0.3**)

## Quickstart
Remember to install [Wine](https://wiki.winehq.org/Download) if you are on Linux.

Following will download ToriLLE with stripped down version of Toribash:
```
pip install torille
```

Random agent:
```python
from torille import ToribashControl, create_random_actions

toribash = ToribashControl(draw_game=True)
# Show gameplay
toribash.init()

# Random agent
while 1:
    state, t = toribash.get_state()
    if t: break
    toribash.make_actions(create_random_actions())
toribash.close()
```

OpenAI Gym environment:
```python
import gym
import torille.envs

env = gym.make("Toribash-DestroyUke-v0")
# Show gameplay
env.set_draw_game(True)

initial_state = env.reset()
t = False
# Random agent
while not t:
    s, r, t, _ = env.step(env.action_space.sample())
env.close()
```

## Manual installation 

You can install ToriLLE without PyPI/pip with the following:

* Install [Toribash](www.toribash.com/)
* Copy contents of `toribash-codes` to Toribash installation directory. Overwrite files
  * **Note:** This will prevent using that specific installation as a regular game. Remove/rename `profile.tbs` file 
               to revert most of the changes and use game normally again.
* Provide path the installed `toribash.exe` when creating `ToribashControl` objects (if you use provided Python library)

## Documentation

Examples in `examples` provide quickstart to how to use ToriLLE, and also show how to apply settings or 
record replays.

For references see:

* [Python library](docs/torille.md)
* [Gym environment](docs/envs.md)

For troubleshooting, see the [FAQ](docs/faq.md).

If you wish to modify ToriLLE or use other language to control Toribash instance, see [hacking](docs/hacking.md) and [documentation on protocol](docs/protocol).

## Repository structure
- `./torille/`: Python codes for the learning environment (inc. Gym environment)
  - `./torille/toribash`: This will include stripped version of the Toribash game when installed from PyPi
- `./toribash-codes/`: Files required for Toribash to make this learning environment work 
- `./examples/`: Python examples on how to use this library
- `./docs/`: Detailed documentation of the inner workings
- `./experiments/`: Codes used to run experiments in the white paper
- `./images/`: Contains GIFs used here

## Related work and useful links

* Options/chat rules: http://forum.toribash.com/showthread.php?t=317900
* Lua functions: https://github.com/trittimo/ToriScriptAPI/blob/master/docs/toribash_docs.txt
* Bodypart list: http://forum.toribash.com/showthread.php?t=9391
* Previous experiments at machine learning with Toribash: 
  * http://forum.toribash.com/showthread.php?t=170100
  * http://forum.toribash.com/showthread.php?t=167355
  * http://forum.toribash.com/showthread.php?t=25263
  * https://www.researchgate.net/profile/Jonathan_Byrne/publication/228848637_Optimising_offensive_moves_in_toribash_using_a_genetic_algorithm/links/0046351420d5001396000000.pdf

## Citing

We wouldn't mind a citation if you find ToriLLE useful in your work. It also helps us to see what people have been up to!

```
@article{kanervisto2018torille,
  author = {Anssi Kanervisto and Ville Hautam{\"a}ki},
  title = {ToriLLE: Learning Environment for Hand-to-Hand Combat},
  year = {2018},
  journal = {arXiv preprint arXiv:1807.10110},
}
```

## Special thanks & Acknowledgements
- hampa and Dranix for invaluable help with configuring Toribash and lua scripts (also for developing the game in the first place!)
- Siim Põder (user "windo" on GitHub) for original [toribash-evolver](https://github.com/windo/toribash-evolver) code
- box (Toribash user) for comments during inception of this project

## License 
Code original to ToriLLE is licensed under GNU GPL 3.0. Toribash is property of Nabistudios. Toribash binary in PyPI package is shared with the permission of main developer "hampa".

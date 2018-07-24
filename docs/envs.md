# envs

ToriLLE comes with several pre-defined OpenAI Gym environments, which can be used
as a (almost) drop-in replacements to e.g. Atari environments.

Limitations: 
* `seed()` function is not implemented (can't change seed of Toribash)
* `render()` function is not implemented (only one type of state available)

Additional functions/modifications for all environments:
* `set_game_draw(draw)`: Enables/Disables rendering of the game according to boolean parameter.
* `reset(settings=None)` takes in ToribashState `settings` parameter for changing settings of game on reset.

### Pre-made environments

Register these environments by importing `torille.envs`.

#### `Toribash-RunAway-v0`

State: Body-part positions of both players
Action: Joint-states for player 1. Player 2 is immobile

Settings:

Setting | Value
------- | -----
matchframes | 1000
turnframes | 5
engagement_distance | 1500

Reward function: Positive reward for head body-part moving away from the center. See `torille.envs.solo_envs.reward_run_away`

#### `Toribash-DestroyUke-v0`

State: Body-part positions of both players
Action: Joint-states for player 1. Player 2 is immobile

Custom settings:

Setting | Value
------- | -----
matchframes | 1000
turnframes | 5

Reward function: Positive reward for damaging (immobile) opponent. See `torille.envs.solo_envs.reward_destroy_uke`

#### `Toribash-SelfDestruct-v0`

State: Body-part positions of both players
Action: Joint-states for player 1. Player 2 is immobile

Custom settings:

Setting | Value
------- | -----
matchframes | 1000
turnframes | 5
engagement_distance | 1500

Reward function: Positive reward for damaging the player itself (not the opponent). See `torille.envs.solo_envs.reward_self_destruct`

#### `Toribash-StaySafe-v0`

State: Body-part positions of both players
Action: Joint-states for player 1. Player 2 is immobile

Custom settings:

Setting | Value
------- | -----
matchframes | 1000
turnframes | 5
engagement_distance | 1500

Reward function: Negative reward for damaging the player itself (not the opponent). See `torille.envs.solo_envs.reward_stay_safe`

### Environment classes

#### `torille.envs.solo_envs.SoloToriEnv`

Base environment used to define "solo" tasks where only player 1 is controlled.

State includes body-part positions of both players, but takes in actions only for first player. 
Second player "holds" all the joints. 

Parameters:
* `reward_func`: A function that takes in previous and current `ToribashState` to calculate reward. 
                 See `torille.envs.solo_envs.reward_*` functions for examples.
* `**kwargs`: Rest of the keywords are fed to `ToribashController.__init__`. Can be used to e.g. set settings.

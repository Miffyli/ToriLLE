# envs

ToriLLE comes with OpenAI Gym environment and several pre-defined tasks, which can be used
as a (almost) drop-in replacements to e.g. Atari environments. 

Register these environments by importing `torille.envs`.

Limitations: 
* `seed()` function is not implemented (can't change seed of Toribash)
* `render()` function is not implemented (only one type of state available)

Additional functions/modifications for all environments:
* `set_game_draw(draw)`: Enables/Disables rendering of the game according to boolean parameter.
* `settings` variable: This is `ToribashState` object used to set Toribash's settings on each reset. 

## Solo environments `torille.envs.solo_envs.SoloToriEnv`

These are tasks where only one character exists (observations/actions only include one player).

Player 2 is set to be immobile and engagement distance is set high to avoid contact between players.

**States**: 1D vector of player 1 body part positions w.r.t player 1's groin (`gym.spaces.box.Box`).

**Actions**: Joint states for player 1 (`gym.spaces.multi_discrete.MultiDiscrete`).

Reward is specified by the task (see below).

Settings:

Setting | Value
------- | -----
matchframes | 1000
turnframes | 5
engagement_distance | 1500

#### `Toribash-RunAway-v0`

Reward function: Positive reward for head body-part moving away from the center. See `torille.envs.solo_envs.reward_run_away`.

#### `Toribash-SelfDestruct-v0`

Reward function: Positive reward for damaging the player itself (not the opponent). See `torille.envs.solo_envs.reward_self_destruct`.

#### `Toribash-StaySafe-v0`

Reward function: Negative reward for damaging the player itself (not the opponent). See `torille.envs.solo_envs.reward_stay_safe`.


## Uke environments `torille.envs.uke_envs.UkeToriEnv`

Tasks where only one character is controlled by agent, but observations for both characters are provided.

Player 2 is set to be immobile or random, depending on the task.

**States**: 1D vector of player 1 and player 2 body part positions, w.r.t player 1's groin. 
The `z` coordinate of player 1's groin is replaced with absolute `z` coordinate. (`gym.spaces.box.Box`)

**Actions**: Joint states for player 1 (`gym.spaces.multi_discrete.MultiDiscrete`)

Reward is specified by the task (see below).

Settings:

Setting | Value
------- | -----
matchframes | 1000
turnframes | 5

#### `Toribash-DestroyUke-v0`

Reward function: Positive reward for damaging immobile opponent. See `torille.envs.uke_envs.reward_destroy_uke`.

#### `Toribash-DestroyUke-v1`

Reward function: Positive reward for damaging immobile opponent and negative reward for receiving damage, summed together. 
                 See `torille.envs.uke_envs.reward_destroy_uke_with_penalty`.
                 
#### `Toribash-DestroyUke-v2`

Reward function: Positive reward for damaging opponent and negative reward for receiving damage, summed together. 
                 **Opponent takes random actions each turn**. See `torille.envs.uke_envs.reward_destroy_uke_with_penalty`.

                 
## Duo environments `torille.envs.duo_envs.DuoToriEnv`

Tasks where both characters are controlled by agent and observations are provided for both characters.

**States**: 1D vector of player 1 and player 2 body part positions, w.r.t player 1's **and** player 2's groin (i.e. 2x longer vector than in solo/uke environments).
The `z` coordinate of player's groins is replaced with the absolute `z` coordinate, so agents know their location w.r.t floor. (`gym.spaces.box.Box`)

**Actions**: Joint states for player 1 and player 2 (`gym.spaces.multi_discrete.MultiDiscrete`)

Reward is specified by the task (see below).

Settings:

Setting | Value
------- | -----
matchframes | 1000
turnframes | 5

#### `Toribash-DuoInjuryCombat-v0`

Reward function: Score from the point of view of player 1, in terms of injury: 
                 Positive reward if opponent received damage,
                 negative if player 1 received damage (summed together). 
                 See `torille.envs.duo_envs.reward_injury_player1_pov`.
                 
#### `Toribash-DuoWinCombat-v0`

Reward function: Score from the point of view of player 1, in terms of winning: 
                 +1 reward if player 1 won the game,
                 -1 reward if player 2 won the game and 
                 0 reward if game was tie.
                 See `torille.envs.duo_envs.reward_win_player1_pov`.

#### `Toribash-Cuddles-v0`

Reward function: Positive reward relative to inverse of distance between two players (distance of center-of-masses).
                 Negative reward if either of players takes damage. These are summed together for final reward.
                 See `torille.envs.duo_envs.reward_cuddles`.

Setting | Value
------- | -----
turnframes | 2

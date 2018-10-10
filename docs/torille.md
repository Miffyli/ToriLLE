# torille


## ToribashControl

Main class which controls Toribash process and handles communication.

#### `__init__(settings=None, draw_game=False, executable=ToribashConstants.TORIBASH_EXE, port=ToribashConstants.PORT)`
Creates a new Toribash controller, but does not launch Toribash instance. 
`ToribashControl` instance can be serialized (pickled) at this point.

Parameters:
* settings: `ToribashSettings` used to define initial settings of the game. 
* draw_game: Boolean specifying if game should be human-"enjoyable", i.e. run at convenient frame-rate and display characters
* executable: String which specifies path to the game executable (toribash.exe). By default this assumes Toribash binary is in 
  `toribash` directory next to `torille.py`, which is the case is installed via pip.
* port: Integer which specifies port where Toribash Lua attempts to connect to.

#### `init()`
Launches Toribash instance and begins to control it. Uses `FileLock` to prevent multiple parallel instances from
mixing Toribash instances with each other.

ToribashControl object is **not** serializable after calling this.

#### `close()`
Closes the connection with Toribash and kills the process. Can be called at any point after `init()`

#### `get_state()`
Returns current state of the game as a `ToribashState` object.

Throws exceptions if game has not been initialized, connection is broken or connection times out.

**Note: ** This function can't be called twice in row: It has to be followed by `make_actions()` or `reset()`

Returns:
* state: `ToribashState` of the current state of the game
* terminal: Boolean indicating if state was terminal 

#### `make_actions(actions)`
Sends given actions to Toribash and proceeds the game by set amount of frames (given in settings).

Throws exceptions if game has not been initialized, connection is broken/times out or actions are wrong.

**Note: ** This function can't be called twice in row: It has to be followed by `get_state()` or `reset()`

Parameters:
* actions: List of two lists with `ToribashConstants.NUM_CONTROLLABLES` elements.
  Each element is integer from range {1,2,3,4}. 
  These represent joint states for both Toribash characters. 
  **Note: ** Toribash character hands only take {0,1}, but for simplicity controller maps
             {1,2} => 0 and {3,4} => 4. 

#### `reset(settings=None)`
Resets the game to initial state, sets new settings (if given) and returns initial state. 

**Note: ** Must be followed by `get_state()` which returned `terminal=True`.

Parameters:
* settings: `ToribashSettings` used to define initial settings of the game. 

Returns
* state: `ToribashState` of the initial state of the game

#### `validate_actions(actions)`
Used to validate actions internally to avoid Toribash crashing without errors. 

Throws an exception if action is invalid.

Parameters:
* actions: List of two lists with `ToribashConstants.NUM_CONTROLLABLES` integers.

#### `get_state_dim()`
Returns number of variables in state per player

Returns:
* state_dim: Number of elements in state vector per player

#### `get_num_joints()`
Returns number of joints per player (number of controllables)

Returns:
* action_dim: Number of joints per player

#### `get_num_joint_states()`
Returns number of states a joint can be in 

Returns:
* action_categories: Number of states joint can be in

----

## ToribashState

Class used to refine and represent state
from Toribash. Returned by `ToribashControl.get_state()` and `ToribashControl.reset()`. 

#### `limb_positions`
A Numpy array of shape (2, `ToribashConstants.NUM_LIMBS`, 3) containing positions of 
body parts of both players.

#### `limb_velocities`
A Numpy array of shape (2, `ToribashConstants.NUM_LIMBS`, 3) containing velocities of 
body parts of both players.

#### `groin_rotations`
A Numpy array of shape (2, 4, 4) containing the rotation matrix of the groin (hip) 
of both players.

#### `joint_states`
A Numpy array of shape (2, `ToribashConstants.NUM_CONTROLLABLES`) containing current
states of the joints of both players

#### `injuries`
A Numpy array of shape (2,) containing current injury of both players (value seen
in game at the top-left and top-right.)

#### `winner`
A single integer or None, specifying the winner of the game.
Only defined at the end of the game (state which was received at terminal state).
0 = game was tie. 1 = player 1 won. 2 = player 2 won. None = Game didn't end.

---

## ToribashSettings

Class used to represent and contain rules for Toribash. These can be used
to modify the game's mechanics.

**Note: ** New settings can only be applied at `ToribashControl.reset(settings)`.

#### `DEFAULT_SETTINGS` (class-variable)
OrderedDict defining the default settings of Toribash game:

#### Possible settings

Name | Description | Type | Default
---- | ----------- | ---- | -------
matchframes | Length of an episode in frames | Integer | 500|
turnframes | Number of frames per turn (aka frame-skip) | Integer (interval [2,matchframes]) | 10| 
engagement_distance | Starting distance between characters | Integer | 100|
engagement_height | Starting height of characters | Integer  | 0|
engagement_rotation | Starting rotation (degrees, anti-clockwise) of characters | Integer | 0|
gravity_x | Strength of gravity in X axis | Float | 0.0|
gravity_y | Strength of gravity in Y axis | Float | 0.0|
gravity_z | Strength of gravity in Z axis | Float | -9.81|
damage | Is damaging enabled | {0,1} | 0 |
dismemberment_enable | Is dismemberment enabled | {0,1} | 1|
dismemberment_threshold | Force required to dismemberment to happen | Integer | 100|
fractures_enable | Enable fractures (disables joints) | {0,1} | 0|
fractures_threshold | Force required for fractures | Integer | 0|
disqualification_enabled | Enable disqualification (see link below for more info) | {0,1} | 0| 
disqualification_flags | Settings for disqualification (see link below for more info) | Integer | 0 |
disqualification_timeout | How long one can touch ground before disqualified | Integer | 0|
dojo_type | How battle arena works (see link below for more info) | Integer | 0|
dojo_size | How large the arena is | Integer | 0|
replay_file | If not equal to "None", Toribash will save replay of the played episode in `replay/[replay_file]` at end of the episode | String | "None"

See [this](http://forum.toribash.com/showthread.php?t=317900) Toribash topic for more info on settings.

#### `__init__(**kwargs)`
Creates new `ToribashSettings` object using `ToribashSettings.DEFAULT_SETTINGS` as a base
and overriding values based on `kwargs`.

Parameters:
* kwargs: Keyword arguments used to override default settings. See keys in `DEFAULT_SETTINGS`.
          E.g. `ToribashSettings(matchframes=1000)` creates new settings object where match length
               is set to 1000 frames, rather than default 500.

#### `get(key)`
Return the value of given setting name.

Parameters:
* key: String of the setting name.

Returns:
* value: Value of the setting given

#### `set(key,value)`
Set given setting to a given value.

Parameters:
* key: String of the setting name.
* value: Value of the setting

#### `validate_settings()`
Used internally to validate settings (correct type, no illegal characters (",") in strings).

Throws errors and warnings accordingly.

---

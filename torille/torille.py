#!/usr/bin/env python3
#
#  torille.py
#  Provides Python API to Toribash (i.e. can control the characters)
#
#  Author: Anssi "Miffyli" Kanervisto, 2018
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.
#
import socket
import numpy as np
import subprocess
import sys
import os
from collections import OrderedDict
import pprint
from filelock import FileLock
import warnings
from copy import deepcopy

from . import constants
from . import utils


class ToribashState:
    """
    Class for storing and processing the state representations
    from Toribash
    """

    def __init__(self, state, winner=None):
        # Limb locations
        # For both players, for all limbs, x,y,z coordinates
        self.limb_positions = np.zeros((2, constants.NUM_LIMBS, 3))
        # Limb velocities
        # For both players, for all limbs, x,y,z velocities
        self.limb_velocities = np.zeros((2, constants.NUM_LIMBS, 3))
        # Groin rotations of both players
        # Rotation is defined as 4x4 rotation matrix
        self.groin_rotations = np.zeros((2, 4, 4))
        # Joint states (including hands)
        # For both players
        self.joint_states = np.zeros((2, constants.NUM_CONTROLLABLES))
        # Amount of injury of players
        # For both players
        self.injuries = np.zeros((2,))
        # Winner of the game (only defined at end of the games)
        # 0 = tie, 1 = player 1 won, 2 = player 2 won
        self.winner = winner
        # Current selected/controlled player
        # Not used in local play, since both characters can be controlled,
        # but required in multiplayer to know which of the characters
        # is the one we control
        self.selected_player = None

        # Length of the game in number of frames
        self.match_length = None
        # Number of frames that have been played
        self.match_frame = None
        # Number of frames next turn will last
        # (E.g. aikido mod defines varying number of turnframes)
        self.frames_next_turn = None

        self.process_list(state)

    def process_list(self, state_list):
        """
        Updates state representations according to given list of
        variables from Toribash
        """
        # Indexes from  state_structure.md
        # Limbs
        self.limb_positions[0] = np.array(state_list[:63]).reshape(
            (constants.NUM_LIMBS, 3))
        self.limb_velocities[0] = np.array(state_list[63:126]).reshape(
            (constants.NUM_LIMBS, 3))
        self.groin_rotations[0] = np.array(state_list[126:142]).reshape(4, 4)

        self.limb_positions[1] = np.array(state_list[165:228]).reshape(
            (constants.NUM_LIMBS, 3))
        self.limb_velocities[1] = np.array(state_list[228:291]).reshape(
            (constants.NUM_LIMBS, 3))
        self.groin_rotations[1] = np.array(state_list[291:307]).reshape(4, 4)

        # Joint states (inc. hand grips)
        self.joint_states[0] = np.array(state_list[142:164], dtype=np.int)
        self.joint_states[1] = np.array(state_list[307:329], dtype=np.int)
        # Injuries
        self.injuries[0] = state_list[164]
        self.injuries[1] = state_list[329]
        # Selected player
        self.selected_player = int(state_list[330])
        # Frame info
        self.match_length = int(state_list[331])
        self.match_frame = int(state_list[332])
        self.frames_next_turn = int(state_list[333])

    def get_normalized_locations(self):
        """
        Normalizes and returns limb locations which are centered
        around respective player's groin, and applies groin's
        rotation to the locations.

        Applies following operations in order:
            - limb_locations - location of player's groin
            - Apply rotation player's groin to centered coordinates

        E.g. at the start of game both players will have same
             coordinates from their point of view.

        Returns:
            normalized_limb_positions: A (2, 2, NUM_LIMBS, 3) array
                                       of normalized locations, from the
                                       point-of-view of both players.
        """

        # Body-part 4 is "groin"
        # Center around the local-player's groin
        player1_obs = self.limb_positions - self.limb_positions[0, 4]
        player2_obs = self.limb_positions - self.limb_positions[1, 4]

        # Apply rotation of the groin, otherwise
        # player2 will have "mirrored" coordinates
        rotations = self.groin_rotations[:, :3, :3]
        player1_obs = np.dot(player1_obs.reshape(
            (-1, 3)), rotations[0]).reshape((2, constants.NUM_LIMBS, 3))
        player2_obs = np.dot(player2_obs.reshape(
            (-1, 3)), rotations[1]).reshape((2, constants.NUM_LIMBS, 3))

        return np.array((player1_obs, player2_obs))


class ToribashSettings:
    """ Class for storing and processing settings for Toribash """

    # Default settings
    DEFAULT_SETTINGS = OrderedDict([
        ("custom_settings", 1),
        ("matchframes", 500),
        ("turnframes", 10),
        ("engagement_distance", 100),
        ("engagement_height", 0),
        ("engagement_rotation", 0),
        ("gravity_x", 0.0),
        ("gravity_y", 0.0),
        ("gravity_z", -9.81),
        ("damage", 0),
        ("dismemberment_enable", 1),
        ("dismemberment_threshold", 100),
        ("fractures_enable", 0),
        ("fractures_threshold", 0),
        ("disqualification_enabled", 0),
        ("disqualification_flags", 0),
        ("disqualification_timeout", 0),
        ("dojo_type", 0),
        ("dojo_size", 0),
        ("replay_file", None),
        ("mod", "classic"),
        ("replayed_replay", None)
    ])

    def __init__(self, **kwargs):
        """
        Create new settings, kwargs can be used to define settings.
        Parameters:
            mod: The name of the mod to be loaded (default: "classic")
            **kwargs: Custom settings
        """
        self.settings = []
        # Get settings from function call, otherwise get them from
        # default settings
        for k, v in ToribashSettings.DEFAULT_SETTINGS.items():
            self.settings.append(kwargs.get(k, v))

    def validate_settings(self):
        """
        Checks that current given settings are valid for Toribash.
        Otherwise Toribash will go quiet, pout and then disappear :(
        """
        # 1-19 should be numbers
        for i, value in enumerate(self.settings[1:19]):
            if not type(value) in (float, int):
                raise ValueError((
                    "Setting {} was not of correct type: " +
                    "Expected float/int, got {}").format(
                        list(ToribashSettings.DEFAULT_SETTINGS.keys())[i],
                        type(value))
                )

        # 3rd value (turnframes) should be from interval [2,matchframes]
        if self.settings[2] < 1 or self.settings[2] > self.settings[1]:
            raise ValueError(
                "Setting 'turnframes' should be from interval " +
                "[1,matchframes].")

        # 20th value should be a string or None
        if self.settings[19] is not None:
            if type(self.settings[19]) != str:
                raise ValueError(
                    "Setting 'replay_file' should be str or None," +
                    " got %s" % type(self.settings[19])
                )

            # Remove commas from 20th value
            if "," in self.settings[19]:
                warnings.warn(
                    "Commas ',' are not supported in settings. " +
                    "Removing.")
                self.settings[19] = self.settings[19].replace(",", "")

        # 22th value (replayed_replay) should be a string or None
        if self.settings[21] is not None:
            if type(self.settings[21]) != str:
                raise ValueError(
                    "Setting 'replayed_replay' should be str or None," +
                    " got %s" % type(self.settings[21])
                )

            # Remove commas from 20th value
            if "," in self.settings[21]:
                warnings.warn(
                    "Commas ',' are not supported in settings. " +
                    "Removing.")
                self.settings[21] = self.settings[21].replace(",", "")

        # Mod should be a string
        if type(self.settings[20]) != str:
            raise ValueError("Setting `mod` should be a str")

        # custom_settings with non-default mod may cause
        # unwanted behaviour
        if self.settings[0] != 0 and self.settings[20] != "classic":
            warnings.warn("Using custom settings with non-classic mod " +
                          "may cause unwanted behaviour.")

    def set(self, key, value):
        """ Set given setting to value """
        self.settings[list(ToribashSettings.DEFAULT_SETTINGS.keys()
                           ).index(key)] = value

    def get(self, key):
        """ Get current value of the setting """
        return self.settings[list(ToribashSettings.DEFAULT_SETTINGS.keys()
                                  ).index(key)]

    def __str__(self):
        return pprint.pformat(
            dict([(k, v) for k, v in zip(
                ToribashSettings.DEFAULT_SETTINGS.keys(),
                self.settings)
            ]))


class ToribashControl:
    """ Main class controlling one instance of Toribash """

    def __init__(self,
                 settings=None,
                 draw_game=False,
                 executable=constants.TORIBASH_EXE,
                 port=constants.PORT):
        """
        Parameters:
            settings: ToribashSettings instance. Uses these settings if
                      provided, else defaults to default settings.
            draw_game: If True, will render the game and limit the FPS.
                       Defaults to False.
            executable: String of path to the toribash.exe launching the game.
                        Defaults to path used with pip-installed package.
            port: Port used to listen for connections from Toribash.
                  Defaults to constants.PORT.
                  NOTE: You have to change port in Toribash Lua script as well!
                        (in {toribash dir}/data/script/remotecontrol.lua )
        """
        self.executable_path = executable
        # Make sure exe exists
        if not os.path.isfile(self.executable_path):
            raise ValueError("Toribash executable path is not a file: %s" %
                             self.executable_path)
        # Create path to stderr.txt file which is created by the
        # Toribash executable (next to it)
        self.toribash_stderr_file = os.path.join(
            os.path.dirname(executable), "stderr.txt"
        )

        self.process = None
        self.connection = None
        self.port = port

        # Lets create FileLock file next to toribash.exe
        # Actual FileLock will be done in init() to keep
        # this object pickleable (serializable)
        self.lock_file = os.path.join(
            os.path.dirname(executable),
            ".launchlock"
        )

        self.draw_game = draw_game
        self.settings = settings
        if self.settings is None:
            self.settings = ToribashSettings()

        # Used as a watchdog to make sure
        # anybody calling using this interface
        # calls `reset` at appropiate times
        self.requires_reset = False
        # Same for get_state/make_actions loop.
        # If False, make_actions should be next call.
        # If True, get_state should be next call.
        self.requires_get_state = False

    def _check_if_initialized(self):
        if self.process is None:
            raise RuntimeError("Controlled not initialized with `init()`")

    def init(self):
        """
        Actual init: Launch the game process, wait for connection and
        and settings for the first game
        """
        # Use global filelock to avoid mixing up Toribash instances with
        # corresponding Python scripts if we have multiple Toribashes running.
        # Create lock here to make code pickle-able before call to init.
        init_lock = FileLock(self.lock_file,
                             timeout=constants.TIMEOUT)
        with init_lock:
            if sys.platform == "linux":
                # Sanity check launching on Linux
                utils.check_linux_sanity()
                # Attempt to make stderr.txt read-only
                # TODO this will cause headache when trying to remove torille
                _ = utils.set_file_readonly(self.toribash_stderr_file)
                # Add wine command explicitly for running on Linux
                self.process = subprocess.Popen((
                    "nohup", "wine", self.executable_path),
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL)
            elif sys.platform == "darwin":
                # Sanity check launching on OSX
                utils.check_darwin_sanity()
                # Attempt to make stderr.txt read-only
                _ = utils.set_file_readonly(self.toribash_stderr_file)
                # Add wine command for running on osx
                self.process = subprocess.Popen((
                    "wine %s" % self.executable_path),
                    stdout=subprocess.DEVNULL,
                    stderr=subprocess.DEVNULL,
                    shell=True)
            else:
                # Launch on Windows (just call the .exe)
                # Don't try to set stderr.txt to read-only: This will
                # cause Toribash to crash on Windows
                self.process = subprocess.Popen((self.executable_path,),
                                                stdout=subprocess.DEVNULL,
                                                stderr=subprocess.DEVNULL)
            # Create socket for waiting for Toribash to connect
            s = socket.socket()
            # This allows rebinding to same address multiple times on *nix
            # Otherwise you will get "address in use" if you launch multiple
            # Toribash instances on same computer
            # From Stackoverflow #6380057
            s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            s.bind(("", self.port))
            s.settimeout(constants.TIMEOUT)
            s.listen(1)
            conn, addr = s.accept()
            # Close the listener socket
            s.close()

            # Set the timeout for connection
            conn.settimeout(constants.TIMEOUT)

            self.connection = conn
        # Set get_state to be first call
        self.requires_get_state = True

        # Send handshake
        self._send_comma_list(self.connection, [int(self.draw_game)])
        self._send_settings()

    def close(self):
        """ Close the running Toribash instance and clean up """
        self._check_if_initialized()
        self.connection.close()
        # No need to be gentle here
        self.process.kill()

    def _recv_line(self, s):
        """
        Call recv till data ends with ToribashConstant.MESSAGE_END
        """
        # First wait till there is something to read
        ret = s.recv(constants.BUFFER_SIZE)
        # Now check if we had "\n", and continue reading till we have it
        while ret[-1:] != constants.MESSAGE_END:
            ret += s.recv(constants.BUFFER_SIZE)
        return ret

    def _recv_state(self):
        """
        Read state from Toribash
        Returns:
            State: List of floats representing the state of the game
            Terminal: Boolean indicating if this is the final state of game
        """
        s = self._recv_line(self.connection).decode()
        terminal = s.startswith("end")
        winner = None
        if terminal:
            # After 'end' comes ':#' where # specifies the winner
            # (one-digit integer)
            # Read the winner
            winner = int(s[4])
            # Remove first three characters + double-dots + integer + comma
            s = s[6:]
            # Allow calling reset next
            self.requires_reset = True
        s = list(map(float, s.split(",")))
        # Make sure we got list of correct length
        if len(s) != constants.STATE_LENGTH:
            raise ValueError((
                "Got state of invalid size. Expected %d, got %d" +
                "\nState: %s") %
                (constants.STATE_LENGTH, len(s), s))
        return s, terminal, winner

    def _send_comma_list(self, s, data):
        """
        Send given list to Toribash as comma-separated list
        Parameters:
            s: The socket where to send the data
            data: List of values to be sent
        """
        # We need to add end of line for the luasocket "*l"
        data = ",".join(map(str, data)) + "\n"
        s.sendall(data.encode())

    def _send_settings(self):
        """
        Send settings required upon new game
        """
        # Validate settings
        self.settings.validate_settings()
        self._send_comma_list(self.connection, self.settings.settings)

    def get_state(self):
        """
        Return state of the game (in prettier format)
        Returns:
            state: ToribashState representing the received state
            terminal: If the ToribashState is terminal state
        """
        self._check_if_initialized()

        if not self.requires_get_state:
            raise RuntimeError(
                "`get_state()` or `reset()` must be followed by `make_actions`"
            )
        self.requires_get_state = False

        s, terminal, winner = self._recv_state()
        s = ToribashState(s, winner)
        return s, terminal

    def reset(self):
        """
        Reset the game by sending settings for next round
        Returns:
            state: ToribashState representing the state of new game
        """
        self._check_if_initialized()

        # Make sure we are allowed to do a reset
        if not self.requires_reset:
            raise RuntimeError("Calling `reset()` is only allowed " +
                               "after terminal states")

        self._send_settings()

        self.requires_get_state = True

        s, terminal = self.get_state()
        self.requires_reset = False

        return s

    def validate_actions(self, actions):
        """
        Check the validity of given actions (correct shape, correct range,
        etc) and throw errors accordingly
        Parameters:
            actions: List of shape 2 x (NUM_JOINTS+2), specifying joint states
                     and hand gripping for both players.
        Returns:
            None. Raises an error if action is not valid
        """
        # Make sure we have lists
        if type(actions) != list and type(actions) != tuple:
            raise ValueError("Actions should be a List (e.g. not numpy array)")

        # Check we have actions for both players
        # Should probably check types of the elements too..
        if len(actions) != 2:
            raise ValueError("Actions should be a List of two lists")

        # Check that we have correct number of states
        if (len(actions[0]) != constants.NUM_CONTROLLABLES or
                len(actions[1]) != constants.NUM_CONTROLLABLES):
            raise ValueError(
                "Actions should be a List of shape 2 x %d" %
                constants.NUM_CONTROLLABLES
            )

        # Check that all joint states are in {1,2,3,4}
        for i in range(constants.NUM_CONTROLLABLES):
            # Check both players at the same time
            if (actions[0][i] > 4 or actions[0][i] < 1 or actions[1][i] > 4 or
                    actions[1][i] < 1):
                raise ValueError(
                    "Joint states should be in {1,2,3,4}. " +
                    "Note: Gym environments take in {0,1,2,3}"
                )

    def make_actions(self, actions):
        """
        Send given list of actions to Toribash.
        Parameters:
            actions: List of shape 2 x NUM_CONTROLLABLES,
                     specifying joint states
                     and hand gripping for both players.
        """
        self._check_if_initialized()

        # Make sure we are allowed to make actions
        if self.requires_reset:
            raise RuntimeError("`reset()` must be called after terminal state")
        if self.requires_get_state:
            raise RuntimeError(
                "`get_states()` must be called after reset or making actions"
            )
        self.requires_get_state = True

        # Validate actions, let it throw errors
        self.validate_actions(actions)

        # Create deepcopy of the actions list
        # because we are about to modify it
        actions = deepcopy(actions)

        # Modify hand grips to be {0,1} rather than {1,2,3,4}
        # Map {1,2} -> 0 , {3,4} -> 1
        actions[0][-2] = 0 if actions[0][-2] < 3 else 1
        actions[0][-1] = 0 if actions[0][-1] < 3 else 1
        actions[1][-2] = 0 if actions[1][-2] < 3 else 1
        actions[1][-1] = 0 if actions[1][-1] < 3 else 1

        # Concat lists into one
        actions = actions[0] + actions[1]

        self._send_comma_list(self.connection, actions)

    def finish_game(self):
        """
        Finish the current game by doing dummy steps
        until end of the game.
        """
        self._check_if_initialized()

        # Check that we are not already in the end
        if self.requires_reset:
            return

        dummy_action = [[3] * constants.NUM_CONTROLLABLES,
                        [3] * constants.NUM_CONTROLLABLES]

        terminal = False
        # Start with get_state if we need it
        if self.requires_get_state:
            _, terminal = self.get_state()

        while not terminal:
            self.make_actions(dummy_action)
            _, terminal = self.get_state()

    def read_replay(self, replay_file):
        """
        Go through given replay file in Toribash and get
        the contained states/actions. Note that this will
        reset current episode.

        Parameters:
            replay_file: String pointing at the replay file to be
                         played (NOTE: This should be inside
                         "replay" folder)
        Returns:
            states: List of ToribashStates, one per each frame
                    in the game
        """
        self._check_if_initialized()

        if not self.requires_reset:
            raise RuntimeError("Reading replays is only allowed " +
                               "between games (requires call to reset")

        # Check that replay file actually exists
        full_replay_path = os.path.join(
            os.path.dirname(self.executable_path), "replay", replay_file
        )

        if not os.path.isfile(full_replay_path):
            raise RuntimeError("Replay file %s does not exist" % replay_file)

        # Change settings
        self.settings.set("replayed_replay", replay_file)

        states = []

        # Begin playing episode
        # These dummy actions are not actually being executed,
        # but we send them to signal we received the state
        dummy_action = [[3] * constants.NUM_CONTROLLABLES,
                        [3] * constants.NUM_CONTROLLABLES]

        # Reset and go through the episode till terminal states
        states.append(self.reset())
        terminal = False
        while not terminal:
            self.make_actions(dummy_action)
            state, terminal = self.get_state()
            states.append(state)

        # Remove the replayed_replay setting
        self.settings.set("replayed_replay", None)

        # Return gathered states
        return states

    def get_state_dim(self):
        """ Return size of state space per character """
        return constants.NUM_LIMBS * 3

    def get_num_joints(self):
        """ Return number of controllable joints """
        return constants.NUM_CONTROLLABLES

    def get_num_joint_states(self):
        """ Return number of states each joint can have """
        return constants.NUM_JOINT_STATES

    def __del__(self):
        """
        Destructor to close running Toribash process.
        There is no point in keeping Toribash alive without the controller...
        """
        if self.process is not None:
            self.close()

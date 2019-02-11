#!/usr/bin/env python3
#
#  manual_torille.py
#  Similar to torille.py (Python API to play Toribash), but for stripped down,
#  manual control: Human must launch the corresponding script in Toribash and
#  end turns manually, this part only receives states and sends actions.
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
from copy import deepcopy

from . import constants
from .torille import ToribashControl, ToribashState


class ManualToribashControl(ToribashControl):
    """
    Main class for playing Toribash manually.

    "Manually", meaning we launch the control script
    manually in a Toribash game, it connects
    to this class and this class then controls main player.
    After game ends this class will kill the connection.
    """

    def __init__(self, port=constants.PORT):
        """
        Parameters:
            port: Port to be listened for incoming connection
                  from Toribash (default: constants.py)
        """
        self.port = port
        self.connection = None

    def _check_if_initialized(self):
        if self.connection is None:
            raise Exception("Not connected to Toribash instance")

    def init(self):
        """
        Override original init from ToribashControl, not
        needed here
        """
        raise NotImplementedError("Not used with manual control. " +
                                  "Use `connect_to_toribash()` instead")

    def connect_to_toribash(self, timeout=constants.TIMEOUT):
        """
        Actual init: Listen for incoming connection from
        Toribash we start to control

        Parameters:
            timout: Seconds to wait for Toribash before throwing
                    an exception. Default: constants.TIMEOUT
        """

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

    def close(self):
        """
        Close connection to the controlled Toribash instance
        """
        if self.connection is not None:
            self.connection.close()
            self.connection = None

    def get_state(self):
        """
        Return state of the game (in prettier format)
        Returns:
            state: ToribashState representing the received state
            terminal: If the ToribashState is terminal state
        """
        self._check_if_initialized()

        s, terminal, winner = self._recv_state()
        s = ToribashState(s, winner)

        # If game ended to this state, close connection
        if terminal:
            self.close()

        return s, terminal

    def validate_actions(self, actions):
        """
        Check the validity of given actions (correct shape, correct range,
        etc) and throw errors accordingly
        Parameters:
            actions: List of length NUM_JOINTS+2, specifying joint states
                     and hand gripping for player 0.
        Returns:
            None. Raises an error if action is not valid
        """
        # Make sure we have list
        if type(actions) != list and type(actions) != tuple:
            raise ValueError("Actions should be a List (e.g. not numpy array)")

        # Check that we have correct number of states
        if len(actions) != constants.NUM_CONTROLLABLES:
            raise ValueError("Actions should be a List of length %d" %
                             constants.NUM_CONTROLLABLES)

        # Check that all joint states are in {1,2,3,4}
        for i in range(constants.NUM_CONTROLLABLES):
            # Check both players at the same time
            if (actions[i] > 4 or actions[i] < 1):
                raise ValueError(
                    "Joint states should be in {1,2,3,4}. " +
                    "Note: Gym environments take in {0,1,2,3}")

    def make_actions(self, actions):
        """
        Send given actions to Toribash for player 0 (not Uke)
        Parameters:
            actions: List of NUM_CONTROLLABLES, specifying joint states
                     and hand gripping for player 0.
        """
        self._check_if_initialized()

        # Validate actions, let it throw errors
        self.validate_actions(actions)

        # Create deepcopy of the actions list
        # because we are about to modify it
        actions = deepcopy(actions)

        # Modify hand grips to be {0,1} rather than {1,2,3,4}
        # Map {1,2} -> 0 , {3,4} -> 1
        actions[-2] = 0 if actions[-2] < 3 else 1
        actions[-1] = 0 if actions[-1] < 3 else 1

        self._send_comma_list(self.connection, actions)

    def reset(self):
        raise Exception("Manual Toribash control can not be reset")

    def __del__(self):
        """
        Override destructor for ToribashControl (we do not have
        process to control)
        """
        if self.connection is not None:
            self.close()

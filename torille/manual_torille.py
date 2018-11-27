#!/usr/bin/env python3
#
#  torille_multiplayer.py
#  Similar to torille.py (Python API to play Toribash), but specifically
#  for multiplayer games which require additional care.
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
from . import constants
from . import utils
from .torille import (ToribashControl, ToribashState, 
                      ToribashSettings)

class ManualToribashControl(ToribashControl):
    """ 
    Main class for playing Toribash manually.

    "Manually", meaning we launch the control script
    manually in a legit Toribash game, it connects
    to this class and this class then controls main player.
    Not to be used for training.
    """
    def __init__(self, port):
        """ 
        Parameters:
            port: Port to be listened for incoming connection
                  from Toribash
        """
        self.port = port
        self.connection = None

    def _check_if_initialized(self):
        if self.connection is None:
            raise Exception("Not connected to Toribash instance")

    def init(self):
        """
        Actual init: Listen for incoming connection from 
        Toribash we start to control
        """

        # Create socket for waiting for Toribash to connect
        s = socket.socket()

        # This allows rebinding to same address multiple times on *nix
        # Otherwise you will get "address in use" if you launch multiple
        # Toribash instances on same computer
        # From Stackoverflow #6380057
        s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

        s.bind(("",self.port))
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
        self._check_if_initialized()
        self.connection.close()

    def make_actions(actions):
        super().make_actions(actions)

        # TODO how does this work? We probably only send 
        #      actions for one player. Take in actions 
        #      for only one player 

    def reset(self):
        raise Exception("Manual Toribash control can not be reset")
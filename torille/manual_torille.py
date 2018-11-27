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
    Main class for playing Toribash manually
    """
    def __init__(self, port):
        """ 
        Parameters:
            port: Port to be listened for incoming connection
                  from Toribash
        """
        self.port = port

        super().__init__(**kwargs)

    def init(self):
        super().init()

        # Login to the network
        # TODO game complains that \login is only available
        #      in multiplayer mode. Do we have to login through
        #      tb_login.dat file? (it just is plain-text file...)
        # TODO make sure "not-rendering" works (unlocked fps).
        #      We could also consider using 
        # TODO how to make sure we have logged in / room is valid /
        #      we had permission to play
        # TODO how do we know when it is our turn to play (the queue,
        #      system in Toribash)

    def make_actions(actions):
        super().make_actions(actions)

        # TODO how does this work? We probably only send 
        #      actions for one player. Take in actions 
        #      for only one player 

    def reset(self):
        super().reset()

        # TODO not available AFAIK, not even to op of the room.
        #      Have reset instead to wait till next round starts?
        #      Needs some work on the Lua side
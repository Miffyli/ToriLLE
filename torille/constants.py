#!/usr/bin/env python3
#
#  constants.py
#  File holding all constants for Torille
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
import os

# Port where Toribashes connect to
PORT = 7788
# Global timeout (in seconds) for connections
TIMEOUT = 300
# Buffer size (for recv)
BUFFER_SIZE = 8096
# Line ending character
MESSAGE_END = "\n".encode()

# "Limb" or "Bodypart"
NUM_LIMBS = 21
NUM_JOINTS = 20
# Add hand_grips
NUM_CONTROLLABLES = NUM_JOINTS + 2
NUM_JOINT_STATES = 4
# Number of setting variables
NUM_SETTINGS = 19

# Bodypart x,y,z + Bodypart x,y,z velocities +
# groin rotation + Joint states + hand grips + injuries + selected player
# + frame info (x3)
STATE_LENGTH = (
    (NUM_LIMBS * 3 * 2) * 2 +
    16 * 2 +
    NUM_JOINTS * 2 +
    4 + 2 + 1 + 3
)

# Path to Toribash supplied with the wheel package
# This should be {this file}/toribash/toribash.exe
my_dir = os.path.dirname(os.path.realpath(__file__))
TORIBASH_EXE = os.path.join(my_dir, "toribash", "toribash.exe")

# Path to Toribash's stderr.txt file, which
# will be filled with bunch of errors unless handled separately
TORIBASH_STDERR_FILE = os.path.join(my_dir, "toribash", "stderr.txt")

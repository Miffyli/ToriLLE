#!/usr/bin/env python3
#
#  utils.py
#  Misc. utility functions for Torille
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
import subprocess
import random as r
from stat import S_IREAD, S_IRGRP, S_IROTH
import warnings

from . import constants


def create_random_actions():
    """ Return random actions for ToribashControl """
    ret = [[], []]
    for plridx in range(2):
        for jointidx in range(constants.NUM_CONTROLLABLES):
            ret[plridx].append(r.randint(1, 4))
    return ret


def set_file_readonly(filepath):
    """
    Attempt to set given file read-only, and
    return True on success.

    Parameters:
        filepath: Path to file to be set read-only
    Returns:
        success: True if file was set read only, otherwise False
    """
    if os.path.isfile(filepath):
        # Set to read only (for user, group and all)
        try:
            os.chmod(filepath, S_IREAD | S_IRGRP | S_IROTH)
        except PermissionError:
            return False
        return True
    else:
        return False


def check_darwin_sanity():
    """
    A helper function that checks OSX/Mac/Darwin environment
    for requirements, and warns/throws accordingly
    """

    # Check Wine version: We need recent enough version, otherwise
    # game won't run
    wine_version = None
    try:
        wine_version = subprocess.check_output(
            ("wine", "--version")).decode()[:-1]
    except FileNotFoundError:
        raise Exception(
            "Recent version of Wine is required to run Toribash. " +
            "Tested to work on Wine version 3.0.3.\n\n" +
            "NOTE: On OSX Wine may not be added to PATH during installation." +
            " Add Wine binaries to the PATH manually. " +
            "One location for Wine binaries is " +
            "'/Applications/Wine Stable.app/Contents/Resources/wine/bin/'")
    if wine_version is not None:
        if wine_version[0] == 1:
            raise Exception(
                "Detected Wine version 1.x. " +
                "Toribash does not run on old versions of Wine. " +
                "Toribash is tested to work on Wine versions 3.0.3"
            )


def check_linux_sanity():
    """
    A helper function that checks Linux environment
    for requirements, and warns/throws accordingly
    """

    # Check that we have a valid display to render into.
    # We rather avoid running over SSH
    display = os.getenv("DISPLAY")
    if display is None:
        raise Exception(
            "No display detected. " +
            "Toribash won't launch without active display. " +
            "If you have a monitor attached, set environment variable " +
            "DISPLAY to point at it (e.g. `export DISPLAY=:0`)")
    if display[0] != ":":
        warnings.warn(
            "Looks like you have X-forwarding enabled. " +
            "This makes Toribash very slow and sad. " +
            "Consider using virtual screen buffer like Xvfb. " +
            "More info at the Github page https://github.com/Miffyli/ToriLLE"
        )

    # Check Wine version: We need recent enough version, otherwise
    # game won't run
    wine_version = None
    try:
        wine_version = subprocess.check_output(
            ("wine", "--version")).decode()[:-1]
    except FileNotFoundError:
        raise Exception(
            "Recent version of Wine is required to run Toribash. " +
            "Tested to work on Wine version 3.0.3")
    if wine_version is not None:
        if wine_version[0] == 1:
            raise Exception(
                "Detected Wine version 1.x. " +
                "Toribash does not run on old versions of Wine. " +
                "Toribash is tested to work on Wine versions 3.0.3"
            )

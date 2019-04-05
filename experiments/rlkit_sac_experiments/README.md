# rlkit SAC experiemnts

Code for running [rlkit](https://github.com/vitchyr/rlkit)'s (modified) SAC on Torille environments 

This code includes compressed copy of the `rlkit` directory in the rlkit repository, with modifications required
to make it run on ToriLLE. You must extract `rlkit_for_torille.zip` in this directory for code to work. You 
can see the modifications to `rlkit` code in the git log.

See `run_destroyukes.bash` for examples how to run the code. 

## Contents

* `rlkit_for_torille.zip`: Archived version of modified rlkit (forked 13-1-2019). Use this version of rlkit to run the accompanied code.
* `sac_torille_destroyuke.py`: Python code for running rlkit SAC on ToriLLE environments 
* `run_destroyukes.bash`: Starts five separate runs of training SAC on ToriLLE envs. See commands here for examples how to run.

#!/bin/bash

# Use: launch_ppo_turnframes.bash turnframes 

for i in `seq 1 5`; do
    screen -dm -S ${1}_${i} python3 ppo_turnframes.py ppo_config_${1}_turnframes.json ${1} 50 results/log_${1}_${i}.txt
done

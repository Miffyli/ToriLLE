# ppo_turnframes

Code for experiments used to study how PPO will learn under different settings of `turnframes` (or frame-skip)

## Contents

* `ppo_turnframes.py`: Main code
* `launch_ppo_turnframes.bash`: Bash script used to launch the experiments
* `*.json`: Tensorforce network and agent specifications. One per different setting of `turnframes` so that each agent will 
  have update batches of size 5000.

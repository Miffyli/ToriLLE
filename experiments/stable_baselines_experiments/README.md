# stable_baselines experiments

Experiment code for running PPO and TRPO experiments on ToriLLE Gym environments with [stable-baselines](https://github.com/hill-a/stable-baselines).

Requires `stable-baselines` installed and available with `import stable_baselines`. 

**Note: Self-play is not the original one used in the publication due to changes in `stable-baselines`, but hyperparameters are the same**

## Contents

* `run_stable_baselines.py`: Code for training PPO/TRPO agents from stable_baselines on ToriLLE DestroyUke task (single-player)
* `sbaselines_selfplay.py`: Code for training PPO with self-play to play in competitive mode.
* `competitive_env.py`: Environment designed for self-play training (used by code above).
* `run_destroyukes_ppo.bash`: Starts five separate runs of training PPO on DestroyUke-v1 environment (with custom settings)
* `run_destroyukes_ppo.bash`: Starts five separate runs of training TRPO on DestroyUke-v1 environment (with custom settings)

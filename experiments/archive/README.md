# Experiments

This directory holds codes used for experiments and benchmarks in **version 1 and 2** of white paper [https://arxiv.org/abs/1807.10110](https://arxiv.org/abs/1807.10110)

## `ppo_turnframes/`

Code used to study effect of different number of frames between turns (with Tensorforce PPO agents)

## `a2c/`

Implementation of A2C and training code used to do A2C experiments in the white paper version 1. 

See `python3 a2c_training.py -h` for arguments.

Experiments in the white paper were ran with following commands (repeated five times):

```
python3 a2c_training.py --timesteps 2000000 destroy-uke models/destroyuke1
python3 a2c_training.py --timesteps 2000000 run-away models/runaway1
python3 a2c_training.py --timesteps 2000000 self-destruct models/selfdestruct1
```

## `baselines_torille.tar.gz`

Compressed package of [OpenAI baselines](https://github.com/openai/baselines/) code used to run PPO experiments in the paper (see `baselines/baselines/ppo1` in the archive). See git log of the archive for the modifications made. 

Experiments in the white paper were ran with following commands in `baselines/baselines/ppo1` directory (repeated five times with different seeds):
```
python3 run_toribash.py --env Toribash-DestroyUke-v0 --num-timesteps 2000000 --seed 0
python3 run_toribash.py --env Toribash-RunAway-v0 --num-timesteps 2000000 --seed 0
python3 run_toribash.py --env Toribash-SelfDestruct-v0 --num-timesteps 2000000 --seed 0
```


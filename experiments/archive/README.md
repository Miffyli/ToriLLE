# Experiments

This directory holds codes used for experiments and benchmarks in **version 1** of white paper [https://arxiv.org/abs/1807.10110](https://arxiv.org/abs/1807.10110)

## `async_benchmark.py`

Used to benchmark Toribash's performance with one or several asynchronous instances.

Run with `python3 async_benchmark.py num_instances match_frames turn_frames`.

## `a2c/`

Implementation of A2C and training code used to do A2C experiments in the white paper. 

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


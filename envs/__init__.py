from gym.envs.registration import register
from .gym_env import TestToriEnv

register(
    id='torille/test-Toribash-v0',
    entry_point='envs:TestToriEnv',
    kwargs={
        'toribash_exe': r"D:\Games\Toribash-5.22\toribash.exe",
        'matchframes': 1000,
        'turnframes': 1,
    },
)
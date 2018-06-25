from gym.envs.registration import register
from .gym_env import TestToriEnv
from .solo_envs import (SoloToriEnv, reward_run_away, 
                        reward_self_destruct, reward_stay_safe,
                        reward_destroy_uke)

# Self-destruct env: Try to inflict as much damage to yourself
#                    as possible (plus reward on damage)
register(
    id='Toribash-SelfDestruct-v0',
    entry_point='torille.envs:SoloToriEnv',
    kwargs={
        'reward_func': reward_self_destruct,
        'matchframes': 1000,
        'turnframes': 5,
        # Avoid contact with the other player (who just idles)
        'engagement_distance': 1500
    },
)

# Stay-safe env: Anti-self-destruct, i.e. try to minimize damage
#                to yourself (minus reward on damage)
register(
    id='Toribash-StaySafe-v0',
    entry_point='torille.envs:SoloToriEnv',
    kwargs={
        'reward_func': reward_stay_safe,
        'matchframes': 1000,
        'turnframes': 5,
        # Avoid contact with the other player (who just idles)
        'engagement_distance': 1500
    },
)

# Run-away env: Attempt to go as far from center as possible
#               (plus reward on moving further away center).
#               Center is located between two players.
register(
    id='Toribash-RunAway-v0',
    entry_point='torille.envs:SoloToriEnv',
    kwargs={
        'reward_func': reward_run_away,
        'matchframes': 1000,
        'turnframes': 5,
        # Avoid contact with the other player (who just idles)
        'engagement_distance': 1500
    },
)

# Destroy-uke env: Attack an immobile Uke, try to inflict as much 
#                  damage as possible to it. Damage = Reward
register(
    id='Toribash-DestroyUke-v0',
    entry_point='torille.envs:SoloToriEnv',
    kwargs={
        'reward_func': reward_destroy_uke,
        'matchframes': 1000,
        'turnframes': 5,
    },
)

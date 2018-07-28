from gym.envs.registration import register
from .solo_envs import (SoloToriEnv, reward_run_away, 
                        reward_self_destruct, reward_stay_safe)
from .uke_envs import (UkeToriEnv, reward_destroy_uke_with_penalty, 
                        reward_destroy_uke)
from .duo_envs import (DuoToriEnv, reward_player1_pov, 
                        reward_cuddles)

# ---------------------------------------------------------------
# Solo envs -----------------------------------------------------
# ---------------------------------------------------------------

# SelfDestruct-v0 env: Try to inflict as much damage to yourself
#                      as possible (plus reward on damage)
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

# StaySafe-v0 env: Anti-self-destruct, i.e. try to minimize damage
#                  to yourself (minus reward on damage)
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

# RunAway-v0 env: Attempt to go as far from center as possible
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

# ---------------------------------------------------------------
# Uke envs ------------------------------------------------------
# ---------------------------------------------------------------

# DestroyUke-v0: Attack an immobile Uke, try to inflict as much 
#                damage as possible to it. Damage = Reward.
register(
    id='Toribash-DestroyUke-v0',
    entry_point='torille.envs:UkeToriEnv',
    kwargs={
        'reward_func': reward_destroy_uke,
        'matchframes': 1000,
        'turnframes': 5,
        'random_uke': False,
    },
)

# DestroyUke-v1: Attack an immobile Uke, try to inflict as much 
#                damage as possible to it. Damage = Reward.
#                Reward penalty if player takes damage.
register(
    id='Toribash-DestroyUke-v1',
    entry_point='torille.envs:UkeToriEnv',
    kwargs={
        'reward_func': reward_destroy_uke_with_penalty,
        'matchframes': 1000,
        'turnframes': 5,
        'random_uke': False,
    },
)

# DestroyUke-v2: Attack a _random_ Uke, try to inflict as much 
#                damage as possible to it. Damage = Reward.
#                Reward penalty if player takes damage.
register(
    id='Toribash-DestroyUke-v2',
    entry_point='torille.envs:UkeToriEnv',
    kwargs={
        'reward_func': reward_destroy_uke_with_penalty,
        'matchframes': 1000,
        'turnframes': 5,
        'random_uke': True,
    },
)

# ---------------------------------------------------------------
# Duo envs ------------------------------------------------------
# ---------------------------------------------------------------

# DuoCombat-v0: Control both players. Receive reward from the
#               point of view of player 1: 
#                   + reward for player 2 receiving damage
#                   - reward for player 1 receiving damage
register(
    id='Toribash-DuoCombat-v0',
    entry_point='torille.envs:DuoToriEnv',
    kwargs={
        'reward_func': reward_player1_pov,
        'matchframes': 1000,
        'turnframes': 5,
    },
)

# Cuddles-v0: Control both players. Receive reward if players'
#             center of masses are close enough, and
#             receive penalty if either of players is
#             damaged.
register(
    id='Toribash-Cuddles-v0',
    entry_point='torille.envs:DuoToriEnv',
    kwargs={
        'reward_func': reward_cuddles,
        'matchframes': 1000,
        # Lower frame-skip for smoother action.
        # Otherwise could get bit too rough
        'turnframes': 2,
    },
)
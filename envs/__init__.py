from gym.envs.registration import register


# Env registration
# ==========================

register(
    id='{}/meta-Doom-v0'.format(USERNAME),
    entry_point='{}_gym_doom:MetaDoomEnv'.format(USERNAME),
    max_episode_steps=999999,
    reward_threshold=9000.0,
    kwargs={
        'average_over': 3,
        'passing_grade': 600,
        'min_tries_for_avg': 3
    },
)
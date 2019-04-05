import numpy as np
import gym
import rlkit.torch.pytorch_util as ptu
from rlkit.envs.wrappers import NormalizedBoxEnv, OneHotsToDecimalsAndRecordAndRandomize
from rlkit.launchers.launcher_util import setup_logger
from rlkit.torch.sac.policies import TanhGaussianPolicy, CategoricalPolicy, MultiCategoricalPolicy
from rlkit.torch.sac.sac import SoftActorCritic
from rlkit.torch.networks import FlattenMlp

import torille.envs

from torch.nn import functional as F

from argparse import ArgumentParser

parser = ArgumentParser("Run SAC on toribash envs")
parser.add_argument("env")
parser.add_argument("target_entropy", type=float)
parser.add_argument("reward_scale", type=float)
parser.add_argument("experiment_index", type=int)
parser.add_argument("--fixed_alpha", type=float)

def experiment(variant, env_name, record_name, record_every_episode):
    #env = CartPoleEnv()
    env =  gym.make(env_name)
    # A workaround to give this info later on 
    # (Such naughty business...)
    randomize_settings = {"turnframes": [10,10], "engagement_distance": [100,200]}
    env.record_name = record_name
    env.record_every_episode = record_every_episode
    env.randomize_settings = randomize_settings
    env = OneHotsToDecimalsAndRecordAndRandomize(env) 

    obs_dim = int(np.prod(env.observation_space.shape))
    num_categoricals = len(env.action_space.nvec)
    num_categories = env.action_space.nvec[0]

    net_size = variant['net_size']
    qf = FlattenMlp(
        hidden_sizes=[net_size, net_size],
        # Action is fed in as a raveled one-hot vector
        input_size=obs_dim + int(np.sum(env.action_space.nvec)),
        output_size=1,
        hidden_activation=F.sigmoid,
    )
    vf = FlattenMlp(
        hidden_sizes=[net_size, net_size],
        input_size=obs_dim,
        output_size=1,
        hidden_activation=F.sigmoid,
    )


    # For multi-discrete
    policy = MultiCategoricalPolicy(
        hidden_sizes=[net_size, net_size],
        obs_dim=obs_dim,
        num_categoricals=num_categoricals,
        num_categories=num_categories,
        hidden_activation=F.sigmoid
    )

    algorithm = SoftActorCritic(
        env=env,
        policy=policy,
        qf=qf,
        vf=vf,
        **variant['algo_params']
    )
    algorithm.to(ptu.device)
    algorithm.train()


if __name__ == "__main__":
    # noinspection PyTypeChecker
    args = parser.parse_args()
    env_name = args.env
    target_entropy = args.target_entropy
    reward_scale = args.reward_scale
    experiment_index = args.experiment_index
    use_automatic_entropy_tuning = True
    experiment_name = "%s-rand-targetentropy_%f_rs_%f_turnframes_10_run%d" % (env_name, target_entropy, reward_scale, experiment_index)
    # Check if we want to use fixed alpha instead
    fixed_alpha = 1.0
    if args.fixed_alpha is not None: 
        use_automatic_entropy_tuning = False
        fixed_alpha = args.fixed_alpha
        experiment_name = "%s-rand-fixed_alpha_%f_rs_%f_turnframes_10_run%d" % (env_name, fixed_alpha, reward_scale, experiment_index)
    
    variant = dict(
        algo_params=dict(
            num_epochs=3000,
            num_steps_per_epoch=1000,
            num_steps_per_eval=250,
            batch_size=128,
            max_path_length=999,
            discount=0.99,
            reward_scale=reward_scale,

            soft_target_tau=0.001,
            policy_lr=3E-4,
            qf_lr=3E-4,
            vf_lr=3E-4,
            train_policy_with_reparameterization=False,
            save_environment=False,
            target_entropy=target_entropy,
            
            use_automatic_entropy_tuning = use_automatic_entropy_tuning,
            fixed_alpha = fixed_alpha
            
        ),
        net_size=64,
    )

    setup_logger(experiment_name, variant=variant)
    ptu.set_gpu_mode(True)  # optionally set the GPU (default=False)
    experiment(variant, env_name=env_name, record_name = experiment_name, record_every_episode = 100)

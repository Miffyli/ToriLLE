#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np
from agents.a2c import ToribashA2C
from torille import ToribashControl
from math import log10, log2
from time import time
import argparse
from collections import deque

parser = argparse.ArgumentParser(description="Train A2C on Toribash")
parser.add_argument('executable', type=str,
                help="Executable file for Toribash")
parser.add_argument('rewardfunc', type=str,
                help="Reward function to be used for training")
parser.add_argument('modelfile', type=str,
                help="Location where model should be stored")
parser.add_argument('--batchsize', type=int, default=32,
                help="Size of a single batch for training (default: 32)")
parser.add_argument('--timesteps', type=int, default=1000000,
                help="Number of timesteps to run (default: 1e6)")
parser.add_argument('--reportrate', type=int, default=100,
                help="How many trains ops between printing stats (default: 100)"
                )
parser.add_argument('--numframes', type=int, default=3,
                help="How many successive frames will be fed to network (default: 3)"
                )
parser.add_argument('--saverate', type=int, default=1000,
                help="How often model should be saved (default: 1000)")
parser.add_argument('--logfile', type=str, default='log.txt',
                help="Logfile where to store data (default: 'log.txt')")

def reward_self_destruct(old_state, new_state):
    """ Returns reward for plr0 receiving damage """
    reward = new_state.plr0_injury - old_state.plr0_injury
    if reward > 1:
        reward = log10(reward) / 4
    return reward
    
def reward_stay_safe(old_state, new_state):
    """ Returns reward for plr0 NOT receiving damage """
    # Injury can only increase
    reward = -(old_state.plr0_injury - new_state.plr0_injury)
    if reward > 1:
        reward = log10(reward) / 4
    return -reward
    
def reward_run_away(old_state, new_state):
    """ Returns reward for plr0 for running away from center of the arena.
    Center of arena is conveniently between players """
    # Use head as a position metric (hip would probably be better, oh well)
    old_pos = old_state.limb_positions[0,0]
    new_pos = new_state.limb_positions[0,0]
    # Amount moved away from center
    # (we want further away to be positive)
    moved = np.sqrt(np.sum(new_pos**2)) - np.sqrt(np.sum(old_pos**2))
    return moved

def reward_destroy_uke(old_state, new_state):
    """ Returns reward on damaging the other player (Uke)"""
    reward = new_state.plr1_injury - old_state.plr1_injury
    if reward > 1:
        reward = log10(reward) / 4
    return reward

REWARD_FUNCS = {
    "self-destruct": reward_self_destruct,
    "stay-safe": reward_stay_safe,
    "run-away": reward_run_away,
    "destroy-uke": reward_destroy_uke,
}

def get_player_states(state):
    """ Get 1D state-arrays for both players """
    p1 = state.limb_positions[0].ravel()
    p2 = state.limb_positions[1].ravel()
    return p1, p2

def get_plr1_refined_state(state):
    """ Return more refined state for player1 (normalized, clipped) """
    s = get_player_states(state)[0] / 10.0
    s = np.clip(s, -3.0, 3.0)
    return s

def print_and_log(s,logfile):
    """ Print and save same message. I imagine there are some proper libraries
    for this..."""
    print(s)
    with open(logfile, "a") as f:
        f.write(s+"\n")

def simple_training(executable, batch_size, num_steps, 
                        report_every_trains, reward_function,
                        logfile, save_every_trains, save_file,
                        num_frames):
    """ An example training code on Toribash
        Player 0 is controlled, player 1 just relaxes to the ground"""

    controller = ToribashControl(executable)
    
    controller.settings.set("matchframes", 1000)
    controller.settings.set("turnframes", 5)
    controller.settings.set("engagement_distance", 1000)
    if reward_function == reward_destroy_uke:
        controller.settings.set("engagement_distance", 100)
    
    num_joints = controller.get_num_joints()
    num_joint_states = controller.get_num_joint_states()
    num_inputs = controller.get_state_dim()
    
    a2c = ToribashA2C(num_inputs*num_frames,
                      num_joints, num_joint_states, 
                      )   
    
    train_op_ctr = 0
    step_ctr = 0
    batch_states = []
    batch_stateprimes = []
    batch_actions = []
    batch_rewards = []
    
    last_s = None
    last_a = None
    last_r = None
    injury = None
    last_orig_s = None
    pi_losses = []
    v_losses = []
    h_losses = []
    vs = []
    rewards = []
    stacker = deque([np.zeros(num_inputs,) for i in range(num_frames)], 
                    maxlen=num_frames)
    
    controller.init()
    
    print_and_log("--- Training starts ---", logfile)
    start_time = time()
    
    while step_ctr < num_steps:
        orig_s,terminal = controller.get_state()
        # We are only concerned about player 1
        s = get_plr1_refined_state(orig_s)
        # Create "correct" state right away
        stacker.append(s)
        s = np.concatenate(stacker)
        
        # Add to batch if we had them
        if last_s is not None and last_a is not None and last_r is not None: 
            batch_states.append(last_s)
            batch_stateprimes.append(s)
            batch_actions.append(last_a)
            batch_rewards.append(last_r)
            if len(batch_states) == batch_size:
                # Bit of normalizing
                states = np.array(batch_states)
                stateprimes = np.array(batch_stateprimes)
                # We need to substract by one for training...
                actions = np.array(batch_actions)
                actions[:,:-2] -= 1
                returns = np.array(batch_rewards)
                losses = a2c.train_on_batch(states, stateprimes, actions, 
                                            returns)
                pi_losses.append(losses[0])
                v_losses.append(losses[1])
                h_losses.append(losses[2])
                train_op_ctr += 1
                batch_states.clear()
                batch_stateprimes.clear()
                batch_actions.clear()
                batch_rewards.clear()
        step_ctr += 1
        # TODO ToribashA2C does not support terminal states yet
        # Lets just skip terminal state for now (can be really bad idea)
        if terminal: 
            last_s = None
            last_a = None
            last_r = None
            last_orig_s = None
            # Reset stacker by putting zeros in
            stacker = deque([np.zeros(num_inputs,) for i in range(num_frames)], 
                             maxlen=num_frames)
            orig_s = controller.reset()
            s = get_plr1_refined_state(orig_s)
            stacker.append(s)
            s = np.concatenate(stacker)
        
        pi, v = a2c.predict_pi_and_v(np.expand_dims(s,0))
        pi = pi[0]
        v = v[0]
        vs.append(v)
        
        a = []
        for probs in pi[:-2]:
            a.append(np.random.choice(num_joint_states, p=probs)+1)
        # Hand joints require some extra care
        a.append(min(1,np.random.choice(num_joint_states, p=pi[-2])))
        a.append(min(1,np.random.choice(num_joint_states, p=pi[-1])))
        
        # Add in player1's actions (needed. Set all to "hold", excepts hands)
        action = [a, [3 for i in range(num_joints-2)]+[0,0]]
        
        controller.make_actions(action)
        
        last_s = s
        last_a = action[0]

        if last_orig_s is not None:
            last_r = reward_function(last_orig_s, orig_s)
        else:
            last_r = 0
        rewards.append(last_r)
        last_orig_s = orig_s
        
        if len(pi_losses) == report_every_trains:
            print_and_log(("Steps: %d\tTime: %d\tPloss: %.4f\tVloss: %.4f\t"+
                           "Hloss: %.4f"+
                           "\tSumR: %.4f\tMaxR: %.4f\tMinR: %.4f\tAvrgV: %.4f")%
                    (step_ctr,
                     int(time()-start_time),
                     sum(pi_losses)/len(pi_losses),
                     sum(v_losses)/len(v_losses),
                     sum(h_losses)/len(h_losses),
                     sum(rewards),
                     max(rewards),
                     min(rewards),
                     sum(vs)/len(vs)), logfile)
            pi_losses.clear()
            v_losses.clear()
            h_losses.clear()
            rewards.clear()
            vs.clear()

        if ((train_op_ctr+1) % save_every_trains) == 0:
            a2c.save(save_file)

if __name__ == '__main__':
    args = parser.parse_args()
    simple_training(executable=args.executable,
                    batch_size=args.batchsize, 
                    num_steps=args.timesteps,
                    report_every_trains=args.reportrate,
                    save_every_trains=args.saverate,
                    save_file=args.modelfile,
                    reward_function=REWARD_FUNCS[args.rewardfunc],
                    logfile=args.logfile,
                    num_frames=args.numframes)

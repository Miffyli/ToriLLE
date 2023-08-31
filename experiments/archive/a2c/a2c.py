#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  a2c.py
#  Simple Advantage Actor Critic implementation for Toribash
#  Author: Anssi "Miffyli" Kanervisto, 2018

#  Original paper: 
#  [1] https://arxiv.org/pdf/1602.01783.pdf
#  Easier-to-digest version here (Berkeley DRL course):
#  [2] http://rll.berkeley.edu/deeprlcourse/f17docs/lecture_5_actor_critic_pdf.pdf
#  Guidance from following codes:
#  [3] https://github.com/mihahauke/deep_rl_vizdoom/blob/master/networks/a3c.py
#  [4] https://github.com/openai/baselines/tree/master/baselines/a2c

#  Note that this may not be the most effecient (or correct) implementation
#  of the method. Please refer to [4] for more refined implementation.

import numpy as np
import tensorflow as tf

# Default beta value for entropy regularization
DEFAULT_BETA = 0.002
# Default learning rate
LEARNING_RATE = 7e-4
# Gamma for RL
GAMMA = 0.99

class ToribashA2C:
    """ 
    Simple A2C implementation for Toribash
    
    One key difference is that there are N joints, each of which can be
    in M different states. So we need a multi-discrete distribution
    rather than discrete.
    Pi is matrix NxM, where it is softmaxed over M
    """
    def __init__(self, num_input, num_joints, num_joint_states, 
                 beta=DEFAULT_BETA, value_weight=0.5,
                 load_model=None):
        self.num_input = num_input
        self.num_joints = num_joints
        self.num_joint_states = num_joint_states
        
        self.input_s = tf.placeholder(np.float32, [None, self.num_input],
                                       name="input_s")
        # Integer values in range [0, num_joint_states]
        self.input_a = tf.placeholder(int32, [None, num_joints],
                                       name="input_a")
        
        # Will be used in the network
        self.input_a_onehot = tf.one_hot(self.input_a, 
                                         depth=self.num_joint_states,
                                         axis=-1)

        self.input_r = tf.placeholder(np.float32, [None,],
                                       name="input_r")
        
        self.target_v = tf.placeholder(np.float32, [None,],
                                       name="target_v")
        
        # Defined in build_network
        self.v = None
        self.pi = None
        self.loss_v = None
        self.loss_pi = None
        self.loss = None
        # This will be final layer of common network head
        self.network_head = None

        # Entropy weight
        self.beta = beta
        # Value loss weight
        self.value_weight = value_weight
        
        self.session = None
        self.optimizer = None
        self.train_op = None
        
        self.saver = None

        self.build_network()
        
    def _initialize_session(self):
        """ Create TF session and initialize network with random parameters """
        # Without this we may have fun rendering the game...
        config = tf.ConfigProto()
        config.gpu_options.allow_growth = True
        self.session = tf.Session(config=config)
        self.session.run(tf.global_variables_initializer())
        self.session.run(tf.local_variables_initializer())
    
    def build_network(self):
        # Create some head 
        # Same as used with e.g. baselines/ppo for mujoco tasks
        self.dense1 = tf.layers.dense(inputs=self.input_s,
                              units=64,
                              activation=tf.nn.tanh,
                              name="dense1")
        self.dense2 = tf.layers.dense(inputs=self.dense1,
                              units=64,
                              activation=tf.nn.tanh,
                              name="dense2")
        
        # In case we will modify the network till this point
        self.network_head = self.dense2
        
        # Split to v and pi
        self.v = tf.layers.dense(inputs=self.network_head,
                                        units=1,
                                        activation=None)
        self.v = tf.reshape(self.v, (-1,),name="output_v")
        
        self.pi = tf.layers.dense(inputs=self.network_head,
                             units=self.num_joints*
                                   self.num_joint_states,
                             activation=None)
        self.pi = tf.reshape(self.pi, (tf.shape(self.pi)[0],
                                       self.num_joints,
                                       self.num_joint_states), name="logit_pi")
        # Do softmaxing but only in specific dimension
        self.pi = tf.nn.softmax(self.pi, axis=2, name="output_pi")
        
        # ---
        # Done with the network structure.
        # Now the fun part, i.e. creating the loss
        # ---
        
        # target_v = r + v(s') (or n-step reward)
        advantage = self.target_v - self.v
        
        # Update value function (much like in [3])
        self.loss_v = tf.reduce_mean(tf.square(advantage)*0.5) * self.value_weight
        
        # Stop gradient to prevent pi_loss from affecting value function
        # (Wouldn't have thought of this without [3])
        advantage = tf.stop_gradient(advantage)
        
        # Clip for numerical stability and log
        log_pi = tf.log(tf.clip_by_value(self.pi, 1e-7, 1))
        
        # Only select pis that were selected as an action
        # (i.e. the joint states we actually selected)
        selected_pi = tf.boolean_mask(log_pi, self.input_a_onehot)
        selected_pi = tf.reshape(selected_pi, (-1,self.num_joints))
        
        # Negative because optimizer attempts to minimize this
        self.loss_pi = -tf.reduce_mean(tf.multiply(selected_pi,
                                                   advantage[:,None]))
        
        # Entropy term
        # H(X) = - \sum{P(X) * log P(X)}
        entropy = tf.reduce_mean(-tf.reduce_sum(self.pi * log_pi, axis=1))
        # We want to maximize entropy, hence neg
        self.loss_entropy = -self.beta*entropy
        
        # TODO add linear annealing to the entropy term
        self.loss = self.loss_pi + self.loss_v + self.loss_entropy
        
        # Now just create vanilla TF optimizer and training op
        self.optimizer = tf.train.RMSPropOptimizer(LEARNING_RATE)
        self.train_op = self.optimizer.minimize(self.loss)
    
    def train_on_batch(self, states, state_primes, actions, returns):
        """ 
        Run train ops on given batch of states, followup states, actions and
        returns. 
        Parameters:
            states: [None, num_inputs]. Represents original state
            state_primes: [None, num_inputs]: Represents succeeding state
            actions: [None, num_joints] where each element is in range 
                     [0,num_joint_states]. Represents joint states.
            returns: Either rewards or N-step returns
        Returns:
            loss_pi, loss_v, loss_H: Losses from training 
        """
        
        # This doesn't have proper handling of terminal states 
        # (target_v = return, not based on the state_primes)
        
        # Check if we have a session. If not, init to random
        if not self.session:
            self._initialize_session()
        
        # Target values for V
        vs = self.predict_v(state_primes)
        target_vs = returns + vs*GAMMA
        
        loss_pi, loss_v, loss_H, _ = self.session.run([self.loss_pi, 
                                    self.loss_v, self.loss_entropy, 
                                    self.train_op],
                                   feed_dict = {self.input_s: states,
                                                self.input_a: actions,
                                                self.input_r: returns,
                                                self.target_v: target_vs})
        return loss_pi, loss_v, loss_H

    def predict_v(self, states):
        """ 
        Predict values for given states. Used in training 
        Parameters:
            states: [None,num_inputs] representing the state
        Returns:
            values: [None,] representing the values of the states
        """
        # Check if we have a session. If not, init to random
        if not self.session:
            self._initialize_session()
        return self.session.run([self.v], 
                                 feed_dict = {self.input_s: states})[0]
    
    def predict_pi(self, states):
        """ 
        Predict policies for given states. 
        Parameters:
            states: [None,num_inputs] representing the states
        Returns:
            values: [None,num_joints,num_joint_states] representing the 
                    probabilities of selecting joint states per joint 
        """
        # Check if we have a session. If not, init to random
        if not self.session:
            self._initialize_session()
        return self.session.run([self.pi], 
                                 feed_dict = {self.input_s: states})[0]
        
    def predict_pi_and_v(self, states):
        """ Predict policies and values for given states. """
        # Check if we have a session. If not, init to random
        if not self.session:
            self._initialize_session()
        return self.session.run([self.pi, self.v], 
                                 feed_dict = {self.input_s: states})
    
    def save(self, filename):
        if self.session is None:
            raise ValueError("TensorFlow session not initialized")
        if self.saver is None:
            self.saver = tf.train.Saver()
        self.saver.save(self.session, filename)

    def load(self, filename):
        if self.saver is None:
            self.saver = tf.train.Saver()
        self.session = tf.Session()
        self.saver.restore(self.session, filename)
        
if __name__ == '__main__':
    # Testing with random values to see if code even runs correctly
    from tqdm import tqdm
    num_inputs = 63
    num_joints = 22
    num_joint_states = 4
    batch_size = 32
    num_batches = 1000
    num_epochs = 1
    
    state = np.random.random((num_inputs,))
    state_prime = np.random.random((num_inputs,))
    action = np.random.randint(0, num_joint_states, size=(num_joints,))
    reward = np.random.random((1,))[0]-0.5
    
    print("Action: "+str(action))
    print("Reward: "+str(reward))
    
    states = np.stack([state for i in range(batch_size)])
    state_primes = np.stack([state_prime for i in range(batch_size)])
    actions = np.stack([action for i in range(batch_size)])
    rewards = np.stack([reward for i in range(batch_size)])
    
    a2c = ToribashA2C(num_inputs, num_joints, num_joint_states)
    for epoch in range(num_epochs):
        losses = []
        for i in tqdm(range(num_batches)):
            losses.append(sum(a2c.train_on_batch(
                               states,
                               state_primes,
                               actions,
                               rewards)))
        print("Avrg loss: %f" % (sum(losses)/len(losses)))
        print("Pi: "+str(a2c.predict_pi(np.expand_dims(state,0))))
    
    a2c.save("testmodel/test")
    a2c.load("testmodel/test")

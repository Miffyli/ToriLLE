#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
#  a2c.py
#  Simple Advantage Actor Critic implementation for Toribash
#  Author: Anssi "Miffyli" Kanervisto

#  Original paper: 
#  [1] https://arxiv.org/pdf/1602.01783.pdf
#  Easier-to-digest version here (Berkeley DRL course):
#  [2] http://rll.berkeley.edu/deeprlcourse/f17docs/lecture_5_actor_critic_pdf.pdf
#  Guidance from Kempka's A3C code here:
#  [3] https://github.com/mihahauke/deep_rl_vizdoom/blob/master/networks/a3c.py

#  Note that this may not be the most effecient (or correct) implementation
#  of the method, but hopefully learns something.

import numpy as np
import tensorflow as tf

class ToribashA2C:
    """ Simple A2C implementation for Toribash
    
    One key difference is that there are N joints, each of which can be
    in M different states. So we need something different for this.
    Pi is matrix NxM, where it is softmaxed over M"""
    def __init__(self, num_input, num_joints, num_joint_states, load_model=None):
        self.num_input = num_input
        self.num_joints = num_joints
        self.num_joint_states = num_joint_states
        
        self.input_s = tf.placeholder(np.float32, [None, self.num_input],
                                       name="input_s")
        # Integer values in range [0, num_joint_states]
        self.input_a = tf.placeholder(np.int32, [None, num_joints],
                                       name="input_a")
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
        
        self.build_network()
        
        # Either loaded or defined in training
        self.session = None
        self.optimizer = None
        self.train_op = None
        self.first_train = True
        
    def build_network(self):
        # Create some head 
        self.dense1 = tf.layers.dense(inputs=self.input_s,
                              units=512,
                              activation=tf.nn.relu,
                              name="dense1")
        self.dense2 = tf.layers.dense(inputs=self.dense1,
                              units=512,
                              activation=tf.nn.relu,
                              name="dense2")
        self.dense3 = tf.layers.dense(inputs=self.dense2,
                              units=512,
                              activation=tf.nn.relu,
                              name="dense3")
        
        # In case we will modify the network till this point
        network = self.dense3
        
        # Split to v and pi
        self.v = tf.layers.dense(inputs=network,
                                        units=1,
                                        activation=None)
        self.v = tf.reshape(self.v, (-1,),name="output_v")
        
        self.pi = tf.layers.dense(inputs=network,
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
        self.loss_v = 0.5 * tf.reduce_sum(advantage**2)
        
        # Stop gradient to prevent pi_loss from affecting value function
        # (Wouldn't have thought of this without [3])
        advantage = tf.stop_gradient(advantage)
        
        # Only select pis that were selected as an action
        # TODO this needs checking if this went correctly
        action_one_hot = tf.one_hot(self.input_a, depth=self.num_joint_states,
                                    axis=-1)
        selected_pi = tf.boolean_mask(self.pi, action_one_hot)
        selected_pi = tf.reshape(selected_pi, (-1,self.num_joints))
        
        # Clip for numerical stability and log
        log_pi = tf.log(tf.clip_by_value(selected_pi, 1e-10, 1))
        # Negative because optimizer attempts to minimize this
        self.loss_pi = -tf.reduce_sum(tf.multiply(log_pi,advantage[:,None]))
        
        # TODO add entropy for exploration
        self.loss = self.loss_pi + self.loss_v
    
    def train_on_batch(self, states, state_primes, actions, returns):
        """ Run train ops on given batch of states, followup states, actions and
            returns. 
        Parameters:
            states: [None, num_inputs]. Represents original state
            state_primes: [None, num_inputs]: Represents succeeding state
            actions: [None, num_joints] where each element is in range 
                     [0,num_joint_states]. Represents joint states.
            returns: Either rewards or N-step returns
        Returns:
            loss: The loss from training update
        """
        
        # Check if this is first train operation. If yes, init 
        # session and network and such
        if self.first_train:
            # Good ol' vanilla Adam. Can't go wrong with it (Right?... Right?!)
            self.optimizer = tf.train.AdamOptimizer()
            
            self.train_op = self.optimizer.minimize(self.loss)
            
            if self.session is None:
                self.session = tf.Session()
                # Re-init network only if session wasn't available
                # (i.e. we did not load a model)
                # Note that due to adaptive nature of Adam, first 
                # update iterations could probably wreck whatever
                # loaded model had stored
                self.session.run(tf.global_variables_initializer())
                self.session.run(tf.local_variables_initializer())
            self.first_train = False

        # Target values for V
        vs = self.predict_v(state_primes)
        target_vs = returns + vs
        
        loss, _ = self.session.run([self.loss, self.train_op],
                                   feed_dict = {self.input_s: states,
                                                self.input_a: actions,
                                                self.input_r: returns,
                                                self.target_v: target_vs})
        return loss

    def predict_v(self, states):
        """ Predict values for given states. Used in training 
        Parameters:
            states: [None,num_inputs] representing the state
        Returns:
            values: [None,] representing the values of the states
        """
        return self.session.run([self.v], 
                                 feed_dict = {self.input_s: states})[0]
    
    def predict_pi(self, states):
        """ Predict policies for given states. 
        Parameters:
            states: [None,num_inputs] representing the states
        Returns:
            values: [None,num_joints,num_joint_states] representing the 
                    probabilities of selecting joint states per joint 
        """
        return self.session.run([self.pi], 
                                 feed_dict = {self.input_s: states})[0]
    
    def save(self, filename):
        if self.session is None:
            raise ValueError("TensorFlow session not initialized")
        saver = tf.train.Saver()
        saver.save(self.session, filename)

    def load(self, filename):
        saver = tf.train.Saver()
        self.session = tf.Session()
        saver.restore(self.session, filename)
        
if __name__ == '__main__':
    # Testing with random values to see if code even runs correctly
    from tqdm import tqdm
    num_inputs = 10
    num_joints = 5
    num_joint_states = 2
    batch_size = 32
    num_batches = 1000
    num_epochs = 1
    
    state = np.random.random((num_inputs,))
    state_prime = np.random.random((num_inputs,))
    action = np.random.randint(0, num_joint_states, size=(num_joints,))
    reward = np.random.random((1,))[0]-1.0
    
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
            losses.append(a2c.train_on_batch(
                               states,
                               state_primes,
                               actions,
                               rewards))
        print("Avrg loss: %f" % (sum(losses)/len(losses)))
        print("Pi: "+str(a2c.predict_pi(np.expand_dims(state,0))))
    
    a2c.save("testmodel/test")
    a2c.load("testmodel/test")
    

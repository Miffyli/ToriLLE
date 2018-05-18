#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from multiprocessing import Process, Value, Lock
import random as r
from time import sleep,time
from torille import ToribashControl

NUM_JOINTS = 20

def create_random_actions():
    """ Return random actions """
    ret = [[],[]]
    for plridx in range(2):
        for jointidx in range(NUM_JOINTS):
            ret[plridx].append(r.randint(1,4))
        ret[plridx].append(r.randint(0,1))
        ret[plridx].append(r.randint(0,1))
    return ret
    
def run_async_torille(toribash_exe, tick_counter, quit_flag):
    # Runs Toribash and increments the Value tick_counter on every frame
    controller = ToribashControl(toribash_exe)
    controller.settings.set("matchframes", 100)
    controller.settings.set("turnframes", 10)
    controller.settings.set("engagement_distance", 1000)
    controller.init()
    while quit_flag.value == 0:
        s,terminal = controller.get_state()
        if terminal: 
            s = controller.reset()
        actions = create_random_actions()
        controller.make_actions(actions)
        # Others are not writing here, so no need for locks
        tick_counter.value += 1
    controller.close()
    
def test_async(toribash_exe, num_instances, print_every_seconds,
               run_for_seconds):
    last_ticks = [0 for i in range(num_instances)]
    tick_ctrs = [Value("i") for i in range(num_instances)]
    quit_flags = [Value("i") for i in range(num_instances)]
    launch_lock = Lock()
    runners = []
    for i in range(num_instances):
        process = Process(target=run_async_torille, args=(toribash_exe,
                                                          tick_ctrs[i],
                                                          quit_flags[i]))
        process.start()
        runners.append(process)
    
    start_time = time()
    while (time()-start_time) < run_for_seconds:
        sleep(print_every_seconds)
        new_ticks = [tick_ctrs[i].value for i in range(num_instances)]
        ticks_progressed = 0
        for i in range(num_instances):
            ticks_progressed += new_ticks[i]-last_ticks[i]
        fps = ticks_progressed / print_every_seconds
        last_ticks = new_ticks
        print("FPS: %.2f" % fps)
    
    for i in range(num_instances):
        quit_flags[i].value = 1
        runners[i].join()
    
if __name__ == '__main__':
	test_async(toribash_exe=r"D:\Games\Toribash-5.2\toribash.exe",
               num_instances=4,
               print_every_seconds=10.0,
               run_for_seconds=120.0)


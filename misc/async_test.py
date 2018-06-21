#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from multiprocessing import Process, Value, Lock
import random as r
from time import sleep,time
from torille import ToribashControl
import sys

NUM_JOINTS = 20

MATCH_FRAMES = 100
TURN_FRAMES = 10

WARM_UP_SECONDS = 120
BENCHMARK_SECONDS = 60

def create_random_actions():
    """ Return random actions """
    ret = [[],[]]
    for plridx in range(2):
        for jointidx in range(NUM_JOINTS):
            ret[plridx].append(r.randint(1,4))
        ret[plridx].append(r.randint(0,1))
        ret[plridx].append(r.randint(0,1))
    return ret
    
def run_async_torille(tick_counter, quit_flag):
    # Runs Toribash and increments the Value tick_counter on every frame
    controller = ToribashControl()
    controller.settings.set("matchframes", MATCH_FRAMES)
    controller.settings.set("turnframes", TURN_FRAMES)
    controller.settings.set("engagement_distance", 1500)
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
    
def test_async(num_instances, warmup_seconds, benchmark_seconds):
    last_ticks = [0 for i in range(num_instances)]
    tick_ctrs = [Value("i") for i in range(num_instances)]
    quit_flags = [Value("i") for i in range(num_instances)]
    runners = []
    for i in range(num_instances):
        process = Process(target=run_async_torille, args=(toribash_exe,
                                                          tick_ctrs[i],
                                                          quit_flags[i]))
        process.start()
        runners.append(process)
    
    sleep(warmup_seconds)
    
    # Get current number of frames
    start_ticks = [tick_ctrs[i].value for i in range(num_instances)]
    
    # Wait for benchmark time
    sleep(benchmark_seconds)
    
    # Get progressed number of ticks
    ticks = [tick_ctrs[i].value for i in range(num_instances)]
    
    # Calculate FPS
    ticks_progressed = 0
    for i in range(num_instances):
        ticks_progressed += new_ticks[i]-last_ticks[i]
    fps = ticks_progressed / print_every_seconds
    
    print("FPS: %.2f" % fps)
    
    for i in range(num_instances):
        quit_flags[i].value = 1
        runners[i].join()
    
if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: python3 async_test.py num_instances")
    else:
        num_instances = int(sys.argv[1])
        print(("\tInstances: %d\n\tWarmup: %d s\n\tBenchmark: %d s" +
              "\n\tMatchlength: %d\n\tTurnframes: %d") %
              (num_instances, WARM_UP_SECONDS, BENCHMARK_SECONDS, 
               MATCH_FRAMES, TURN_FRAMES))
        test_async(toribash_exe=r"D:\Games\Toribash-5.2\toribash.exe",
                num_instances=num_instances,
                warm_up_seconds=WARM_UP_SECONDS,
                benchmark_seconds=BENCHMARK_SECONDS)


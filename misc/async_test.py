#!/usr/bin/env python3

from multiprocessing import Process, Value, Lock
import random as r
from time import sleep,time
from torille import ToribashControl
import sys

NUM_JOINTS = 22

WARM_UP_SECONDS = 10
BENCHMARK_SECONDS = 60

def create_random_actions():
    """ Return random actions """
    ret = [[],[]]
    for plridx in range(2):
        for jointidx in range(NUM_JOINTS):
            ret[plridx].append(r.randint(1,4))
    return ret
    
def run_async_torille(tick_counter, quit_flag, match_frames, turn_frames):
    # Runs Toribash and increments the Value tick_counter on every frame
    controller = ToribashControl()
    controller.settings.set("matchframes", match_frames)
    controller.settings.set("turnframes", turn_frames)
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
    
def test_async(num_instances, warm_up_seconds, benchmark_seconds, match_frames,
               turn_frames):
    last_ticks = [0 for i in range(num_instances)]
    tick_ctrs = [Value("i") for i in range(num_instances)]
    quit_flags = [Value("i") for i in range(num_instances)]
    runners = []
    for i in range(num_instances):
        process = Process(target=run_async_torille, args=(tick_ctrs[i],
                                                          quit_flags[i],
                                                          match_frames,
                                                          turn_frames))
        process.start()
        runners.append(process)
    
    sleep(warm_up_seconds)
    
    # Get current number of frames
    start_ticks = [tick_ctrs[i].value for i in range(num_instances)]
    
    # Wait for benchmark time
    sleep(benchmark_seconds)
    
    # Get progressed number of ticks
    ticks = [tick_ctrs[i].value for i in range(num_instances)]
    
    # Calculate FPS
    ticks_progressed = 0
    for i in range(num_instances):
        ticks_progressed += ticks[i]-start_ticks[i]
    pps = ticks_progressed / benchmark_seconds
    
    print("PPS: %.2f" % pps)
    print("FPS: %.2f\n" % (pps*turn_frames))
    
    for i in range(num_instances):
        quit_flags[i].value = 1
        runners[i].join()
    
if __name__ == '__main__':
    if len(sys.argv) != 4:
        print("Usage: python3 async_test.py num_instances match_frames turn_frames")
    else:
        num_instances = int(sys.argv[1])
        match_frames = int(sys.argv[2])
        turn_frames = int(sys.argv[3])
        print(("Instances: %d\nWarmup: %d s\nBenchmark: %d s" +
              "\nMatchframes: %d\nTurnframes: %d") %
              (num_instances, WARM_UP_SECONDS, BENCHMARK_SECONDS, 
               match_frames, turn_frames))
        test_async(num_instances=num_instances,
                   warm_up_seconds=WARM_UP_SECONDS,
                   benchmark_seconds=BENCHMARK_SECONDS,
                   match_frames=match_frames,
                   turn_frames=turn_frames)


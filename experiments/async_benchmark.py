#!/usr/bin/env python3
#
#  async_benchmark.py
#  FPS benchmarking. Runs multiple instances of Toribash
#  in parallel (asynchronously)
#
#  Author: Anssi "Miffyli" Kanervisto, 2018

from multiprocessing import Process, Value
import random as r
from time import sleep,time
from torille import ToribashControl
import argparse
import sys

NUM_JOINTS = 22

# How many seconds after all instances have booted up
WARM_UP_SECONDS = 10

# How many seconds will benchmark last
BENCHMARK_SECONDS = 60

parser = argparse.ArgumentParser()
parser.add_argument("--warmup_time", default=WARM_UP_SECONDS,
                    type=int, help="Seconds before benchmark starts (default: 10s)")
parser.add_argument("--benchmark_time", default=BENCHMARK_SECONDS,
                    type=int, help="How many seconds benchmark lasts (default: 60s)")
parser.add_argument("num_instances", type=int, help="How many instances will be launched")
parser.add_argument("match_frames", type=int, help="How many frames matches last")
parser.add_argument("turn_frames", type=int, help="Amount of frames between turns")
parser.add_argument("engagement_distance", type=int, help="How far apart players spawn")

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
               turn_frames, engagement_distance):
    """ 
    Run benchmark with given parameters, returns [turns per second, frames per second]
    """
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
    
    for i in range(num_instances):
        quit_flags[i].value = 1
        runners[i].join()

    return [pps, (pps*turn_frames)]
    
if __name__ == '__main__':
    args = parser.parse_args()
    
    assert args.turn_frames > 1
    assert args.turn_frames < args.match_frames
    assert args.engagement_distance > 0 

    print(("Instances: %d\nWarmup: %d s\nBenchmark: %d s" +
              "\nMatchframes: %d\nTurnframes: %d\nEngagement distance: %d") %
              (args.num_instances, args.warmup_time, args.benchmark_time, 
               args.match_frames, args.turn_frames, args.engagement_distance))
    [pps, fps] = test_async(num_instances=args.num_instances,
                            warm_up_seconds=args.warmup_time,
                            benchmark_seconds=args.benchmark_time,
                            match_frames=args.match_frames,
                            turn_frames=args.turn_frames,
                            engagement_distance=args.engagement_distance)
    print("PPS: %.2f" % pps)
    print("FPS: %.2f" % fps)

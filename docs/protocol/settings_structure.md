Elements in settings list used for communication
==============================================

**Check source for more information about each of these settings**

Elements in the action list ([index] = [description]).
```
0 = matchframes (int, game default: 500. How long the match is in terms of frames)
1 = turnframes (int, game default: 10. How many frames each action is repeated for (in DRL, this would be "frame skip"/"action repeat"))
2 = engagement distance (int, game default: 100. Starting distance between players)
3 = engagement height (int, game default: 0. Starting height of players)
4 = engagement rotation (int, game default: 0. Starting rotation of players (in deg))
5 = gravity (float3, x,y,z, game default: 0.0 0.0 -9.81. Direction of gravity)
8 = damage (int, one of {0,1,2}, game default: 0. See source below for further info)
9 = dismemberment (bool, {0,1}, game default: 1. Enable/disable dismemberment)
10 = dismemberthreshold  (int, game default: 100. How much power is needed to rip joints off)
11 = fractures (bool, {0,1}, game default: 0. Enable/disable fractures)
12 = fracturethreshold  (int, game default: 100. How much power is needed for fracturing a joint)
13 = disqualification (bool, {0,1}, game default: 0. Enable/disable disqualification)
14 = disqual flags (bool, {0,1}, game default: 0. See source for more info)
15 = disqual timeout (int, game default: 0. Number of frames one can touch ground before loosing)
16 = dojotype (bool, {0,1}, game default: 0, Type of the dojo (square or round))
17 = dojosize (int, game default: 0, Size of the dojo)
18 = replay_file (str, default: "None", Replay file where to store rounds (only stored if doesn't match with string "None"))
```

Floats have decimals separated with dot ".".

Booleans are integers {0,1}

Sources used:

* http://forum.toribash.com/showthread.php?t=317900

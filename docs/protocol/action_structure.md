Elements in settings list used for communication
================================================

Elements in the action list ([index] = [description])
```
0 = plr0 neck
1 = plr0 chest
2 = plr0 lumbar
3 = plr0 abs
4 = plr0 right pec
5 = plr0 right shoulder
6 = plr0 right elbow
7 = plr0 left pec
8 = plr0 left shoulder
9 = plr0 left elbow
10 = plr0 right wrist
11 = plr0 left wrist
12 = plr0 right glute
13 = plr0 left glute
14 = plr0 right hip
15 = plr0 left hip
16 = plr0 right knee
17 = plr0 left knee
18 = plr0 right ankle
19 = plr0 left ankle
20 = plr0 grip left hand
21 = plr0 grip right hand

22 = plr1 neck
23 = plr1 chest
24 = plr1 lumbar
25 = plr1 abs
26 = plr1 right pec
27 = plr1 right shoulder
28 = plr1 right elbow
29 = plr1 left pec
30 = plr1 left shoulder
31 = plr1 left elbow
32 = plr1 right wrist
33 = plr1 left wrist
34 = plr1 right glute
35 = plr1 left glute
36 = plr1 right hip
37 = plr1 left hip
38 = plr1 right knee
39 = plr1 left knee
40 = plr1 right ankle
41 = plr1 left ankle
42 = plr1 grip left hand
43 = plr1 grip right hand
```

Elements outside hand grips (20, 21, 42 and 43) are integers, and
one of following:
```
1 = extend/right rotate/right bend
2 = contract/left rotate/left bend
3 = hold
4 = relax
```

More detailed list of what each action does for each joint 
available [in Table 1 of this paper](https://www.researchgate.net/profile/Jonathan_Byrne/publication/228848637_Optimising_offensive_moves_in_toribash_using_a_genetic_algorithm/links/0046351420d5001396000000.pdf).

Elements for hand gripping (20, 21, 42 and 45) are integers,
and one of the following:
```
0 = don't grip (don't "attach")
1 = grip
```


Sources used:

* http://forum.toribash.com/showthread.php?t=9391

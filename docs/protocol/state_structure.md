Elements in state list used for communication
=============================================

Elements in the state list ([index] = [description])
```
0   = plr0 head x,y,z
3   = plr0 breast x,y,z
6   = plr0 chest x,y,z
9   = plr0 stomach x,y,z
12  = plr0 groin x,y,z
15  = plr0 r_pecs x,y,z
18  = plr0 r_biceps x,y,z
21  = plr0 r_triceps x,y,z
24  = plr0 l_pecs x,y,z
27  = plr0 l_biceps x,y,z
30  = plr0 l_triceps x,y,z
33  = plr0 r_hand x,y,z
36  = plr0 l_hand x,y,z
39  = plr0 r_butt x,y,z
42  = plr0 l_butt x,y,z
45  = plr0 r_thigh x,y,z
48  = plr0 l_thigh x,y,z
51  = plr0 l_leg x,y,z
54  = plr0 r_leg x,y,z
57  = plr0 r_foot x,y,z
60  = plr0 l_foot x,y,z
63  = plr0 neck state
64  = plr0 chest state
65  = plr0 lumbar state
66  = plr0 abs state
67  = plr0 right pec state
68  = plr0 right shoulder state
69  = plr0 right elbow state
70  = plr0 left pec state
71  = plr0 left shoulder state
72  = plr0 left elbow state
73  = plr0 right wrist state
74  = plr0 left wrist state
75  = plr0 right glute state
76  = plr0 left glute state
77  = plr0 right hip state
78  = plr0 left hip state
79  = plr0 right knee state
80  = plr0 left knee state
81  = plr0 right ankle state
82  = plr0 left ankle state
83  = plr0 grip left hand state
84  = plr0 grip right hand state
85  = plr0 injury

86  = plr1 head x,y,z
88  = plr1 breast x,y,z
91  = plr1 chest x,y,z
94  = plr1 stomach x,y,z
97  = plr1 groin x,y,z
100 = plr1 r_pecs x,y,z
103 = plr1 r_biceps x,y,z
106 = plr1 r_triceps x,y,z
108 = plr1 l_pecs x,y,z
112 = plr1 l_biceps x,y,z
115 = plr1 l_triceps x,y,z
118 = plr1 r_hand x,y,z
121 = plr1 l_hand x,y,z
124 = plr1 r_butt x,y,z
127 = plr1 l_butt x,y,z
130 = plr1 r_thigh x,y,z
133 = plr1 l_thigh x,y,z
136 = plr1 l_leg x,y,z
138 = plr1 r_leg x,y,z
142 = plr1 r_foot x,y,z
145 = plr1 l_foot x,y,z
148 = plr1 neck state
149 = plr1 chest state
150 = plr1 lumbar state
151 = plr1 abs state
152 = plr1 right pec state
153 = plr1 right shoulder state
154 = plr1 right elbow state
155 = plr1 left pec state
156 = plr1 left shoulder state
157 = plr1 left elbow state
158 = plr1 right wrist state
159 = plr1 left wrist state
160 = plr1 right glute state
161 = plr1 left glute state
162 = plr1 right hip state
163 = plr1 left hip state
164 = plr1 right knee state 
165 = plr1 left knee state
166 = plr1 right ankle state
167 = plr1 left ankle state
168 = plr1 grip left hand state 
169 = plr1 grip right hand state
170 = plr1 injury
```

Coordinates (x,y,z) are floats (decimals separated with a dot).

States are one of {1,2,3,4} representing the state of joint, where:
```
1 = extend/right rotate/right bend
2 = contract/left rotate/left bend
3 = hold
4 = relax
```

Grip-states are one of {0,1} representing if hand is gripping (1 = grip).

Injury specifies the injury aflicted to player's body. This is the score
of the opponent (e.g. Plr0 injury of 2000 means Plr1 has score of 2000).

Sources used:

* http://forum.toribash.com/showthread.php?t=9391
Elements in state list used for communication
=============================================

Elements in the state list ([index] = [description])

Coordinates (x,y,z) are floats (decimals separated with a dot).

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
63  = plr0 groin rotation (4x4 matrix, row-by-row)
79  = plr0 neck state
80  = plr0 chest state
81  = plr0 lumbar state
82  = plr0 abs state
83  = plr0 right pec state
84  = plr0 right shoulder state
85  = plr0 right elbow state
86  = plr0 left pec state
87  = plr0 left shoulder state
88  = plr0 left elbow state
89  = plr0 right wrist state
90  = plr0 left wrist state
91  = plr0 right glute state
92  = plr0 left glute state
93  = plr0 right hip state
94  = plr0 left hip state
95  = plr0 right knee state
96  = plr0 left knee state
97  = plr0 right ankle state
98  = plr0 left ankle state
99  = plr0 grip left hand state
100  = plr0 grip right hand state
101  = plr0 injury

102  = plr1 head x,y,z
105  = plr1 breast x,y,z
108  = plr1 chest x,y,z
111  = plr1 stomach x,y,z
114  = plr1 groin x,y,z
117 = plr1 r_pecs x,y,z
120 = plr1 r_biceps x,y,z
123 = plr1 r_triceps x,y,z
126 = plr1 l_pecs x,y,z
129 = plr1 l_biceps x,y,z
132 = plr1 l_triceps x,y,z
135 = plr1 r_hand x,y,z
138 = plr1 l_hand x,y,z
141 = plr1 r_butt x,y,z
144 = plr1 l_butt x,y,z
147 = plr1 r_thigh x,y,z
150 = plr1 l_thigh x,y,z
153 = plr1 l_leg x,y,z
156 = plr1 r_leg x,y,z
159 = plr1 r_foot x,y,z
162 = plr1 l_foot x,y,z
165 = plr1 groin rotation (4x4 matrix, row-by-row)
181 = plr1 neck state
182 = plr1 chest state
183 = plr1 lumbar state
184 = plr1 abs state
185 = plr1 right pec state
186 = plr1 right shoulder state
187 = plr1 right elbow state
188 = plr1 left pec state
189 = plr1 left shoulder state
190 = plr1 left elbow state
191 = plr1 right wrist state
192 = plr1 left wrist state
193 = plr1 right glute state
194 = plr1 left glute state
195 = plr1 right hip state
196 = plr1 left hip state
197 = plr1 right knee state 
198 = plr1 left knee state
199 = plr1 right ankle state
200 = plr1 left ankle state
201 = plr1 grip left hand state 
202 = plr1 grip right hand state
203 = plr1 injury
```

States are one of {1,2,3,4} representing the state of joint, where:
```
1 = extend/right rotate/right bend
2 = contract/left rotate/left bend
3 = hold
4 = relax
```

Grip-states are one of {0,1} representing if hand is gripping (1 = grip).

Injury specifies the injury inflicted to player's body. This is the score
of the opponent (e.g. Plr0 injury of 2000 means Plr1 has score of 2000).

Sources used:

* http://forum.toribash.com/showthread.php?t=9391

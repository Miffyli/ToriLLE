World Creator
=============
Created for Toribash 3.0 by NewbLuck

This script will assist the user in creating environment mod files for use 
in Toribash 3.0.


Quick Start and Tutorial:
-------------------------

When you first load the script, you will notice that the ground has changed to 
a grey color.  This is where the world floor is, and is grey to locate 
underground objects easier.  There is no objects in the world on loading.  

To load your first object, hit the * key on the numpad.  You should see a blue
cube in the center of the world.  

When objects are created, they are automatically added to the current group.
Objects in a group are affected by editing commands, and objects not in a group
are not.  You can tell if an object is in a group by its transparency.  More 
solid appearing opjects are grouped, and the more transparent ones are not 
grouped.

Also notice the outline around the object you just added, and how it is 
flashing.  This means this object is your current selected object.  If an 
object is selected, you can choose to group and ungroup this object, and
also change the object's shape type.

Try pressing 5 on the numpad a few times to see how the object changes types.
Press 5 again until the shape is back to the cube shape.  Now, try pressing 
4 on the numpad a few times.  The box will move left.   Now press numpad 6
to move the box to back where it was.  Do the same with numpad 8 and numpad 2.

You might have to rotate the camera sometimes to see the changes you have done.
To rotate the camera, use the arrow keys.  Holding shift and using up and down 
will adjust camera height.  Also, you can use the mouse to move the camera by
holding down the right mouse button.

Now that you have moved the cube and back in the two directions, try this with
the numpad 9 and numpad 3 keys.  This will change the height of your object.

Now, lets move our object out of the way by pressing 4 a few times.  Go ahead  
and press - on the numpad to remove this pbject from our group.  Notice how it
becomes more transparent.  Then, press numpad * to create a new object.  The 
current selection will move to the new object, andthe new object will be added
to the active group.  Press numpad enter a few times to see how the current 
object changes.  Press enter until the new object is selected again.  

Now, lets try resizing our object.  Hold numpad 0 and press 6 a few times. The
cube should have stretched out into a more rectangular shape.  Hold 0 and press
4 a few times to return it to its original shape.  Play with the movement keys
while holding 0 to seehow the cube stretches.  

Now, lets move this cube to touch our other cube.  Using the movement keys, 
scoot your new cube over to touch the old cube.  If it won't line up correctly, 
you can press Capslock to toggle fine movement on and off.  Once the new object
is touching the old, press enter to switch the current selection to the old 
object, then press + to add this object to the group.  Both objects should be
grouped now.  Try using the movement keys now.  Notice how both move together.
Also, try stretching the cubes vertically using numpad 0 and numpad 9.  Both 
should stretch the same amount.  

Now press - and enter. Scoot the object back away from the other, and press 
numpad 5 to switch to a sphere.  Try stretching this in all the directions.  
Notice how only 8 and 2 affect the radius.  now press 5 again to switch to
a cylinder.  Also try stretching this in all directions.  Notice how 8 and 2
change the radius, while 4 and 6 adjust the height. 

Now, press C on the keyboard.  A panel with buttons should pop up.  This is the
color editor.  Try pressing the colored buttons to see how it affects the 
grouped object.  Change the color to red and then press ok to close this panel.
Now, hit - on the numpad and then enter to switch to our original object.  Hit
+ to add this object to the group, then enter to switch back to the newer
object.  Now press c again.  Notice how the original object now becomes red.
When the color editor is loaded, its color gets set to current selections 
color, meaning any grouped objects assume this color.  

Play around a little bit and create a simple environment, then press enter on the 
main part of your keyboard.  This will write your environment to a file in your
script directory called world_out.tbm.  Move this new file to your mod 
directory, then load the mod in toribash.  You should see the environment you
created.



About Objects:
--------------

More solid: Grouped
Less solid: Not grouped
Flashing/Outlined: Selected
Darker areas: Underground


Controls:
---------

Commands in [ ] are the alternate keyboard layout keys. 

Numpad * [KB ~]................ Create a new object.
Numpad 2,4,6,8 [KB X,A,D,W].... Move object on the x/y plane.
Numpad 1,7 [KB Z,Q]............ Move object on the Z axis.
Numpad 0 [KB E]................ Hold to change movement input to scaling input.
Numpad . [KB R] ............... Hold to toggle movement input to rotation input.
Caps-Lock ..................... Toggle between coarse and fine adjustment, Caps off being coarse.
Numpad - [KB 1]................ Removes the current object from the group. 
Numpad + [KB 3]................ Adds the current object to the group.
Numpad Enter [KB 2]............ Move current selection to the next object.
Numpad 5 [KB S]................ Switches currently selected object between box, sphere, and cylinder.
Keyboard P .................... Duplicate currently selected object.
Keyboard Delete ............... Deletes currently selected object.

Keyboard Enter ................ Writes a tbm file.
Keyboard L .................... Loads a tbm file.
Keyboard C .................... Brings up the color modifying panel.
Keyboard M .................... Brings up mass modifying panel.
Keyboard F .................... Toggles visibiliy of flag modifying window.
Keyboard I .................... Toggles visibility of information window.
Keyboard K .................... Switches to alternate keyboard layout (Laptops need to use this)

Color Modifier Panel:
---------------------

Press C to load this.  The active color for the tool will be set to the color 
of the currently selected object.  If no object is on the scene, it will 
default to black.  Pressing the + or - for the corresponding color will modifiy
the color for the grouped objects only in that way.

Tip:  To copy colors quickly, with the color panel off, group all the objects
	  you want to color, then move selection to the object whos color you want
	  to copy from.  Then, press C, and that color will be applied.  This also
	  works with the mass and flags tool.



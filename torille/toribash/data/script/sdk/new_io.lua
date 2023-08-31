--new io.open example

--As long as the third parameter isn't nil it will open up in "./" instead of "data/script/".
local testfile = io.open("data/script/iotest.txt", "r", 1)
if(testfile ~= nil) then
	repeat
		line = testfile:read("*l")
		echo(line)
	until line == nil
end

--shows backwards compatability with old scripts.
local testfile = io.open("iotest.txt", "r")
if(testfile ~= nil) then
	repeat
		line = testfile:read("*l")
		echo(line)
	until line == nil
end
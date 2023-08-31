module("demo", package.seeall)

function add(a, b) echo(string.format("%f + %f = %.2f (2dp)", a, b, a+b)) end

--USAGE:
--[[
require "demomodule"

demo.add(134.34, 234.12)
]]
module("demo2", package.seeall)

function divide(a, b) echo(string.format("%f / %f = %.2f (2dp)", a, b, a/b)) end
function multiply(a, b) echo(string.format("%f x %f= %.2f (2dp)", a, b, a*b)) end

dofile("modules/anothermoduledemo/loaded.lua")

--USAGE:
--[[
require "anothermoduledemo"

demo2.divide(134.34, 234.12)
demo2.multiply(134.34, 234.12)
]]
local pui = require("gamesense/pui")
local vector = require("vector")
local ffi = require("ffi")

local menu = {
    enabled = true,
    value = 10,
    name = "test"
}

local checkbox = ui.new_checkbox("LUA", "B", "baran")

local function add(a,b)
    return a+b
end

local x = add(10,20)

if x > 20 then
    menu.value = x
else
    menu.value = 0
end

return menu
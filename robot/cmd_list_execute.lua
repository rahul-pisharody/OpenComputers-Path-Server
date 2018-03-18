local location = require("location")
local serial = require("serialization")
local sides = require("sides")
local robot = require("robot")

local move,turn,use = 1,2,3

local args = {...}

cmd_list = serial.unserialize(args[1])
local function execute_cmds(cmd_list)
  for i,c in ipairs(cmd_list) do
    if (c[1]==move) then
      if (c[2]==sides.up) then robot.up()
      elseif (c[2]==sides.down) then robot.down()
      elseif (c[2]==sides.front) then robot.forward()
      elseif (c[2]==sides.back) then robot.back()
      elseif (c[2]==sides.right) then robot.turnRight() robot.forward() robot.turnLeft()
      elseif (c[2]==sides.left) then robot.turnLeft() robot.forward() robot.turnRight()
      end
    elseif (c[1]==turn) then
      if (c[2]%4==1) then robot.turnRight()
      elseif (c[2]%4==3) then robot.turnLeft()
      elseif (c[2]%4==2) then robot.turnAround()
      end
    elseif (c[1]==use) then
      if (c[2]==sides.up) then robot.useUp()
      elseif (c[2]==sides.down) then robot.useDown()
      else robot.use()
      end
    end
  end
end
execute_cmds(cmd_list)
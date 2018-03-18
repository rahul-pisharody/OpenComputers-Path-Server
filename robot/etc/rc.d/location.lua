local location = require("location")
local robot = require("robot")

local old_up = robot.up
local old_down = robot.down
local old_forward = robot.forward
local old_back = robot.back
local old_turnRight = robot.turnRight
local old_turnLeft = robot.turnLeft
local old_turnAround = robot.turnAround

local function loc_up()
  local res = old_up()
  if res then
    local pos,orient = location.get()
    pos[2] = pos[2] + 1
    location.set(pos,orient)
  end
  return res
end
local function loc_down()
  local res = old_down()
  if res then
    local pos,orient = location.get()
    pos[2] = pos[2] - 1
    location.set(pos,orient)
  end
  return res
end
local function loc_forward()
  local res = old_forward()
  if res then
    local pos,orient = location.get()
    if (orient==0) then pos[1] = pos[1] + 1
    elseif (orient==1) then pos[3] = pos[3] + 1
    elseif (orient==2) then pos[1] = pos[1] - 1
    elseif (orient==3) then pos[3] = pos[3] - 1
    else print("ERROR: INVALID ORIENTATION")
    end
    location.set(pos,orient)
  end
  return res
end
local function loc_back()
  local res = old_back()
  if res then
    local pos,orient = location.get()
    if (orient==0) then pos[1] = pos[1] - 1
    elseif (orient==1) then pos[3] = pos[3] - 1
    elseif (orient==2) then pos[1] = pos[1] + 1
    elseif (orient==3) then pos[3] = pos[3] + 1
    else print("ERROR: INVALID ORIENTATION")
    end
    location.set(pos,orient)
  end
  return res
end
local function loc_turnRight()
  local res = old_turnRight()
  if res then
    local pos,orient = location.get()
    orient = (orient+1)%4
    location.set(pos,orient)
  end
  return res
end
local function loc_turnLeft()
  local res = old_turnLeft()
  if res then
    local pos,orient = location.get()
    orient = (orient-1)%4
    location.set(pos,orient)
  end
  return res
end

local function loc_turnAround()
  local res = old_turnAround()
  if res then
    local pos,orient = location.get()
    orient = (orient+2)%4
    location.set(pos,orient)
  end
  return res
end

function start(arg)
  robot.up = loc_up
  robot.down = loc_down
  robot.forward = loc_forward
  robot.back = loc_back
  robot.turnRight = loc_turnRight
  robot.turnLeft = loc_turnLeft
  robot.turnAround = loc_turnAround
end
function stop(arg)
  robot.up = old_up
  robot.down = old_down
  robot.forward = old_forward
  robot.back = old_back
  robot.turnRight = old_turnRight
  robot.turnLeft = old_turnLeft
  robot.turnAround = old_turnAround
end
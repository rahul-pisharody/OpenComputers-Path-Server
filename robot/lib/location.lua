local serialization = require("serialization")

local location={}
local position, orientation

local function save()
  local ostream = io.open("/var/loc.dat","w")
  ostream:write(serialization.serialize(position),"\n",serialization.serialize(orientation))
  ostream:close()
end

local function load()
  local istream = io.open("/var/loc.dat","r")
  local s_pos = istream:read("*line")
  local s_orient = istream:read("*line")
  if (s_pos and s_orient) then
    position = serialization.unserialize(s_pos)
    orientation = serialization.unserialize(s_orient)
  end
end

function location.set(pos,orient)
  position, orientation = pos, orient
  save()
end

function location.get()
  if (not position) then
    load()
  end
  return position,orientation
end

return location
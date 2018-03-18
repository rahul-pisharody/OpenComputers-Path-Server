path = require("path")
robot = require("robot")
computer = require("computer")


chargePos = {-43,107,253}

if (path.gotoPos(chargePos[1],chargePos[2],chargePos[3])) then
  robot.useUp()
  while(computer.energy()<0.9*computer.maxEnergy()) do
    os.sleep(0.5)
  end
  robot.useUp()
end
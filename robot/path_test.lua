path = require("path")

args = {...}
x=args[1]
y=args[2]
z=args[3]

if (path.gotoPos(x,y,z)==true) then print("I'm Here!")
else print("Got stuck")
end
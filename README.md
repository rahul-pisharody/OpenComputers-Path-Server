# OpenComputers-Path-Server
A server based robot pathfinding system created for the OpenComputers mod (Minecraft)

Server uses A* algorithm to find shortest path.
Requirements: Geolyzer(to fill the 3d map; adjust variables as needed), Hologram Tier 2 (remove code if visualization not needed) and lots of memory.

The location service for the robot inspired by Jomik's own location service. (They're quite similar, but override different functions)
Link to his repo: https://github.com/OpenPrograms/Jomik-Programs/tree/master/robot/services/location/

Location service needs to be enabled (<code>rc location enable</code>) for this to work. (Or just start it every time with <code>rc location start</code>)

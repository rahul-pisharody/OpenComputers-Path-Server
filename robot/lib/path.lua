local location = require("location")
local component = require("component")
local event = require("event")
local serial = require("serialization")

local modem = component.modem

local path={}

local rseq=0
local sseq=0

local path_server = "4607bbb5-fdb5-418c-b7f2-268e1c70646d"

local function updateSeq(seq)
  if (seq==1) then return 0 else return 1 end
end

  
local function stopConn()
  tries = 0
  while (tries<5) do
    modem.send(path_server,150,sseq,"closeConn")
    t,_,s,port,dist,seq,payload = event.pull(5,"modem_message")
    if (t==nil) then tries=tries+1
    elseif (s==path_server and seq==rseq and payload=="closeACK") then
      print("Connection Closed")
      modem.close(160)
      return 0
    end
  end
  print("Close not ACKnoledged")
  modem.close(160)
  return 1
end

local function startConn()
  rseq = 0
  modem.open(160)
  modem.send(path_server,150,rseq,"handshake1")
  while true do
    t,_,s,port,dist,seq,payload = event.pull(5,"modem_message")
    if (t==nil) then 
      print("Failed handshake")
      return false
      --stopConn() 
    end
    if (payload=="handshake2") then
      sseq=seq
     break
    end
  end
  while true do 
    modem.send(path_server,150,sseq,"handACK")
    t,_,s,port,dist,seq,payload = event.pull(5,"modem_message")
    if (t==nil) then print("ACK failed") stop() end
    if (payload=="handACK") then
      sseq = updateSeq(sseq)
      rseq = updateSeq(rseq)
      print("Connection established")
      break
    end
  end
  return true
end

function path.getPath(dest)
  if (not startConn()) then return nil end
  print("Sending "..sseq)
  local src = location.get()
  s_src = serial.serialize(src)
  s_dest = serial.serialize(dest)
  print("Wait for: "..rseq)
  tries=0
  while tries<5 do
    modem.broadcast(150,sseq,"getPath",s_src,s_dest)
    t,_,src,port,dist,seq,payload1,payload2 = event.pull(20,"modem_message")
    print(seq,rseq,payload1=="commandlist")
    if (t==nil) then tries=tries+1
    elseif (seq==rseq and payload1=="commandlist") then
      rseq=updateSeq(rseq)
      sseq=updateSeq(sseq)
      stopConn()
      return serial.unserialize(payload2)
    else print(seq,rseq,payload1)
    end
  end
  print("NO REPLY")
  stopConn()
  return nil
end
 

function path.gotoPos(x,y,z)
  t=path.getPath({x,y,z})
  print("THIS",t)
  if (t~=nil) then
    os.execute("/home/cmd_list_execute "..serial.serialize(t))
    currentPos = location.get()
    print(currentPos[1],currentPos[2],currentPos[3],x,y,z) 
    return (currentPos[1]==x and currentPos[2]==y and currentPos[3]==z)
  end
  return false
end

return path
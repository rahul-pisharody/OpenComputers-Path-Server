local geo = require("component").geolyzer
local holo = require("component").hologram
local modem = require("component").modem

local event = require("event")
local serial = require("serialization")

-------------------------MAP GENERATION---------------------------
local map3d = {}
local boundary = {20,20}

local function generateMap()
  for i=-(boundary[1]),boundary[1] do
    map3d[i] = {}
    for j=(-boundary[2]),boundary[2] do
      map3d[i][j] = geo.scan(i,j)
    end
  end
end

local function displayMap(map)
  holo.clear()
  holo.setTranslation(10,0.5,0)
  holo.setScale(2)
  for i=-20,20 do
    for j=-20,20 do
      for k=39,64 do
        color = 0
        if (map[i][j][k]~=0) then color = 2 end
        holo.set(24+i,k-38,24+j,color)
      end
    end
  end
end

-----------------------------PATHFINDING-------------------------------------

local function length(tab)
  local num = 0
  for k,v in ipairs(tab) do
    num = num+1
  end
  return num
end

local function search_and_delete(array,x)
  for i,v in ipairs(array) do
    if (v==x) then
      table.remove(array,i)
      break
    end
  end
end

local function pointEq(pt1,pt2)
  return (pt1[1]==pt2[1] and pt1[2]==pt2[2] and pt1[3]==pt2[3])
end

local function notIn(tab,x)
  for _,v in ipairs(tab) do
    if (pointEq(v,x)) then return false end
  end
  return true
end

local function manhattanDist(src,dest)
  return(math.abs(dest[1]-src[1])+math.abs(dest[2]-src[2])+math.abs(dest[3]-src[3]))
end

local function getBestMove(set,scores)
  local min,best_move = 1/0,nil
  for _,move in ipairs(set) do
    if (scores[move]<min) then
      min = scores[move]
      best_move = move
    end
  end
  return best_move
end

local function isValid(pt,map)
  return (pt[1]>=-(boundary[1]) and pt[1]<=boundary[1] and pt[3]>-(boundary[2]) and pt[3]<boundary[2] and map[pt[1]][pt[3]][pt[2]]==0) 
end

local function getNeighbours(src,map)
  local nb={}
  x=src[1] y=src[2] z = src[3]
  if (isValid({x+1,y,z},map)) then
    point = {x+1,y,z}
    table.insert(nb,point)
  end
  if (isValid({x-1,y,z},map)) then
    point = {x-1,y,z}
    table.insert(nb,point)
  end
  if (isValid({x,y,z+1},map)) then
    table.insert(nb,{x,y,z+1})
  end
  if (isValid({x,y,z-1},map)) then
    table.insert(nb,{x,y,z-1})
  end
  if (isValid({x,y+1,z},map)) then
    table.insert(nb,{x,y+1,z})
  end
  if (isValid({x,y-1,z},map)) then
    table.insert(nb,{x,y-1,z})
  end
  return nb
end

local function getPathTable(from_table,src,dest)
  path = {}
  pt = dest
  while(not pointEq(pt,src)) do
    table.insert(path,1,pt)
    pt = from_table[pt]
  end
  table.insert(path,1,src)
  return path
end

local function a_star(src,dest)
  if (not isValid(dest,map3d)) then
    map3d[dest[1]][dest[3]]=geo.scan(dest[1],dest[3])
    if (not isValid(dest,map3d)) then return {} end
  end
  local open_set = {src}
  local closed_set = {}
  local move_from={}

  local heuristicDist = manhattanDist

  local g_score, f_score = {}, {}
  g_score[src] = 0
  f_score[src] = g_score[src] + heuristicDist(src,dest)
  
  while (#open_set>0) do
    event.push("fake")
    event.pull()
    current=getBestMove(open_set,f_score)
    --holo.set(24+current[1],current[2]-38,24+current[3],1)
    if (pointEq(current,dest)) then
      path = getPathTable(move_from,src,current)
      return path
    end
    search_and_delete(open_set,current)
    table.insert(closed_set,current)
    for _,n in ipairs(getNeighbours(current,map3d)) do 
      if (notIn(closed_set,n)) then
        pot_g_score = g_score[current] + 1
        if (notIn(open_set,n)) then
          table.insert(open_set,n)
        end
        if (g_score[n]==nil or pot_g_score<g_score[n]) then
          move_from[n] = current
          g_score[n] = pot_g_score
          f_score[n] = g_score[n] + heuristicDist(n,dest)
        end
      end
    end
  end
  return {}
end

realMap={44,-61,-254}

-----------------------------Service------------------------------
local sseq,rseq = {},{}

local function updateSeq(seq)
  if (seq==0) then return 1 else return 0 end
end

local function messageHandler(_,_,src,port,dist,seq,payload1,payload2,payload3)
  if (rseq[src]==nil and payload1=="handshake1") then
    sseq[src]=seq
    rseq[src]=0
    modem.send(src,160,rseq[src],"handshake2")
    t,_,src,port,dist,seq,payload = event.pull(5,"modem_message")
    while (seq~=rseq[src] and payload=="handACK") do
      t,_,src,port,dist,seq,payload = event.pull(5,"modem_message")
      if (t==nil) then break end
    end
    if (t==nil) then
      rseq[src]=nil
      sseq[src]=nil
      return
    end
    modem.send(src,160,sseq[src],"handACK")
    rseq[src]=updateSeq(rseq[src])
    sseq[src]=updateSeq(sseq[src])
    return
  elseif (rseq[src]==nil) then return
  elseif (seq==rseq[src] and payload1=="getPath") then
    rseq[src] = updateSeq(rseq[src])
    source = serial.unserialize(payload2)
    dest = serial.unserialize(payload3)

    mapped_src = {source[1]+realMap[1],source[2]+realMap[2],source[3]+realMap[3]}
    mapped_dest = {dest[1]+realMap[1],dest[2]+realMap[2],dest[3]+realMap[3]}
    a_path = a_star(mapped_src,mapped_dest)
    for _,n in ipairs(a_path) do
      holo.set(n[1]+24,n[2]-38,n[3]+24,1)
    end
    s_path = serial.serialize(a_path)
    os.execute("/home/geolyzer_tests/path2cmds.lua "..s_path.." "..sseq[src])
    sseq[src] = updateSeq(sseq[src])
  elseif (seq==rseq[src] and payload1=="closeConn") then
    modem.send(src,160,sseq[src],"closeACK")
    sseq[src] = nil
    rseq[src] = nil
  end
end

function start(arg)
  sseq = {}
  rseq = {}
  generateMap()
  displayMap(map3d)
  modem.open(150)
  event.listen("modem_message",messageHandler)
end
function stop(arg)
  event.ignore("modem_message",messageHandler)
  modem.close(150)
end
function regenerateMap()
  generateMap()
  displayMap(map3d)
end
function disconnectAll()
  sseq={}
  rseq = {}
end

local function a_test(src,dest)
  generateMap()
  displayMap(map3d)
  mapped_src={src[1]+realMap[1],src[2]+realMap[2],src[3]+realMap[3]}
  mapped_dest={dest[1]+realMap[1],dest[2]+realMap[2],dest[3]+realMap[3]}
  apath = a_star(mapped_src,mapped_dest)
end

--a_test({-43,107,253},{-34,71,265})
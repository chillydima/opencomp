local comp = require("component")
local event = require("event")
local os = require("os")
local computer = require("computer")

local sleep = os.sleep
local me = comp.me_interface
local net = comp.modem
local files = comp.filesystem
local config = {}
local work = true
local debugmain = {}
local debugnet = {}
local deleter = ""
net.open(1)
net.open(2)
net.open(3)
local selector = 1
local startchar = 1

function tst(str)
  return tostring(str) .. " "
end

function handlekeys(_,_,_,char,_)
  if char == 200 then
    if selector == 1 and startchar > 0 then
      startchar = startchar-1
    end
    if selector > 1 then selector = selector - 1 end
  end
  if char == 208 then
    if selector == 10 and startchar < #config then
      startchar = startchar + 1
    end
    if selector < 10 then selector = selector + 1 end
  end
  if char == 211 then
    if deleter == "" then
      deleter = "<  really delete? press again to confirm"
    else
      deleter = ""
      remove(config, startchar + selector)
    end
  end
end

function checkcpus(item)
  for k,v in pairs(me.getCpus()) do
    local cpu = v.cpu
    if cpu.isBusy() then
      local fin = cpu.finalOutput()
      if fin then
        if fin.name == item[1] and fin.damage == item[2] and fin.label == item[3] then return true end
      end
    end
  end
  return false
end

function compound(items)
  local totalsize = 0
  for k,v in pairs(items) do
    totalsize = totalsize + v.size
  end
  return totalsize
end

function printm(str)
  local str = tostring(str)
  s, e = string.find(str, ": crafting")
  s1, e1 = string.find( str, ": requested")
  if e then
    local plain = string.gsub(str, ": crafting", " ")
    for k,v in pairs(debugmain) do
      local plain1 = string.gsub(v, ": requested", " ")
      if plain == plain1 then debugmain[k] = str return nil end
    end
  end
  if e1 then
    for k,v in pairs(debugmain) do
      if v == str then return nil end
    end
  end
  if #debugmain < 10 then
    debugmain[#debugmain + 1] = str
  else
    remove(debugmain, 1)
    debugmain[#debugmain + 1] = str
  end 
end

function printn(str)
  local str = tostring(str)
  if #debugnet < 10 then
    debugnet[#debugnet + 1] = str
  else
    remove(debugnet, 1)
    debugnet[#debugnet + 1] = str
  end
end

function visuals_update()
  if work then if work == true then
  os.execute("clear")
  print("===================network  debug===================")
  for k=1,10 do
    local v = debugnet[k]
    if v == nil then
      print(" ")
    else
      print(v)
    end
  end
  print("===================maintain debug===================")
  for k=1,10 do
    local v = debugmain[k]
    if v == nil then
      print(" ")
    else
    print(v)
    end
  end
  print("↑↓======================================del to delete")
  for k=1, 10 do
    local v = config[startchar + k]
    if v ~= nil then
    if selector == k then
      print(">" .. v[1] .. ":" .. v[2] .. " #" .. v[3] .. " batch: " .. v[4] .. " maintained amount: " .. v[5] .. " " ..  deleter)
    else
      print(" " .. v[1] .. ":" .. v[2] .. " #" .. v[3] .. " batch: " .. v[4] .. " maintained amount: " .. v[5])
    end
    else
      if selector ~= k then
        print("           *empty*")
      else
        print(">          *empty*")
      end
    end
  end
  end end
end

function remove(table, slot)
  for k = slot, #table-1 do
    if k == #table-1 then
      table[k] = table[#table]
      table[#table] = nil
      break
    else
      table[k] = table[k+1]
    end
  end  
end

function network_update(where, who, howtohow, port, _, arg1, arg2, arg3, arg4, arg5)
  printn(tst(where) .. tst(who) .. tst(howtohow) .. tst(port) .. tst(_)  .. tst(arg1) .. tst(arg2) .. tst(arg2) .. tst(arg3) .. tst(arg4) .. tst(arg5))
  if port then net.broadcast(1, "star walker") end
  if arg3 == "0" then arg3 = nil end
  if arg1 == "ae2fc:fluid_drop" then if string.find(arg3, "drop of") == nil then arg3 = "drop of "..arg3 end end
  local debug = ""
  local removed = false
  if port == 1 then
    local overwritten = false
    printn("addition request for " .. arg1 .. ":".. arg2 .. " with label ".. arg3 .. " crafting batch size: " .. arg4 .. " trigger: " .. arg5)
    for k,v in pairs(config) do
      if v[1] == arg1 and v[2] == tonumber(arg2) and v[3] == arg3 then
      config[k][4] = arg4
      config[k][5] = arg5
      overwritten = true
      debug = debug .. ": entry exists, reconfigured"
      end
    end
    if overwritten == false then
      config[#config + 1] = {arg1, tonumber(arg2), arg3, tonumber(arg4), tonumber(arg5)}
      debug = debug .. ": success"
    end
  else
    if port == 2 then
      printn("removal request for " .. arg1 .. ":" .. arg2 .. " with label " .. arg3)
      for k,v in pairs(config) do
        if v[1] == arg1 and v[2] == tonumber(arg2) and v[3] == arg3 then
          remove(config, k)
          debug = debug .. ": success"
          removed = true
        end 
      end
      if removed == false then debug = debug .. ": not found" end
    
    else if port == 3 then
      print("shutting down...")
      files.rename("/home/config", "/home/configold")
      files.remove("/home/config")
      local save = files.open("/home/config", "w")
      for k,v in pairs(config) do
        files.write(save, v[1]..","..v[2]..","..v[3]..","..v[4]..","..v[5]..",,")
      end
      event.cancel(vis)
      files.close(save)
      work = false
      end
    end
  end
  if debug ~= "" then
    printn(debug)
  end
end


if files.exists("/home/config") then
  file = files.open("/home/config",  "r")
  local tab = {}
  local count = 1
  local chunk = ""
  repeat
  a = files.read(file,1)
  if a == "," then
    if count < 6 then
      if count == 1 then chunk = string.gsub(chunk, "\n", "") end
      tab[count] = chunk
      print(chunk)
      chunk = ""
      count = count + 1
    else
      count = 1
      config[#config + 1] = tab
      tab = {}
      chunk = ""
    end
  else 
    if a ~= nil then
      chunk = chunk  .. a
    end
  end
  
  until a == nil
end

event.listen("modem_message", network_update)
event.listen("key_up", handlekeys)
vis = event.timer(5, visuals_update, math.huge)

while work do
  for k,v in pairs(config) do
    if compound(me.getItemsInNetwork({name = v[1], damage=v[2], label=v[3]})) < tonumber(v[5]) then
      local label = v[3]
      local debug = "running low on " .. v[1] .. ":" .. tostring(v[2]).. " named:"  .. tostring(label)
      
      craftables = me.getCraftables({name = v[1], damage = tonumber(v[2]), label = label})
      if #craftables > 0 then
        if checkcpus({v[1], v[2], v[3]}) == false then
          craftables[1].request(tonumber(v[4]))
          debug = debug.. ": requested"
        else
          debug = debug.. ": crafting"
        end
      else
        debug = debug.. ": no pattern!"
      end
      printm(debug)
    end
    sleep(1)
    
  end
  if #config == 0 then
    sleep(10)
  end
end
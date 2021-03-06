local Event = require 'utils.event'
local Global = require 'utils.global'

local util = require("util")
local silo_script = require("silo-script")

local global = {}
Global.register(global,function(tbl)
    global = tbl
end)

local created_items = function()
  return
  {
    ["iron-plate"] = 8,
    ["wood"] = 1,
    ["pistol"] = 1,
    ["firearm-magazine"] = 10,
    ["burner-mining-drill"] = 1,
    ["stone-furnace"] = 1
  }
end

local respawn_items = function()
  return
  {
    ["pistol"] = 1,
    ["firearm-magazine"] = 10
  }
end

for k,v in pairs(silo_script.get_events()) do
    Event.add(k, v)
end

Event.add(defines.events.on_player_created, function(event)
  local player = game.players[event.player_index]
  util.insert_safe(player, global.created_items)

  local r = global.chart_distance or 200
  player.force.chart(player.surface, {{player.position.x - r, player.position.y - r}, {player.position.x + r, player.position.y + r}})

  silo_script.on_event(event)
end)

Event.add(defines.events.on_player_respawned, function(event)
  local player = game.players[event.player_index]
  util.insert_safe(player, global.respawn_items)
  silo_script.on_event(event)
end)

Event.on_load(function()
  silo_script.on_load()
end)

Event.on_init(function()
  global.created_items = created_items()
  global.respawn_items = respawn_items()
  silo_script.on_init()
end)

silo_script.add_remote_interface()
silo_script.add_commands()

remote.add_interface("freeplay",
{
  get_created_items = function()
    return global.created_items
  end,
  set_created_items = function(map)
    global.created_items = map
  end,
  get_respawn_items = function()
    return global.respawn_items
  end,
  set_respawn_items = function(map)
    global.respawn_items = map
  end,
  set_skip_intro = function(bool)
    global.skip_intro = bool
  end,
  set_chart_distance = function(value)
    global.chart_distance = tonumber(value)
  end
})

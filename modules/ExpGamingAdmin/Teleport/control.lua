--- Desction <get from json>
-- @module ExpGamingAdmin.Jail@4.0.0
-- @author <get from json>
-- @license <get from json>
-- @alais ThisModule 

-- Module Require
local Admin = require('ExpGamingAdmin.AdminLib@^4.0.0')
local AdminGui = require('ExpGamingAdmin.Gui@^4.0.0')
local Game = require('FactorioStdLib.Game@^0.8.0')

-- Module Define
local module_verbose = false
local ThisModule = {}

-- Function Define
AdminGui.add_button('goto','utility/export_slot',{'ExpGamingAdmin.tooltip-go-to'},function(player,byPlayer)
    Admin.go_to(player,byPlayer)
end)
AdminGui.add_button('bring','utility/import_slot',{'ExpGamingAdmin.tooltip-bring'},function(player,byPlayer)
    Admin.bring(player,byPlayer)
end)

function Admin.tp(from_playaer, to_player)
    local _from_player = Game.get_player(from_player)
    local _to_player = Game.get_player(to_player)
    if not _from_player or not _to_player then return end
    _from_player.teleport(_to_player.surface.find_non_colliding_position('player',_to_player.position,32,1),_to_player.surface)
end

function Admin.go_to(player,by_player)
    Admin.tp(by_player, player)
end

function Admin.bring(player,by_player)
    Admin.tp(player, by_player)
end

Admin.add_action('Go To',Admin.go_to)
Admin.add_action('Bring',Admin.bring)

-- Module Return
return ThisModule 
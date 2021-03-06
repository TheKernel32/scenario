--- Adds a organiser for left gui elements which will automatically update there information and have open requirements
-- @module ExpGamingCore.Gui.Left
-- @alias left
-- @author Cooldude2606
-- @license https://github.com/explosivegaming/scenario/blob/master/LICENSE

--- This is a submodule of ExpGamingCore.Gui but for ldoc reasons it is under its own module
-- @function _comment
local Game = require('FactorioStdLib.Game')
local Server = require('ExpGamingCore.Server')
local Color = require('FactorioStdLib.Color')
local mod_gui = require('mod-gui')
local Gui = require('ExpGamingCore.Gui')
local order_config = require(module_path..'/order_config')
local Role -- this is optional and is handled by it being present, it is loaded on init

local left = {}
left._prototype = {}

left.hide = Gui.inputs{
    name='gui-left-hide',
    type='button',
    caption='<'
}:on_event('click',function(event)
    for _,child in pairs(event.element.parent.children) do
        if child.name ~= 'popups' then child.style.visible = false end
    end
end)

local global = {}
Global.register(global,function(tbl) global = tbl end)

-- used for debugging
function left.override_open(state)
    global.over_ride_left_can_open = state
end
--- Used to add a left gui frame
-- @usage Gui.left.add{name='foo',caption='Foo',tooltip='just testing',open_on_join=true,can_open=function,draw=function}
-- @usage return_value(player) -- toggles visibility for that player, if no player then updates for all players
-- @param obj this is what will be made, needs a name and a draw function(root_frame), open_on_join can be used to set the default state true/false, can_open is a test to block it from opening but is not needed
-- @return the object that is made, calling the returned value with out a param will update the gui, else will toggle visibility for that player
function left.add(obj)
    if not is_type(obj,'table') then return end
    if not is_type(obj.name,'string') then return end
    verbose('Created Left Gui: '..obj.name)
    setmetatable(obj,{__index=left._prototype,__call=function(self,player) if player then return self:toggle(player) else return left.update(self.name) end end})
    Gui.data('left',obj.name,obj)
    if Gui.toolbar then Gui.toolbar(obj.name,obj.caption,obj.tooltip,function(event) obj:toggle(event) end) end
    return obj
end

--- This is used to update all the guis of connected players, good idea to use our thread system as it as nested for loops
-- @usage Gui.left.update()
-- @tparam[opt] string frame this is the name of a frame if you only want to update one
-- @param[opt] players the player to update for, if not given all players are updated, can be one player
function left.update(frame,players)
    if not Server or not Server._thread then
        players = is_type(players,'table') and #players > 0 and {unpack(players)} or is_type(players,'table') and {players} or Game.get_player(players) and {Game.get_player(players)} or game.connected_players
        for _,player in pairs(players) do
            local frames = Gui.data.left or {}
            if frame then frames = {[frame]=frames[frame]} or {} end
            for _,left_frame in pairs(frames) do
                if left_frame then left_frame:first_open(player) end
            end
        end
    else
        local frames = Gui.data.left or {}
        if frame then frames = {[frame]=frames[frame]} or {} end
        players = is_type(players,'table') and #players > 0 and {unpack(players)} or is_type(players,'table') and {players} or Game.get_player(players) and {Game.get_player(players)} or game.connected_players
        Server.new_thread{
            data={players=players,frames=frames}
        }:on_event('tick',function(thread)
            if #thread.data.players == 0 then thread:close() return end
            local player = table.remove(thread.data.players,1)
            Server.new_thread{
                data={player=player,frames=thread.data.frames}
            }:on_event('resolve',function(thread)
                for _,left_frame in pairs(thread.data.frames) do
                    if left_frame then left_frame:first_open(thread.data.player) end
                end
            end):queue()
        end):open()
    end
end

--- Used to open the left gui of every player
-- @usage Gui.left.open('foo')
-- @tparam string left_name this is the gui that you want to open
-- @tparam[opt] LuaPlayer the player to open the gui for
function left.open(left_name,player)
    local players = player and {player} or game.connected_players
    local _left = Gui.data.left[left_name]
    if not _left then return end
    if not Server or not Server._thread then
        for _,next_player in pairs(players) do _left:open(next_player) end
    else
        Server.new_thread{
            data={players=players}
        }:on_event('tick',function(thread)
            if #thread.data.players == 0 then thread:close() return end
            local next_player = table.remove(thread.data.players,1)
            _left:open(next_player)
        end):open()
    end
end

--- Used to close the left gui of every player
-- @usage Gui.left.close('foo')
-- @tparam string left_name this is the gui that you want to close
-- @tparam[opt] LuaPlayer the player to close the gui for
function left.close(left_name,player)
    local players = player and {player} or game.connected_players
    local _left = Gui.data.left[left_name]
    if not _left then return end
    if not Server or not Server._thread or player then
        for _,next_player in pairs(players) do _left:close(next_player) end
    else
        Server.new_thread{
            data={players=players}
        }:on_event('tick',function(thread)
            if #thread.data.players == 0 then thread:close() return end
            local next_player = table.remove(thread.data.players,1)
            _left:close(next_player)
        end):open()
    end
end


--- Used to force the gui open for the player
-- @usage left:open(player)
-- @tparam luaPlayer player the player to open the gui for
function left._prototype:open(player)
    player = Game.get_player(player)
    if not player then error('Invalid Player') end
    local left_flow = mod_gui.get_frame_flow(player)
    if not left_flow[self.name] then self:first_open(player) end
    left_flow[self.name].style.visible = true
    if left_flow['gui-left-hide'] then left_flow['gui-left-hide'].style.visible = true end
end

--- Used to force the gui closed for the player
-- @usage left:open(player)
-- @tparam luaPlayer player the player to close the gui for
function left._prototype:close(player)
    player = Game.get_player(player)
    if not player then error('Invalid Player') end
    local left_flow = mod_gui.get_frame_flow(player)
    if not left_flow[self.name] then self:first_open(player) end
    left_flow[self.name].style.visible = false
    local count = 0
    for _,child in pairs(left_flow.children) do if child.style.visible then count = count+1 end if count > 1 then break end end
    if count == 1 and left_flow['gui-left-hide'] then left_flow['gui-left-hide'].style.visible = false end
end

--- When the gui is first made or is updated this function is called, used by the script
-- @usage left:first_open(player) -- returns the frame
-- @tparam LuaPlayer player the player to draw the gui for
-- @treturn LuaFrame the frame made/updated
function left._prototype:first_open(player)
    player = Game.get_player(player)
    local left_flow = mod_gui.get_frame_flow(player)
    local frame
    if left_flow[self.name] then
        frame = left_flow[self.name]
        frame.clear()
    else
        if not left_flow['gui-left-hide'] then left.hide(left_flow).style.maximal_width=15 end
        frame = left_flow.add{type='frame',name=self.name,style=mod_gui.frame_style,caption=self.caption,direction='vertical'}
        frame.style.visible = false
        if is_type(self.open_on_join,'boolean') then frame.style.visible = self.open_on_join left_flow['gui-left-hide'].style.visible = true end
    end
    if is_type(self.draw,'function') then self:draw(frame) else frame.style.visible = false error('No Callback On '..self.name) end
    return frame
end

--- Toggles the visibility of the gui based on some conditions
-- @usage left:toggle(player) -- returns new state
-- @tparam LuaPlayer player the player to toggle the gui for, remember there are condition which need to be met
-- @treturn boolean the new state that the gui is in
function left._prototype:toggle(player)
    player = Game.get_player(player)
    local left_flow = mod_gui.get_frame_flow(player)
    if not left_flow[self.name] then self:first_open(player) end
    local left_frame = left_flow[self.name]
    local open = false
    if is_type(self.can_open,'function') then
        local success, err = pcall(self.can_open,player)
        if not success then error(err)
        elseif err == true then open = true 
        elseif global.over_ride_left_can_open then 
            if is_type(Role,'table')  then
                if Role.allowed(player,self.name) then open = true
                else open = {'ExpGamingCore_Gui.unauthorized'} end
            else open = true end 
        else open = err end
    else
        if is_type(Role,'table')  then
            if Role.allowed(player,self.name) then open = true 
            else open = {'ExpGamingCore_Gui.unauthorized'} end
        else open = true end
    end
    if open == true and left_frame.style.visible ~= true then
        left_frame.style.visible = true
        left_flow['gui-left-hide'].style.visible = true
    else
        left_frame.style.visible = false
        local count = 0
        for _,child in pairs(left_flow.children) do if child.style.visible then count = count+1 end if count > 1 then break end end
        if count == 1 and left_flow['gui-left-hide'] then left_flow['gui-left-hide'].style.visible = false end
    end
    if open == false then player_return({'ExpGamingCore_Gui.cant-open-no-reason'},defines.textcolor.crit,player) player.play_sound{path='utility/cannot_build'} 
    elseif open ~= true then player_return({'ExpGamingCore_Gui.cant-open',open},defines.textcolor.crit,player) player.play_sound{path='utility/cannot_build'} end
    return left_frame.style.visible
end

Event.add(defines.events.on_player_joined_game,function(event)
    -- draws the left guis when a player first joins, fake_event is just because i am lazy
    local player = Game.get_player(event)
    local frames = Gui.data.left or {}
    local left_flow = mod_gui.get_frame_flow(player)
    if not left_flow['gui-left-hide'] then left.hide(left_flow).style.maximal_width=15 end
    local done = {}
    for _,name in pairs(order_config) do
        local left_frame = Gui.data.left[name]
        if left_frame then
            done[name] = true
            left_frame:first_open(player)
        end
    end
    for name,left_frame in pairs(frames) do
        if not done[name] then left_frame:first_open(player) end
    end
end)

Event.add(defines.events.on_tick,function(event)
    if ((event.tick+10)/(3600*game.speed)) % 15 == 0 then
		left.update()
    end
end)

function left.on_init()
    if loaded_modules['ExpGamingCore.Role'] then Role = require('ExpGamingCore.Role') end
end

-- calling will attempt to add a new gui
return setmetatable(left,{__call=function(self,...) return self.add(...) end})
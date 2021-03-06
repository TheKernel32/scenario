--- A full ranking system for factorio.
-- @module ExpGamingPlayer.playerList@4.0.0
-- @author Cooldude2606
-- @license https://github.com/explosivegaming/scenario/blob/master/LICENSE

local Game = require('FactorioStdLib.Game')
local Gui = require('ExpGamingCore.Gui')
local Admin -- ExpGamingAdmin@^4.0.0
local AdminGui -- ExpGamingAdmin.Gui@^4.0.0

-- Local Variables
local playerInfo = function(player,frame)
    frame.add{
        type='label',
        caption={'ExpGamingPlayer-playerList.no-info-file'}
    }
end

local getPlayers = function()
    local rtn = {{{r=233,g=63,b=233},'Admin',{},true},{{r=255,g=159,b=27},'',{},false}}
    for _,player in pairs(game.connected_players) do
        if player.admin then table.insert(rtn[2][3],player)
        else table.insert(rtn[1][3],player) end
    end
    return rtn
end

-- Module Define
local module_verbose = false
local ThisModule = {
    on_init=function(self)
        if loaded_modules['ExpGamingPlayer.playerInfo'] then playerInfo = require('ExpGamingPlayer.playerInfo') end
        if loaded_modules['ExpGamingCore.Role'] then getPlayers = require(module_path..'/src/ranking',{self=self}) end
        if loaded_modules['ExpGamingAdmin'] then Admin = require('ExpGamingAdmin') end
        if loaded_modules['ExpGamingAdmin.Gui'] then AdminGui = require('ExpGamingAdmin.Gui') end
    end
}

-- Global Define
local global = {
    update=0,
    delay=10,
    interval=54000
}
Global.register(global,function(tbl) global = tbl end)

function ThisModule.update(tick)
    local tick = is_type(tick,'table') and tick.tick or is_type(tick,'number') and tick or game.tick
    if tick + global.delay > global.update - global.interval then
        global.update = tick + global.delay
    end
end

local back_btn = Gui.inputs{
    type='button',
    caption='utility/enter',
    name='player-list-back'
}:on_event('click',function(event)
    event.element.parent.parent.scroll.style.visible = true
    event.element.parent.destroy()
end)

ThisModule.Gui = Gui.left{
    name='player-list',
    caption='entity/player',
    tooltip={'ExpGamingPlayer-playerList.tooltip'},
    draw=function(self,frame)
        frame.caption = ''
        local player_list = frame.add{
            name='scroll',
            type = 'scroll-pane',
            direction = 'vertical',
            vertical_scroll_policy='auto',
            horizontal_scroll_policy='never'
        }
        player_list.vertical_scroll_policy = 'auto'
        player_list.style.maximal_height=195
        local done = {}
        local players = getPlayers() -- list of [colour,shortHand,[playerOne,playerTwo]]
        for _,rank in pairs(players) do
            for _,player in pairs(rank[3]) do
                if not done[player.index] then
                    done[player.index] = true
                    local flow = player_list.add{type='flow'}
                    if rank[2] == '' then
                        flow.add{
                            type='label',
                            name=player.name,
                            style='caption_label',
                            caption={'ExpGamingPlayer-playerList.format-nil',tick_to_display_format(player.online_time),player.name}
                        }.style.font_color = rank[1]
                    else
                        flow.add{
                            type='label',
                            name=player.name,
                            style='caption_label',
                            caption={'ExpGamingPlayer-playerList.format',tick_to_display_format(player.online_time),player.name,rank[2]}
                        }.style.font_color = rank[1]
                    end
                    if Admin and Admin.report_btn then
                        if not rank[4] and player.index ~= frame.player_index then
                            local btn = Admin.report_btn(flow)
                            btn.style.height = 20
                            btn.style.width = 20
                        end
                    end
                end
            end
        end
    end,
    open_on_join=true
}

Event.add(defines.events.on_tick,function(event)
    if event.tick > global.update then
        ThisModule.Gui()
        global.update = event.tick + global.interval
    end
end)

Event.add(defines.events.on_gui_click,function(event)
    -- lots of checks for it being valid
    if event.element and event.element.valid 
    and event.element.parent and event.element.parent.parent and event.element.parent.parent.parent 
    and event.element.parent.parent.parent.name == 'player-list' then else return end
    -- must be a right click
    if event.button == defines.mouse_button_type.right then else return end
    local player_list = event.element.parent.parent.parent
    -- must be a valid player which is clicked
    if not Game.get_player(event.element.name) then return end
    -- hides the player list to show the info
    player_list.scroll.style.visible = false
    local flow = player_list.add{type='flow',direction='vertical'}
    back_btn:draw(flow)
    playerInfo(event.element.name,flow,true)
    if Game.get_player(event.element.name) and event.player_index == Game.get_player(event.element.name).index then return end
    if Admin and AdminGui and Admin.allowed(event.player_index) then AdminGui(flow).caption = event.element.name end
end)

Event.add(defines.events.on_player_joined_game,function() ThisModule.update() end)
Event.add(defines.events.on_player_left_game,function() ThisModule.update() end)

ThisModule.force_update = function() return ThisModule.Gui() end
-- when called it will queue an update to the player list
return setmetatable(ThisModule,{__call=function(self,...) self.update(...) end})
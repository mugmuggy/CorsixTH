--[[ Copyright (c) 2009 Peter "Corsix" Cawley

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. --]]

--! The mini game UI and game controller
class "UIMiniGame" (Window)

---@type UIMiniGame
local UIMiniGame = _G["UIMiniGame"]

function UIMiniGame:UIMiniGame(ui)
  self:Window()

  local app = ui.app

  self.ui = ui
  self.world = app.world
  
  -- these are just hacked into place here
  
  self.original_adviser_state = self.ui.app.config.adviser_disabled
  -- disable without saving to config permanently
  self.ui.app.config.adviser_disabled = true
  
  -- TODO: disable salary raise via another method as this will probably update config permanently
  self.original_debug_disable_salary_raise = self.world.debug_disable_salary_raise
  self.world.debug_disable_salary_raise = true
  
  -- need to disable staff mood icons and the staff dialog.. they can't be clickable
  local hospital = self.world:getLocalPlayerHospital()
  for _, staff in ipairs(hospital.staff) do
  end
  
  -- place our random litter everywhere... how many? one per tile?
  -- brute force get all tiles in plot
  local split_tiles = {}
  for intX = 1, 128 do
    for intY = 1, 128 do
	  -- part of hospital and passable tiles to get mostly the internal ones
	  if self.world:getHospital(intX, intY) and self.world.map.th:getCellFlags(intX, intY).buildable then
	    table.insert(split_tiles, {[1]=intX, [2]=intY})
	  end
	end
  end

  local tile_count = #split_tiles
  print('tile count', tile_count)
  -- this places 100 litter, need to check how much
  for i = 1,100 do
     -- Drop some litter!
	 local plot_tile_index = math.random(tile_count)
	 local x, y =  split_tiles[plot_tile_index][1], split_tiles[plot_tile_index][2]
	 -- table.remove
	 split_tiles[plot_tile_index] = split_tiles[tile_count]
	 split_tiles[tile_count] = nil
	 tile_count = tile_count - 1
	 
     local trash = math.random(1, 4)
     local litter = self.world:newObject("litter", x, y)
     litter:setLitterType(trash, math.random(0, 1))
  end
  

  
  self.on_top = false
  self.width = 640
  self.height = 48
  self:setDefaultPosition(0.5, -0.1)
  self.panel_sprites = app.gfx:loadSpriteTable("Data", "Panel04V", true) -- panel 04
  self.kills_font = app.gfx:loadFont("QData", "Font110V") -- score font is 110v
  self.date_font = app.gfx:loadFont("QData", "Font16V")
  self.white_font = app.gfx:loadFont("QData", "Font01V", 0, -2) -- need to find the black font for the floating kill numbers

  -- weapons will need to refer to sprite, position, sound, animation (for bomb)
  self.weapons = {"shotgun", "uzi", "bazooka", "bomb"} 
  self.current_weapon = "shotgun"

  self.rat_kills = 0
   -- need to work this out but is probably something like percentage of tiles in parcel with litter
  local litterness = self.world.map.th:getLitterFraction(1)
  print('litterness', litterness)
  self.litterness = litterness
  
  -- brute force ratholes as we're going to need rats to spawn
  local wanted_ratholes = math.round(self.litterness * 200)
  if #hospital.ratholes < wanted_ratholes then
  end
  
  self:addPanel( 10, 0, 0)
  self:addPanel( 11, 230, 0)
  self:addPanel( 12, 288, 0)
  self:addPanel( 13, 329, 0)
  self:addPanel( 14, 387, 0)
  self:addPanel( 15, 411, 0)

  self:registerKeyHandlers()
end

function UIMiniGame:registerKeyHandlers()
  local ui = self.ui
  local buttons = self.additional_buttons

--  ui:addKeyHandler("ingame_loadMenu", self, self.openLoad)  -- load saved game menu
--  ui:addKeyHandler("ingame_saveMenu", self, self.openSave)  -- load create save menu
--  ui:addKeyHandler("ingame_restartLevel", self, self.restart)  -- restart the level
--  ui:addKeyHandler("ingame_quitLevel", self, self.quit)  -- quit the game and return to main menu
--  ui:addKeyHandler("ingame_quickSave", self, self.quickSave)  -- quick save
--  ui:addKeyHandler("ingame_quickLoad", self, self.quickLoad)  -- load last quick save

  -- misc. keyhandlers
--  ui:addKeyHandler("ingame_jukebox", self, self.openJukebox)   -- jukebox
end

function UIMiniGame:openJukebox()
  self.ui:addWindow(UIJukebox(self.ui.app))
end

function UIMiniGame:openSave()
  self.ui:addWindow(UISaveGame(self.ui))
end

function UIMiniGame:openLoad()
  self.ui:addWindow(UILoadGame(self.ui, "game"))
end

function UIMiniGame:quickSave()
  self.ui.app:quickSave()
end

function UIMiniGame:quickLoad()
  self.ui.app:quickLoad()
end

function UIMiniGame:restart()
  -- restoring the stuff we modified
  self.ui.app.config.adviser_disabled = self.original_adviser_state
  self.world.debug_disable_salary_raise = self.original_debug_disable_salary_raise
  
  self.ui.app:restart()
end

function UIMiniGame:quit()
  -- restoring the stuff we modified
  self.ui.app.config.adviser_disabled = self.original_adviser_state
  self.world.debug_disable_salary_raise = self.original_debug_disable_salary_raise
  
  self.ui:quit()
end

function UIMiniGame:draw(canvas, x, y)
  Window.draw(self, canvas, x, y)

  -- draw rat kills
  x, y = x + self.x, y + self.y
  local off = 19 * 5
  if self.rat_kills > 0 then
    off = 19 * (5 - math.floor(math.log(self.rat_kills, 10)))
  end
  self.kills_font:draw(canvas, ("%i"):format(self.rat_kills), x + 72 + off, y + 14)
  
  -- draw weapon
  if self.current_weapon == "shotgun" then
    self.panel_sprites:draw(canvas, 16, x + 230, y + 12)
  elseif self.current_weapon == "uzi" then
    self.panel_sprites:draw(canvas, 18, x + 288, y + 12)
  elseif self.current_weapon == "bazooka" then
    self.panel_sprites:draw(canvas, 20, x + 329, y + 12)
  elseif self.current_weapon == "bomb" then
    self.panel_sprites:draw(canvas, 22, x + 387, y + 12)
  end  
  
  -- draw dirtiness meter
  -- litterness * 4
  local litterness_scale_factor = 32
  local litterness_scaled = self.litterness * litterness_scale_factor
  -- we need to clamp this value as we only want to draw a max of 4
  -- also if its 4 they blink
  local full_count = math.min(4, math.floor(litterness_scaled))
  -- if there is no timer, start one, else get the display state
  self.display_state = true
  if full_count == 4 then
    if self.display_state then
      for i= 1, full_count do
        self.panel_sprites:draw(canvas, 26, x + 431 + (24 * i), y + 12)
      end
    else
	end
  else
    -- draw full_count garbage bins
	for i= 1, full_count do
      self.panel_sprites:draw(canvas, 26, x + 431 + (24 * i), y + 12)
	end
	litterness_scaled = litterness_scaled - full_count
	if litterness_scaled > 0.67 then
	  self.panel_sprites:draw(canvas, 25, x + 431 + (24 * full_count) + 24, y + 12)
	elseif litterness_scaled > 0.33 then
	  self.panel_sprites:draw(canvas, 24, x + 431 + (24 * full_count) + 24, y + 12)
	end
  end
  
  

end

function UIMiniGame:setPosition(x, y)
  -- Lock to bottom of screen
  return Window.setPosition(self, x, -0.1)
end


function UIMiniGame:drawDynamicInfo(canvas, x, y)

end

function UIMiniGame:setDynamicInfo(info)

end

function UIMiniGame:onMouseMove(x, y, dx, dy)
--  local repaint = Window.onMouseMove(self, x, y, dx, dy)
--  if self:showAdditionalButtons(x, y) then
--    repaint = true
--  end
  return true
end



function UIMiniGame:hitTest(x, y, x_offset)
  return x >= (x_offset and x_offset or 0) and y >= 0 and x < self.width and y < self.height
end

--! Queue a fax notification message to appear.
--! The arguments specify a message, which is added to a FIFO queue, and will
-- appear on screen once there is space.
--!param type (string) The type of message, can be: "emergency", "epidemy", "personality", "information", "disease", "report" or "strike"
--!param message (table or number) If type == "strike", the amount of pay rise. Else a list of texts to display, including a "choices" table with choices. See below for structure.
--!param owner (humanoid or nil) Some messages are related to one staff or patient. Otherwise this is nil.
--!param timeout (number or nil) If given, the message will expire after that many world ticks and be removed.
--!param default_choice (number or nil) If given, the choice with this number will be executed on expiration of the message.
--!param callback (function or nil) If given, it will be called when the message is closed.
--! Structure of message (except strike):
-- message = {
--   { text = "first line of text", offset (integer, optional) }
--   { text = "second line of text", offset (integer, optional) }
--   ...
--   choices = {
--     { text = "first choice", choice = "choice_type", enabled = true or false (optional, defaults to true) }
--     ...
--   }
-- }
function UIMiniGame:queueMessage(type, message, owner, timeout, default_choice, callback)

end

--[[ A fax can be queued if the event the fax causes does not affect
an event caused by any other fax that is queued. i.e both emergency
and epidemics use the timer, so both faxes cannot appear at the same time.
@param fax (table) the fax we want to determine if can be queued.
@return true if fax can be queued, false otherwise (boolean) ]]
function UIMiniGame:canQueueFax(fax)
  return false
end

--[[ Cancels a fax of a particular type currently only "emergency" and "epidemy"
Handles the cancelling of the event which the fax pertains to.
@param fax_type (string) type of fax event to be cancelled]]
function UIMiniGame:cancelFax(fax_type)

end

-- Opens the last available message. Currently used to open the level completed message.
function UIMiniGame:openLastMessage()

end

--! Trigger a message to be moved from the queue into a actual window, after
-- first performing the necessary animation.
function UIMiniGame:showMessage()

end

-- Opens the first available message in the list of message_windows.
function UIMiniGame:openFirstMessage()

end

-- Removes a message from the message queue (for example if a room is built before the player
-- says what to do with the patient.
function UIMiniGame:removeMessage(owner)
  return false
end

--! Pop the message with the given index from the message queue and turn it into an actual
-- message window; if no index is provided the first message in the queue is popped.
function UIMiniGame:createMessageWindow(index)
end

function UIMiniGame:onTick()
  Window.onTick(self)
  
  local litterness = self.world.map.th:getLitterFraction(1)
  self.litterness = litterness
end


function UIMiniGame:toggleInformation()
  self.world:toggleInformation()
end

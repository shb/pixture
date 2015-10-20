--
-- Player skins mod
-- By Kaadmy, for Pixture
--

player_skins = {}

player_skins.skin_names = {"male", "female"}
if minetest.setting_get("player_skins_names") then
   player_skins.skin_names = util.split(minetest.setting_get("player_skins_names"), ",")
end

player_skins.old_skins = {}
player_skins.skins = {}

local update_time = 1
local timer = 10
local skins_file = minetest.get_worldpath() .. "/player_skins"

local function save_skins()
   local f = io.open(skins_file, "w")

   for name, tex in pairs(player_skins.skins) do
      f:write(name .. " " .. tex .. "\n")
   end

   io.close(f)
end

local function load_skins()
   local f = io.open(skins_file, "r")

   if f then
      repeat
	 local l = f:read("*l")
	 if l == nil then break end

	 for name, tex in string.gfind(l, "(.+) (.+)") do
	    player_skins.skins[name] = tex
	 end
      until f:read(0) == nil

      io.close(f)
   else
      save_skins()
   end
end

local function is_valid_skin(tex)
   for _, n in pairs(player_skins.skin_names) do
      if n == tex then
	 return true
      end
   end

   return false
end

function player_skins.get_skin(name)
   return "player_skins_" .. player_skins.skins[name] .. ".png"
end
 
function player_skins.set_skin(name, tex)
   if minetest.check_player_privs(name, {player_skin = true}) then
      if is_valid_skin(tex) then
	 player_skins.skins[name] = tex
	 save_skins()
      else
	 minetest.chat_send_player(name, "Invalid skin")
      end
   else
      minetest.chat_send_player(name, "You do not have the privilege to change your skin.")
   end
end

local function step(dtime)
   timer = timer + dtime
   if timer > update_time then
      for _, player in pairs(minetest.get_connected_players()) do
	 local name = player:get_player_name()

	 if player_skins.skins[name] ~= player_skins.old_skins[name] then
	    default.player_set_textures(player, {"player_skins_" .. player_skins.skins[name] .. ".png"})
	    player_skins.old_skins[name] = player_skins.skins[name]
	 end
      end
      timer = 0
   end
end

local function on_joinplayer(player)
   local name = player:get_player_name()

   if player_skins.skins[name] == nil then
      player_skins.skins[name] = "male"
   end
end

minetest.register_globalstep(step)
minetest.register_on_joinplayer(on_joinplayer)

local function get_chatparams()
   local s = "["

   for _, n in pairs(player_skins.skin_names) do
      if s == "[" then
	 s = s .. n
      else
	 s = s .. "|" .. n
      end
   end

   return s .. "]"
end

minetest.register_privilege("player_skin", "Can change player skin")
minetest.register_chatcommand(
   "player_skin",
   {
      params = get_chatparams(),
      description = "Set your player skin",
      privs = {player_skin = true},
      func = function(name, param)
		if is_valid_skin(param) then
		   player_skins.set_skin(name, param)
		elseif param == "" then
		   minetest.chat_send_player(name, "Current player skin: " .. player_skins.skins[name])		   
		else
		   minetest.chat_send_player(name, "Bad param for /player_skin; type /help player_skin")
		end
	     end
   })

minetest.after(1.0, load_skins)

default.log("mod:player_skins", "loaded")
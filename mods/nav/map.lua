-- Map handling

nav.map_radius = 256

nav.waypoints = {}

local form_nav = default.ui.get_page("core")
default.ui.register_page("nav:nav", form_nav)

local open_formspecs = {}

local timer = 10
local update_time = 0.2

function nav.add_waypoint(pos, name, label, isinfo, type)
   nav.waypoints[name] = {pos = pos, label = label, isinfo = isinfo or false, type = type}
end

function nav.remove_waypoint(name)
   nav.waypoints[name] = nil
end

function nav.relocate_waypoint(name, pos)
   nav.waypoints[name].pos = pos
end

function nav.get_waypoints_in_square(pos, radius)
   local wpts = {}

   for name, data in pairs(nav.waypoints) do
      local wp = data.pos
      
      if wp.x > pos.x-radius and wp.x < pos.x+radius and  wp.z > pos.z-radius and wp.z < pos.z+radius then
	 table.insert(wpts, name)
      end
   end

   return wpts
end

local function get_formspec_waypoint(x, y, name, label, isinfo)
   local img = "nav_waypoint.png"
   if isinfo then
      img = "nav_info.png"
   end

   local form = ""
   
   form = form .. "image_button["..(x-0.72)..","..(y-0.53)..";0.5,0.5;"..img..";"..name..";;false;false;"..img.."]"
   form = form .. "tooltip["..name..";"..minetest.formspec_escape(label).."]"

   return form
end

function nav.show_map(player)
   if player == nil then return end

   local name = player:get_player_name()

   if not open_formspecs[name] then return end

   local pos = player:getpos()

   local form = default.ui.get_page("nav:nav")

   form = form .. "field[-1,-1;0,0;nav_map_tracker;;]"

   form = form .. "label[0.25,0.25;"..minetest.formspec_escape(name).." (x: "..math.floor(pos.x+0.5)..", y: "..math.floor(pos.y)..", z: "..math.floor(pos.z+0.5)..")]"

   form = form .. "image[0.5,3;6,6;nav_background.png]"

   local wpts = nav.get_waypoints_in_square(pos, nav.map_radius)
   for _, wptname in pairs(wpts) do
      local wpt = nav.waypoints[wptname]

      form = form .. get_formspec_waypoint(
	 3.5+(((wpt.pos.x-pos.x)/nav.map_radius)*3),
	 6+(((pos.z-wpt.pos.z)/nav.map_radius)*3),
	 wptname,
	 wpt.label,
	 wpt.isinfo)
   end

   form = form .. "image[5.5,3;1,1;nav_map_compass.png]"

   form = form .. "label[6.25,6.6;"..nav.map_radius.."m]"
   form = form .. "image[5.5,5.5;3,3;"..minetest.formspec_escape("nav_legend.png^[transformFX").."]"

   minetest.show_formspec(name, "nav:map", form)
end

local function recieve_fields(player, form_name, fields)
   if form_name == "nav:map" then
      if fields.quit or fields.nav_map_tracker then
	 open_formspecs[player:get_player_name()] = false
      end
   end
end

if minetest.setting_get_pos("static_spawnpoint") and (not minetest.is_singleplayer()) then
   minetest.after(
      1.0,
      function()
	 nav.add_waypoint(minetest.setting_get_pos("static_spawnpoint"),
			  "spawn", "Spawn", true, "spawn")
      end)
end

local function on_joinplayer(player)
   local name = player:get_player_name()

   minetest.after(
      1.0,
      function()
	 nav.add_waypoint(player:getpos(), "player_"..name, name, true, "player")
      end)
end

local function on_leaveplayer(player)
   local name = player:get_player_name()

   nav.remove_waypoint("player_"..name)
end

local function step(dtime)
   timer = timer + dtime

   if timer > update_time then
      local players = {}

      for _, player in pairs(minetest.get_connected_players()) do
	 if player ~= nil then
	    local name = player:get_player_name()
	    
	    players[name] = player
	    
	    nav.show_map(player)
	 end
      end

      for wptname, wpt in pairs(nav.waypoints) do
	 if wpt.type == "player" then
	    if players[wpt.label] ~= nil and minetest.get_player_by_name(wpt.label) ~= nil then
	       nav.relocate_waypoint(wptname, players[wpt.label]:getpos())
	    end
	 end
      end

      timer = 0
   end
end

minetest.register_craftitem(
   "nav:map",
   {
      description = "Map",
      inventory_image = "nav_inventory.png",
      wield_image = "nav_inventory.png",
      stack_max = 1,
      on_use = function(itemstack, player, pointed_thing)
		  open_formspecs[player:get_player_name()] = true
		  nav.show_map(player)
	       end,
   })

minetest.register_craft(
   {
      output = "nav:map",
      recipe = {
	 {"default:stick", "default:stick", "default:stick"},
	 {"default:paper", "default:paper", "default:paper"},
	 {"default:stick", "default:stick", "default:stick"},
      }
   })


minetest.register_on_joinplayer(on_joinplayer)
minetest.register_on_leaveplayer(on_leaveplayer)
minetest.register_globalstep(step)
minetest.register_on_player_receive_fields(recieve_fields)

-- Achievements

achievements.register_achievement(
   "navigator",
   {
      title = "Navigator",
      description = "Craft a map",
      times = 1,
      craftitem = "nav:map",
   })
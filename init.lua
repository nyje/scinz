--  "scinz" (c) Nigel Garnett 2020 (GPLv3)
--
--	contains code from:
--		"Unified Skins for Minetest" (GPLv3) and "skinsdb" ()
--			by
--		cornernote, Dean Montgomery, MirceaKitsune, Zeg9, Krock, bell07
--

scinz = {}



scinz.modpath = minetest.get_modpath("scinz")
scinz.file = minetest.get_worldpath().."/scinz.mt"
scinz.default = "Sam_0.png"
scinz.pages = {}
scinz.list = {}
scinz.meta = {}
scinz.scinz = {}
scinz.file_save = false

local function get_preview(texture, format)
	local player_skin = "("..texture..")"
	local skin = ""
	-- Consistent on both sizes:
	--Chest
	skin = skin .. "([combine:16x32:-16,-12=" .. player_skin .. "^[mask:skindb_mask_chest.png)^"
	--Head
	skin = skin .. "([combine:16x32:-4,-8=" .. player_skin .. "^[mask:skindb_mask_head.png)^"
	--Hat
	skin = skin .. "([combine:16x32:-36,-8=" .. player_skin .. "^[mask:skindb_mask_head.png)^"
	--Right Arm
	skin = skin .. "([combine:16x32:-44,-12=" .. player_skin .. "^[mask:skindb_mask_rarm.png)^"
	--Right Leg
	skin = skin .. "([combine:16x32:0,0=" .. player_skin .. "^[mask:skindb_mask_rleg.png)^"
	-- 64x skins have non-mirrored arms and legs
	local left_arm
	local left_leg
	if format == "1.8" then
		left_arm = "([combine:16x32:-24,-44=" .. player_skin .. "^[mask:(skindb_mask_rarm.png^[transformFX))^"
		left_leg = "([combine:16x32:-12,-32=" .. player_skin .. "^[mask:(skindb_mask_rleg.png^[transformFX))^"
	else
		left_arm = "([combine:16x32:-44,-12=" .. player_skin .. "^[mask:skindb_mask_rarm.png^[transformFX)^"
		left_leg = "([combine:16x32:0,0=" .. player_skin .. "^[mask:skindb_mask_rleg.png^[transformFX)^"
	end
	-- Left Arm
	skin = skin .. left_arm
	--Left Leg
	skin = skin .. left_leg
	-- Add overlays for 64x skins. these wont appear if skin is 32x because it will be cropped out
	--Chest Overlay
	skin = skin .. "([combine:16x32:-16,-28=" .. player_skin .. "^[mask:skindb_mask_chest.png)^"
	--Right Arm Overlay
	skin = skin .. "([combine:16x32:-44,-28=" .. player_skin .. "^[mask:skindb_mask_rarm.png)^"
	--Right Leg Overlay
	skin = skin .. "([combine:16x32:0,-16=" .. player_skin .. "^[mask:skindb_mask_rleg.png)^"
	--Left Arm Overlay
	skin = skin .. "([combine:16x32:-40,-44=" .. player_skin .. "^[mask:(skindb_mask_rarm.png^[transformFX))^"
	--Left Leg Overlay
	skin = skin .. "([combine:16x32:4,-32=" .. player_skin .. "^[mask:(skindb_mask_rleg.png^[transformFX))"
	-- Full Preview
	skin = "(((" .. skin .. ")^[resize:64x128)^[mask:skindb_transform.png)"
	return minetest.formspec_escape(skin)
end

scinz.is_skin = function(texture)
	if not texture then
		return false
	end
	if not scinz.meta[texture] then
		return false
	end
	return true
end

local file = io.open(scinz.modpath.."/scinzList.txt", "r")
if file then
	local lines = string.split(file:read("*all"), "\n")
	file:close()
	for i = 1,#lines do
		local parts = string.split(lines[i],":")
		local name = parts[1]
		scinz.list[i] = name
		scinz.meta[name] = {}
		scinz.meta[name].name = parts[5]
		scinz.meta[name].author = parts[4]
		scinz.meta[name].license = parts[2]
		scinz.meta[name].race = parts[3]
	end
end

scinz.load_players = function()
	local file = io.open(scinz.file, "r")
	if file then
		for line in file:lines() do
			local data = string.split(line, " ", 2)
			scinz.scinz[data[1]] = data[2]
		end
		io.close(file)
	end
end
scinz.load_players()

local ttime = 0
minetest.register_globalstep(function(t)
	ttime = ttime + t
	if ttime < 360 then --every 6min'
		return
	end
	ttime = 0
	scinz.save()
end)

minetest.register_on_shutdown(function() scinz.save() end)

scinz.save = function()
	if not scinz.file_save then
		return
	end
	scinz.file_save = false
	local output = io.open(scinz.file, "w")
	for name, skin in pairs(scinz.scinz) do
		if name and skin then
			if skin ~= scinz.default then
				output:write(name.." "..skin.."\n")
			end
		end
	end
	io.close(output)
end

scinz.update_player_skin = function(player)
	local name = player:get_player_name()
	if not scinz.is_skin(scinz.scinz[name]) then
		scinz.scinz[name] = scinz.default
	end
	player:set_properties({
		textures = {scinz.scinz[name]},
	})
end

-- Display Current Skin
unified_inventory.register_page("scinz", {
	get_formspec = function(player)
		local name = player:get_player_name()
		if not scinz.is_skin(scinz.scinz[name]) then
			scinz.scinz[name] = scinz.default
		end

		local formspec = ("background[0.06,0.99;7.92,7.52;ui_misc_form.png]"
			.."image[0,.75;1,2;"..get_preview(scinz.scinz[name]).."]"
			.."label[6,.5;Raw texture:]"
			.."image[6,1;2,1;"..scinz.scinz[name].."]")

		local meta = scinz.meta[scinz.scinz[name]]
		if meta then
			if meta.name ~= "" then
				formspec = formspec.."label[2,.5;Name: "..minetest.formspec_escape(meta.name).."]"
			end
			if meta.author ~= "" then
				formspec = formspec.."label[2,1;Author: "..minetest.formspec_escape(meta.author).."]"
			end
			if meta.license ~= "" then
				formspec = formspec.."label[2,1.5;License: "..minetest.formspec_escape(meta.license).."]"
			end
			if meta.race ~= "" then
				formspec = formspec.."label[2,2;Race: "..minetest.formspec_escape(meta.race).."]"
			end
		end
		local page = 0
		if scinz.pages[name] then
			page = scinz.pages[name]
		end
		formspec = formspec .. "button[.75,3;6.5,.5;scinz_page$"..page..";Change]"
		return {formspec=formspec}
	end,
})

unified_inventory.register_button("scinz", {
	type = "image",
	image = "scinz_button.png",
})

-- Create all of the skin-picker pages.

scinz.generate_pages = function(texture)
	local page = 0
	local pages = {}
	for i, skin in ipairs(scinz.list) do
		local p_index = (i - 1) % 16
		if p_index == 0 then
			page = page + 1
			pages[page] = {}
		end
		pages[page][p_index + 1] = {i, skin}
	end
	local total_pages = page
	print("scinz - Loaded "..total_pages.." pages")
	page = 1
	for page, arr in ipairs(pages) do
		local formspec = "background[0.06,0.99;7.92,7.52;ui_misc_form.png]"
		local y = -0.1
		for i, skin in ipairs(arr) do
			local x = (i - 1) % 8
			if i > 1 and x == 0 then
				y = 1.8
			end
			formspec = (formspec.."image_button["..x..","..y..";1,2;"..
				get_preview(skin[2])..";scinz_set$"..skin[1]..";]"..
				"tooltip[scinz_set$"..skin[1]..";"..
				scinz.meta[skin[2]].name.."\n( "..
				scinz.meta[skin[2]].race:sub(1,1):upper()..
				scinz.meta[skin[2]].race:sub(2).." )]")
		end
		local page_prev = page - 2
		local page_next = page
		if page_prev < 0 then
			page_prev = total_pages - 1
		end
		if page_next >= total_pages then
			page_next = 0
		end
		formspec = (formspec
			.."button[0,3.8;1,.5;scinz_page$"..page_prev..";<<]"
			.."button[.75,3.8;6.5,.5;scinz_null;Page "..page.."/"..total_pages.."]"
			.."button[7,3.8;1,.5;scinz_page$"..page_next..";>>]")

		unified_inventory.register_page("scinz_page$"..(page - 1), {
			get_formspec = function(player)
				return {formspec=formspec}
			end
		})
	end
end

-- click button handlers
minetest.register_on_player_receive_fields(function(player, formname, fields)
	if fields.scinz then
		unified_inventory.set_inventory_formspec(player, "craft")
		return
	end
	for field, _ in pairs(fields) do
		local current = string.split(field, "$", 2)
		if current[1] == "scinz_set" then
			scinz.scinz[player:get_player_name()] = scinz.list[tonumber(current[2])]
			scinz.update_player_skin(player)
			scinz.file_save = true
			unified_inventory.set_inventory_formspec(player, "scinz")
		elseif current[1] == "scinz_page" then
			scinz.pages[player:get_player_name()] = current[2]
			unified_inventory.set_inventory_formspec(player, "scinz_page$"..current[2])
		end
	end
end)

-- Change skin on join - reset if invalid
minetest.register_on_joinplayer(function(player)
	local player_name = player:get_player_name()
	if not scinz.is_skin(scinz.scinz[player_name]) then
		scinz.scinz[player_name] = scinz.default
	end
	scinz.update_player_skin(player)
	local pos = player:get_pos()
	pos.y = pos.y +1.5
	player:set_pos(pos)
end)

scinz.generate_pages()



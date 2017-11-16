local libmthelpers = modns.get("com.github.thetaepsilon.minetest.libmthelpers")
local newset = libmthelpers.datastructs.new.tableset

local prefix = "[libmt_wield_hooks] "
local logger = function(msg)
	print(prefix..msg)
end
local warning = function(msg)
	minetest.log("warning", prefix..msg)
end

-- callbacks that may be declared by registering mods.
local kc_vanished = "on_player_vanished"
local kc_wield_start = "on_wield_start"
local kc_wield_stop = "on_wield_stop"
local kc_wield_hold = "on_hold"



local atime = 0
-- might need to be configurable later...
local atime_min = 0.3

local registry = {}
local oldwielded = {}

local invoke_if_present = function(maybefunc, ...)
	if type(maybefunc) == "function" then
		return maybefunc(...)
	end
end
local callback = function(tbl, key, ...)
	if type(tbl) == "table" then
		return invoke_if_present(tbl[key], ...)
	end
end

-- callback to clean up a player's entries and notify callbacks that the player vanished.
-- allows callbacks for the last held item to arrange clean-up of any lingering world effects etc.
local cleanup = function(playerref)
	local olditem = oldwielded[playerref]
	oldwielded[playerref] = nil
	callback(registry[olditem], kc_vanished, playerref)
end

local process = function()
	local currentplayers = minetest.get_connected_players()

	for _, player in ipairs(currentplayers) do
		local olditem = oldwielded[player]
		local itemstack = player:get_wielded_item()
		local currentitem = itemstack:get_name()
		local currentreg = registry[currentitem]

		local cstart = function() callback(currentreg, kc_wield_start, player, itemstack) end
		if olditem ~= nil then
			if olditem ~= currentitem then
				callback(registry[olditem], kc_wield_stop, player)
				cstart()
			end	-- no else: if holding the same item don't do anything
		else
			-- if olditem was nil then this player is new, they haven't held anything before.
			cstart()
		end
		-- invoke continuous fire callbacks
		callback(currentreg, kc_wield_hold, player, itemstack)

		-- record what player was holding for next run
		oldwielded[player] = currentitem
	end
end



local step = function(dtime)
	local total = atime + dtime
	if total < atime_min then
		atime = total
	else
		atime = 0
		process()
	end
end

minetest.register_globalstep(step)

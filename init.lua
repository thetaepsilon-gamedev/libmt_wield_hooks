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
	callback(registry[olditem], kc_vanished, playerref, olditem)
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
				callback(registry[olditem], kc_wield_stop, player, olditem)
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



-- registration functions.
local interface = {}
wieldhooks = interface

-- check that passed callback tables are either nil or functions for the expected keys.
local copy_callback = function(source, target, key)
	local v = source[key]
	local t = type(v)
	if not ((t == "function") or (t == "nil")) then
		error("callback "..key.." expected to be a function or not set, got "..t)
	end
	target[key] = v
end
local validate_callbacks = function(source)
	local result = {}
	local c = function(k) copy_callback(source, result, k) end
	c(kc_vanished)
	c(kc_wield_start)
	c(kc_wield_stop)
	c(kc_wield_hold)
	return result
end

-- register a callback set for a given item.
-- currently, only one per item is supported.
-- TODO: implement handling of multiple callback sets
local register_wield_hooks = function(itemname, set)
	local dname = "register_wield_hooks() "
	if type(itemname) ~= "string" then error(dname.."item name must be a string!") end
	local reg = validate_callbacks(set)
	if registry[itemname] ~= nil then error(dname.."duplicate registration for item "..itemname) end
	registry[itemname] = reg
end
interface.register_wield_hooks = register_wield_hooks



-- too lazy to type extra chars...
local n = function(ref) return ref:get_player_name() end
local describe = function(itemstack) return itemstack:get_name().." with "..itemstack:get_count().." in stack" end

-- debugging helper for local use; do not use in released mods!
-- registers callbacks that print messages to console for tracking the code's behaviour.
local make_debug_hooks = function(print)
	local hooks = {}
	hooks.on_player_vanished = function(player, itemname)
		print(n(player).." vanished while holding "..itemname)
	end
	hooks.on_wield_start = function(player, itemstack)
		print(n(player).." pulled out "..describe(itemstack))
	end
	hooks.on_hold = function(player, itemstack)
		print(n(player).." is holding "..describe(itemstack))
	end
	hooks.on_wield_stop = function(player, itemname)
		print(n(player).." stopped wielding "..itemname)
	end
	return hooks
end

local debug_hook = function(regitem, print)
	return register_wield_hooks(regitem, make_debug_hooks(print))
end
local printer = print
local debug_hook_console = function(itemname) return debug_hook(itemname, printer) end
interface.debug_hook = debug_hook
interface.debug_hook_console = debug_hook_console

## libmt\_wield\_hooks: register callbacks when a player switches to items

This mod adds a mechanism by which other mods can register callbacks called on player item switch.
A globalstep is registered which, at intervals, polls the wielded item stacks of all connected players.
Whenever a player is detected to have changed items,
or is current holding an item with a continuous-fire callback,
registered callbacks are invoked. simples.

## Documentation
Please see the comment block near the top of init.lua for the supported callbacks.
Any of the on\_* callbacks may be set in a table,
then pass an item name and that callbacks table to
wieldhooks.register\_wield\_hooks.

## Caveats
* Held items are not checked every globalstep invocation.
	The default interval value (search for "local atime_min" in init.lua)
	is intended to be reasonably frequent to support updating the position of a walking player as they move around,
	without causing the server unreasonable burden.
	If your mod absolutely needs faster than this, consider implementing a separate globalstep.
* This mod does not do detection of switching hotbar slots.
	While there is get\_wield\_index() for player objects,
	in general there is no fool-proof generic way to detect when e.g.
	an item is moved around inside the inventory and swaps places with a hotbar slot
	(handles to ItemStacks are not the same for the same slot between invocations).
	Therefore this mod only looks at the item name and does not in itself distinguish instances of the same name.
	If you really need to distinguish between two instances of an item
	(e.g. if they have metadata/durability attached),
	you should probably use a continuous fire callback to inspect the currently held item.

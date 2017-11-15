## libmt\_wield\_hooks: register callbacks when a player switches to items

This mod adds a mechanism by which other mods can register callbacks called on player item switch.
A globalstep is registered which, at intervals, polls the wielded item stacks of all connected players.
Whenever a player is detected to have changed items, registered callbacks are invoked. simples.

API documentation Coming Soon.

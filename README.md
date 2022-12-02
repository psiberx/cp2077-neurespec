# Neu-Re-Spec

Neu-Re-Spec is a mod that allows you to respec your character at any moment. 

- **Restore attribute points** from selected attributes or reset all attributes at once
- **Restore perk points** from selected attributes or reset all perks at once
- **Adjust skill levels** to match new build or **keep gained experience**

## Requirements

- [Cyber Engine Tweaks](https://github.com/yamashi/CyberEngineTweaks) 1.21
- Cyberpunk 2077 1.61

## Installation

1. Download [the release archive](https://github.com/psiberx/cp2077-neurespec/releases). 
2. Extract it into the Cyberpunk 2077 installation folder.

You should have `<Cyberpunk 2077>/bin/x64/plugins/cyber_engine_tweaks/mods/NeureSpec` directory now. 

## Usage

Neu-Re-Spec integrates into the *Hub* menu.
You can access new functions in the *Hub > Character* section.

To manage individual stats, follow button hints in the bottom right corner and in the tooltip popups.

### Attributes

When an attribute is hovered and is not at the minimum level (3), a new *Return* action is available,
which downgrades attribute one level and restores one attribute point.
It's bound to the same key used to disassemble items (default is `Z` for keyboard input).

When an attribute is downgraded, perks that no longer meet the requirements will be reset, 
and the corresponding perk points will be restored.

On the other hand, skills are never lowered to match the new attribute level. 
You can keep gained skill levels even if the new attribute level is lower.

### Perks

Same as for attributes, when a perk is hovered and is not at zero level, a new *Return* action is available,
which downgrades perk one level and restores one perk point.
It's bound to the same key used to disassemble items (default is `Z` for keyboard input).

### Skills

You can adjust the skills to any level, up to the maximum level you've ever gotten in the current playthrough. 
When a skill level is hovered and is available, a new *Select* action will appear in the button hints. 
It's bound to the same key used to buy perk (default is `F` for keyboard input).

When skill level is lowered all the bonuses from corresponding levels are canceled, including perk points.
It's possible to get negative perk points if you have no unspent perk points, 
and you cancel the level that gives perk points.

### Full Reset

Two new buttons added to the *Character* screen:

- *Reset Perks* &mdash; Restore all your perk points as with *TABULA E-RASA* item.
- *Reset Attributes* &mdash; Restore all your attribute points.

## Translations

This mod has multilingual support. 
Contact me if you would like to see the mod in your language and would like to participate. 
At the moment, there are not so many texts to translate. 
Check the [english translation](https://github.com/psiberx/cp2077-neurespec/blob/master/data/lang/en-us.lua) file to get them. 

## Future Plans

- An immersive version in which you have to meet the stats requirements and buy the mod from ripperdoc in order to access the respec functions.
- A redscript version of the mod.

## Acknowledgements

- [yamashi](https://github.com/yamashi), [WSSDude420](https://github.com/WSSDude420), [Sombra](https://github.com/Sombra0xCC), [Expired](https://github.com/expired6978) and all [Cyber Engine Tweaks](https://github.com/yamashi/CyberEngineTweaks) team
- [RED Modding tools](https://github.com/WolvenKit), [WopsS](https://github.com/WopsS), [rfuzzo](https://github.com/rfuzzo), [Rick Gibbed](https://github.com/gibbed), [PixelRick](https://github.com/PixelRick) and all researchers
- [CP77 Modding Community Discord](https://discord.gg/VhdvZncG6f)

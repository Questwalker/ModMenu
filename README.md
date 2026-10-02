# Mod Menu
A mod for VotV designed to create a mod menu that allows users to see all loaded mods and to edit their configs.

Heavily inspired by the [ModMenu](<https://modrinth.com/mod/modmenu>) mod from Minecraft and Minecraft's modding ecosystem.

Contained within the Questwalker-ModMenu folder are the lua scripts that accompany this mod.

<img src="https://raw.githubusercontent.com/Questwalker/ModMenu/refs/heads/main/Assets/modsTab.png" alt="Description" width="40%">&nbsp;<img src="https://raw.githubusercontent.com/Questwalker/ModMenu/refs/heads/main/Assets/configTab.png" alt="Description" width="40%">

## Feature List:
* Mod menu button available in the pause/main menu.
* View all mods (currently only blueprint mods!) currently loaded in the menu's first tab.
* View all config files in the menu's second tab.
* Edit config files in-game using the second tab's config editor.

The ConfigAPI library is also made alongside this project. It's a library that makes it easier for developers to read/write config files without having to roll all of the code themselves. See [here](https://github.com/Questwalker/modmenu#config-api) for more documentation on that.

## Creating your mod manifest (Making your ModMenu entry)
(This section is for developers)\
In the folder where your ModActor is located, create a new blueprint (the parent class can be anything, I.E. the base object class) and name it "manifest".

Open it up and create 4 string variables, named "name", "desc", "author", "version". Then one final Texture2D variable "icon". Hit the compile button on the blueprint, and then hit the "Class Defaults" button to open up the defaults pane, where you should see the variables you just created in the list. This is where you will fill in your mod's information. Set the `name`, `description`, `author`, and `version` to whatever you want, and set the `icon` too (make sure the texture2D that you use is packaged with your mod or it might cause some issues).

## Config API
This project also additionally provides a library called the ConfigAPI (located [here](https://github.com/Questwalker/modmenu/raw/refs/heads/main/Content/Mods/ModMenu/ConfigAPI.uasset)). This is intended to be used so that mods can read and write to config files (`.cfg`, `.ini`, etc.). This is an additional tool and does not require ModMenu in any way to use.

### Usage instructions
Using it will require some plugins, [FileSDK](https://www.fab.com/listings/9020eef3-f598-473d-9964-84ad507002be), [LowEntryExtendedStandardLibrary](https://www.fab.com/listings/0aadd41b-c02d-4f63-9009-bffad0070ebc), [RyHelpfulHelpers](https://www.fab.com/listings/78e7d607-29fd-4fcd-80a0-d0f7f1361916), and VictoryBPLibrary if you haven't installed it already. They're all free on the marketplace but you can also download them as files from here: [discord link](https://discord.com/channels/512287844258021376/1109865680322428938/1472941606507253914) and install them manually using the directions in the "Setting Up Unreal Engine" page in the wiki if you want to avoid messing around with the marketplace and launcher. Additionally, the built-in "Blueprint File Utilities" plugin must be enabled.

To install, just close unreal engine, place the `ConfigAPI.uasset` file in your project's mod folder (or wherever you want it to be), and open Unreal Engine again. Keep in mind that if the required plugins (listed above) are not installed when you attempt to open `ConfigAPI.uasset`, Unreal Engine will most likely crash. 

The usage is pretty simple.
1. The library supports any format that uses `key=value` pairs (.cfg files or .ini files for example), so create a file in the config folder (`/Config` in unreal engine, `/shimloader/cfg` inside r2modman/thunderstore, `/VotV/Config` in a manual installation) with whatever content you want in it.
2. The library is an "Actor Component", so to use it, attach it to your mod actor (or whatever you want to interface with it)
3. To "select" a file for the library to read and parse, use its "Select Config File" function. Give it just the filename, and it'll look in the config folder mentioned above for it. The function also gives you the ability to create the file if it doesn't exist.
4. From there you're pretty much all set up. Use the "Get Key" and "Write To Key" functions all you want to interface with your config file, and theres also the "Add Key", "Key Exists", "Remove Key", "Get Keys", "Get Values", and "Get Items" functions for some further interaction. The library also runs it's own little file watcher, so if the file gets updated through an outside source (a user manually editing the file), it'll call the "Config Updated" event dispatcher, which you can bind to and stuff.

Additional Notes:
* `#`, `;`, and newline characters are not allowed in keys or values, and are just removed from any inputs. Better handling of these characters is planned later. Additionally, inputs are additionally trimmed of surrounding whitespace when reading/writing, so keep that in mind.
* Section headers are not supported for now.
* The library is all yours to screw around with as much as you please! Feel free to open it up, change around the code, and do whatever you want with it. I've tried to leave useful comments on all the functions and many nodes to make it easy to read and figure out.
* The library has a logging event dispatcher `ConfigLog` which it uses to log its operations. You can bind to it if you want to see what its doing internally or to debug anything.
* The library only deals in strings (for now at least). You'll need to manually convert the value yourself into a boolean, integer, array, etc. if you need it.

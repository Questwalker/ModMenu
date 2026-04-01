# Mod Menu
A mod for VotV designed to create a mod menu that allows users to see all loaded mods and to edit their configs.

Heavily inspired by the [ModMenu](<https://modrinth.com/mod/modmenu>) mod from Minecraft and Minecraft's modding ecosystem.

> [!IMPORTANT]
> **This mod is in heavy development and is not complete yet!**

## Config API
This project also additionally provides a library called the ConfigAPI (located [here](MISSINGLINK)). This is intended to be used so that mods can read and write to config files (`.cfg`, `.ini`, etc.). This is an additional tool and does not require ModMenu in any way to use.

### Usage instructions
Using it will require some plugins, [FileSDK](https://www.fab.com/listings/9020eef3-f598-473d-9964-84ad507002be), [LowEntryExtendedStandardLibrary](https://www.fab.com/listings/0aadd41b-c02d-4f63-9009-bffad0070ebc), [RyHelpfulHelpers](https://www.fab.com/listings/78e7d607-29fd-4fcd-80a0-d0f7f1361916), and VictoryBPLibrary if you haven't installed it already. They're all free on the marketplace but you can also download them as files from here: [discord link](https://discord.com/channels/512287844258021376/1109865680322428938/1472941606507253914) and install them manually using the directions in the "Setting Up Unreal Engine" page in the wiki if you want to avoid messing around with the marketplace and launcher.

To install, just close unreal engine, place the `ConfigAPI.uasset` file in your project's mod folder (or wherever you want it to be), and open Unreal Engine again.

The usage is pretty simple.
1. The library supports any format that uses `key=value` pairs (.cfg files or .ini files for example), so create a file in the config folder (`/Config` in unreal engine, `/shimloader/cfg` inside r2modman/thunderstore, `/VotV/Config` in a manual installation) with whatever content you want in it.
2. The library is an "Actor Component", so to use it, attach it to your mod actor (or whatever you want to interface with it)
3. To "select" a file for the library to read and parse, use its "Select Config File" function. Give it just the filename, and it'll look in the config folder mentioned above for it.
4. From there you're pretty much all set up. Use the "Get Key" and "Write To Key" functions all you want to interface with your config file, and theres also the "Add Key", "Key Exists", "Get Keys", "Get Values", and "Get Items" functions for some further interaction. The library also runs it's own little file watcher, so if the file gets updated through an outside source (a user manually editing the file), it'll call the "Config Updated" event dispatcher, which you can bind to and stuff.

Additional Notes:
* The library doesn't support _creating_ a config file yet. It'll only rely on a file that is already there (I'll add a feature for creating a file)
* The library's parser supports comments that start with either # hashtags or ; semicolons, but it doesn't support inline comments yet. So something like `importantvalue=password123 #this is a comment` won't parse like you'd expect.
* The library is all yours to screw around with as much as you please. Feel free to open it up, change around the code, and do whatever you want with it. I've tried to leave useful comments on all the functions and many nodes to make it easy to read and figure out.
* The library has a logging function `_ConfigAPILog` which it uses to log many things. It uses a debug print statement but feel free to edit it if you've got a better logging system going on in your project
* The library only deals in strings (for now at least). You'll need to manually convert the value yourself into a boolean, integer, array, etc. if you need it.

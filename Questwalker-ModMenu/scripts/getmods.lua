local UEHelpers = require("UEHelpers")

local VerboseLogging = false

local function Log(Message, OnlyLogIfVerbose)
    if not VerboseLogging and OnlyLogIfVerbose then return end
    print("[ModMenu] " .. Message)
end

-- package.path = '.\\Mods\\ModLoaderMod\\?.lua;' .. package.path
-- package.path = '.\\Mods\\ModLoaderMod\\BPMods\\?.lua;' .. package.path

Mods = {}

-- Contains mod names from Mods/BPModLoaderMod/load_order.txt and is used to determine the load order of BP mods.
local ModOrderList = {}

local DefaultModConfig = {}
DefaultModConfig.AssetName = "ModActor_C"
DefaultModConfig.AssetNameAsFName = UEHelpers.FindOrAddFName("ModActor_C")

-- Checks if the beginning of a string contains a certain pattern.
local function StartsWith(String, StringToCompare)
    return string.sub(String, 1, string.len(StringToCompare)) == StringToCompare
end

local function FileExists(file)
    local f = io.open(file, "rb")
    if f then f:close() end
    return f ~= nil
end

-- Reads lines from the specified file and returns a table of lines read.
-- Second argument takes a string that can be used to exclude lines starting with that string. Default ;
local function LinesFrom(file, ignoreLinesStartingWith)
    if not FileExists(file) then return {}, false end

    if ignoreLinesStartingWith == nil then
        ignoreLinesStartingWith = ";"
    end

    local lines = {}
    for line in io.lines(file) do
        if not StartsWith(line, ignoreLinesStartingWith) then
            lines[#lines + 1] = line
        end
    end
    return lines, true
end

-- Called Second:
-- Loads mod order data from load_order.txt and pushes it into ModOrderList.
local function LoadModOrder()
    -- A bug: If using the experimental release of UE4SS, most files (including the Mods folder) are contained inside a "ue4ss" folder,
    --  which this ↓ path doesn't specify. So the file fails to load
    local file = 'Mods/BPModLoaderMod/load_order.txt'
    local lines, success = LinesFrom(file)
    if not success then lines = LinesFrom('ue4ss/Mods/BPModLoaderMod/load_order.txt') end -- DEBUG: REMOVE LATER

    local entriesAdded = 0

    for _, line in pairs(lines) do
        ModAlreadyExists = false
        for _, ModName in pairs(ModOrderList) do
            if ModName == line then
                ModAlreadyExists = true
            end
        end
        -- Checks for double mod entries in the file and if a mod was already included, skip it.
        if not ModAlreadyExists then
            table.insert(ModOrderList, line)
            entriesAdded = entriesAdded + 1
        end
    end

    if entriesAdded <= 0 then
        Log(string.format("Mods/BPModLoaderMod/load_order.txt not present or no matching mods, loading all BP mods in random order.\n"))
    end
end

-- Called Third:
local function SetupModOrder()
    local Priority = 1

    -- Adds priority mods first by their respective order as specified in load_order.txt
    for _, ModOrderEntry in pairs(ModOrderList) do
        for ModName, ModInfo in pairs(Mods) do
            if type(ModInfo) == "table" then
                if ModOrderEntry == ModName then
                    OrderedMods[Priority] = ModInfo
                    OrderedMods[Priority].Name = ModName
                    OrderedMods[Priority].Priority = Priority
                    Priority = Priority + 1
                end
            end
        end
    end

    -- Adds the remaining mods in a random order after the prioritized mods.
    for ModName, ModInfo in pairs(Mods) do
        ModAlreadyIncluded = false
        for _, OrderedModInfo in ipairs(OrderedMods) do
            if type(OrderedModInfo) == "table" then
                if OrderedModInfo.Name == ModName then
                    ModAlreadyIncluded = true
                end
            end
        end

        if not ModAlreadyIncluded then
            ModInfo.Name = ModName
            table.insert(OrderedMods, ModInfo)
        end
    end
end

-- Called First:
local function LoadModConfigs()
    -- Load configurations for mods.
    local Dirs = IterateGameDirectories();
    if not Dirs then
        error("[ModMenu] UE4SS does not support loading mods for this game.")
    end
    local LogicModsDir = Dirs.Game.Content.Paks.LogicMods
    if not Dirs then error("[ModMenu] IterateGameDirectories failed, cannot load BP mod configurations.") end
    if not LogicModsDir then
        CreateLogicModsDirectory();
        Dirs = IterateGameDirectories();
        LogicModsDir = Dirs.Game.Content.Paks.LogicMods
        if not LogicModsDir then error("[ModMenu] Unable to find or create Content/Paks/LogicMods directory. Try creating manually.") end
    end
    for ModDirectoryName, ModDirectory in pairs(LogicModsDir) do
        Log(string.format("Mod: %s\n", ModDirectoryName))
        for _, ModFile in pairs(ModDirectory.__files) do
            Log(string.format("    ModFile: %s\n", ModFile.__name))
            if ModFile.__name == "config.lua" then
                dofile(ModFile.__absolute_path)
                if type(Mods[ModDirectoryName]) ~= "table" then break end
                if not Mods[ModDirectoryName].AssetName then break end
                Mods[ModDirectoryName].AssetNameAsFName = UEHelpers.FindOrAddFName(Mods[ModDirectoryName].AssetName)
                break
            end
        end
    end

    local Files = LogicModsDir.__files
    for _, ModDirectory in pairs(LogicModsDir) do
        for _, ModFile in pairs(ModDirectory.__files) do
            table.insert(Files, ModFile)
        end
    end

    -- Load a default configuration for mods that didn't have their own configuration.
    for _, ModFile in pairs(Files) do
        local ModName = ModFile.__name
        local ModNameNoExtension = ModName:match("(.+)%..+$")
        local FileExtension = ModName:match("^.+(%..+)$");
        if FileExtension == ".pak" and not Mods[ModNameNoExtension] then
            --Log("--------------\n")
            --Log(string.format("ModFile: '%s'\n", ModFile.__name))
            --Log(string.format("ModNameNoExtension: '%s'\n", ModNameNoExtension))
            --Log(string.format("FileExtension: %s\n", FileExtension))
            Mods[ModNameNoExtension] = {}
            Mods[ModNameNoExtension].AssetName = DefaultModConfig.AssetName
            Mods[ModNameNoExtension].AssetNameAsFName = DefaultModConfig.AssetNameAsFName
            Mods[ModNameNoExtension].AssetPath = string.format("/Game/Mods/%s/ModActor", ModNameNoExtension)
        end
    end

    LoadModOrder()

    SetupModOrder()
end

LoadModConfigs()



function collectModDataAndManifest(ModInfo)
    local Priority = ""
    local ModName = ""
    local ModDesc = ""
    local ModIcon = nil
    local ModAuthor = ""
    local ModVersion = ""

    -- Get default class of the provided manifest if it exists
    -- pprint("Fetching manifest for", ModInfo.Name)
    local ManifestObject = {}
    LowEntryExtendedStandardLibrary:GetClassWithName(string.format("/Game/Mods/%s/manifest.manifest_C", ModInfo.Name), ManifestObject, nil) -- We need error handling on this, and a ifvalid too
    local ManifestCDefault = nil
    if ManifestObject.success and ManifestObject.Class_:IsValid() then
        pprint("Success in getting manifest for", ModInfo.Name)
        -- The manifest is valid, so it exists. We start pulling info from it
        -- Verifications and fallbacks are done for all of the datatypes
        ManifestCDefault = ManifestObject.Class_:GetCDO()
        if ManifestCDefault.name:type() == "FString" then
            ModName = ManifestCDefault.name
        else
            ModName = ""
        end
        if ManifestCDefault.desc:type() == "FString" then
            ModDesc = ManifestCDefault.desc
        else
            ModDesc = ""
        end
        if ManifestCDefault.icon:type() == "UObject" and ManifestCDefault.icon:IsValid() and ManifestCDefault.icon:GetClass():GetFullName() == "Class /Script/Engine.Texture2D" then
            ModIcon = ManifestCDefault.icon
        else
            ModIcon = nil
        end
        if ManifestCDefault.author:type() == "FString" then
            ModAuthor = ManifestCDefault.author
        else
            ModAuthor = ""
        end
        if ManifestCDefault.version:type() == "FString" then
            ModVersion = ManifestCDefault.version
        else
            ModVersion = ""
        end
    else
        pprint("Failure to get manifest for", ModInfo.Name)
    end

    -- Verifications and fallbacks for a couple of the datatypes part 2
    if ModInfo.Priority == nil then
        Priority = "-1"
    else
        Priority = tostring(ModInfo.Priority)
    end

    return {
        ["FileModName_19_2FA3BCE54EEA0C3A5ECEB19E907DF3DD"] = ModInfo.Name,
        ["AssetPath_5_73FB67EE4D37FB600A1DFBA65FA80D8C"] = ModInfo.AssetPath,
        ["AssetName_7_CF87196B48815907770F049A70EC73ED"] = ModInfo.AssetName,
        ["Priority_9_99D9AF15467E7981427631BBF01740C0"] = Priority,
        ["ModName_12_5CC6E42345DA2E9F8D8A52B840F34B9A"] = ModName,
        ["ModDesc_14_4EC5CEC6439E742FD59C46A040CE7AC0"] = ModDesc,
        ["ModIcon_18_EDDA17414AD5160200884C9280B3300F"] = ModIcon,
        ["ModAuthor_24_1BC4ED3F4C6A679D547E44A18DD458B6"] = ModAuthor,
        ["ModVersion_25_C9BB2B1A4E272EE46064E3960D95A0AF"] = ModVersion,
    }
end


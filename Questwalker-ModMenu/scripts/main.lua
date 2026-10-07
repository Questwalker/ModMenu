local UEHelpers = require('UEHelpers')
LowEntryExtendedStandardLibrary = StaticFindObject('/Script/LowEntryExtendedStandardLibrary.Default__LowEntryExtendedStandardLibrary') -- global for getmods to use
local KismetSystemLibrary = UEHelpers.GetKismetSystemLibrary(true)
local mainGamemode = FindFirstOf('mainGamemode_C')
require('utils')
MMModActor = nil
pprint('[ModMenuLua] ModMenu lua module loaded')

---- Collect mod data ----
OrderedMods = {}
require('getmods')
RegisterCustomEvent('IdentifyModMenu', function(ParamContext)
    -- Grab ModActor
    pprint('[ModMenuLua] ModMenu identifying')
    if ParamContext:get() ~= nil then
        MMModActor = ParamContext:get()
    else
        error('[ModMenuLua] Failed to get ModActor!')
    end

    local ModsDataPackage = {}

    -- Scan blueprint mods and create data package
    for i, ModInfo in ipairs(OrderedMods) do
        table.insert(ModsDataPackage, collectModDataAndManifest(ModInfo))
    end

    -- Get Lua and C++ mods
    local DllModsDataPackage = DllGetMods()
    for i, ModInfo in ipairs(DllModsDataPackage) do
        table.insert(ModsDataPackage, {
            ['FileModName_19_2FA3BCE54EEA0C3A5ECEB19E907DF3DD'] = ModInfo['ModName'],
            ['FileAbsolutePath_34_EAB74C8A4264DAD930B2A4904B144DE9'] = ModInfo['AbsoluteFilePath'], -- Will not actually be the complete filepath in the case that the lua or dll file failed to load, but instead to the containing mod folder
            ['ModType_28_3873B3FA429F9A447528B5BB838245A6'] = ModInfo['ModType'],
            ['ModFunctioning_31_948018D14FE264534E2068B3A3B8EE69'] = not not ModInfo['ModFunctioning'],
            -- I cannot get any of the mod data defined in dll mods because theres no way to get the class
            --  ( theres a pointer in cppmod but its fucking private so i can't access it :[ )
        })
    end
    -- pprint('[ModMenuLua]', ModsDataPackage)

    -- Verify ModActor
    if not MMModActor or not MMModActor:IsValid() then
        error('[FATAL MM ERROR] ModActor not defined while sending data')
    end

    -- Return callback to `LuaModlistCallback`
    local LuaModlistCallback = MMModActor.LuaModlistCallback
    if LuaModlistCallback:IsValid() then
        pprint('[ModMenuLua] Executing ModMenu callback')
        LuaModlistCallback(ModsDataPackage)
    else
        error('[FATAL MM ERROR] LuaModlistCallback not valid!')
    end

end)
--------------------------

-- LowEntryExtendedStandardLibrary = StaticFindObject('/Script/LowEntryExtendedStandardLibrary.Default__LowEntryExtendedStandardLibrary') -- global for getmods to use
-- bpCodeLib

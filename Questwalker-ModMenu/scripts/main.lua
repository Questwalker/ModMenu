local UEHelpers = require("UEHelpers")
LowEntryExtendedStandardLibrary = StaticFindObject("/Script/LowEntryExtendedStandardLibrary.Default__LowEntryExtendedStandardLibrary") -- global for getmods to use
local KismetSystemLibrary = UEHelpers.GetKismetSystemLibrary(true)
local mainGamemode = FindFirstOf("mainGamemode_C")
require("utils")
MMModActor = nil
pprint('ModMenu Lua Module Loaded')

---- Collect mod data ----
OrderedMods = {}
require("getmods")
RegisterCustomEvent("IdentifyModMenu", function(ParamContext)
    -- Grab ModActor
    pprint("ModMenu identifying")
    if ParamContext:get() ~= nil then
        MMModActor = ParamContext:get()
    else
        error("[FATAL MM ERROR] Failed to get ModActor")
    end

    -- Scan and create mod data package
    local ModsDataPackage = {}
    for i, ModInfo in ipairs(OrderedMods) do
        table.insert(ModsDataPackage, collectModDataAndManifest(ModInfo))
    end

    -- Verify ModActor
    if not MMModActor or not MMModActor:IsValid() then
        error('[FATAL MM ERROR] ModActor not defined while sending data')
    end

    -- Return callback to `LuaModlistCallback`
    local LuaModlistCallback = MMModActor.LuaModlistCallback
    if LuaModlistCallback:IsValid() then
        pprint('Executing ModMenu callback')
        LuaModlistCallback(ModsDataPackage)
    else
        error('[FATAL MM ERROR] LuaModlistCallback not valid!')
    end

end)
--------------------------









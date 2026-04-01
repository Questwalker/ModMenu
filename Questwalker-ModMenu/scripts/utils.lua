-- UTILS.lua by Questwalker
function format_table(t)
    local builder = ""
    local function _print(str)
        str = str or ""
        builder = builder .. str .. "\n"
    end
    local print_r_cache = {}
    local function sub_print_r(t, indent)
        if (print_r_cache[tostring(t)]) then
            _print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t) == "table") then
                for pos,val in pairs(t) do
                    if (type(val) == "table") then
                        _print(indent.."<"..type(val)..">".."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val, indent..string.rep(" ", string.len(pos)+8))
                        _print(indent..string.rep(" ", string.len(pos)+6).."}")
                    elseif (type(val) == "string") then
                        _print(indent.."<"..type(val)..">".."["..pos..'] => "'..val..'"')
                    else
                        _print(indent.."<"..type(val)..">".."["..pos.."] => "..valtostring(val))
                    end
                end
            else
                _print(indent..tostring(t))
            end
        end
    end
    if (type(t) == "table") then
        _print("{")
        sub_print_r(t, "  ")
        _print("}")
    else
        sub_print_r(t, "  ")
    end
    return builder
end

function valtostring(value)
    if (type(value) == "string") then
        return value
    elseif (type(value) == "number" or type(value) == "boolean" or value == nil) then
        return tostring(value)
    elseif (type(value) == "table") then
        return format_table(value)
        
    -- ue4ss types
    elseif (type(value) == "userdata") then
        local UValType = value:type()

        -- RemoteUnrealParam, LocalUnrealParam
        if (UValType == "RemoteUnrealParam" or UValType == "LocalUnrealParam") then
            local gottenvalue = value:get()
            return "<".. UValType .." ".. type(gottenvalue) .."<".. valtostring(gottenvalue) ..">>"

        -- FName, FText, FString, FAnsiString, FUtf8String
        elseif (UValType == "FName" or UValType == "FText" or UValType == "FString" or UValType == "FAnsiString" or UValType == "FUtf8String") then
            return value:ToString()

        -- TArray
        elseif (UValType == "TArray") then
            local tarraybuffer = "[ "
            for i = 1, #value do
                tarraybuffer = tarraybuffer .. valtostring(value[i]) .. ", "
            end
            tarraybuffer = tarraybuffer .. " ]"
            return tarraybuffer

        -- TSet (EXPERMENTAL, HAS NOT BEEN TESTED)
        elseif (UValType == "TSet") then
            local tsetbuffer = "{ "
            value:ForEach(function(element)
                tsetbuffer = tsetbuffer .. valtostring(element:get()) .. ", "
            end)
            tsetbuffer = tsetbuffer .. " }"
            return tsetbuffer

        else
            return "" .. valtostring(UValType) .. ""
        end

    -- unknown type
    else
        return "<UnrecognizedValue ".. type(value) ..">"
    end
end

function pprint(...)
    local args = {...}
    local builtstring = ""
    for i, value in ipairs(args) do
        builtstring = builtstring .. valtostring(value)
        if (i ~= (#args)) then
            builtstring = builtstring .. " "
        end
    end
    print(builtstring)
end

function getCWD()
    return io.popen"cd":read'*l'
end

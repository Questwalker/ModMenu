//#include <stdio.h>
#include <Mod/CppUserModBase.hpp>
#include <DynamicOutput/DynamicOutput.hpp>
#include <Unreal/UObjectGlobals.hpp>
#include <Unreal/UObject.hpp>
#include <iostream>
#include <fstream>
#include <string>
#include <filesystem>
#include <vector>
#include <windows.h>
#include <codecvt>
#include <locale>
#include <cstdlib>
#include <UE4SSProgram.hpp>
#include <Mod/CppMod.hpp>
#include <Mod/LuaMod.hpp>
#include <Mod/Mod.hpp>
#include <LuaLibrary.hpp>
#include <LuaMadeSimple/LuaMadeSimple.hpp>
using namespace RC;
using namespace RC::Unreal;

namespace fs = std::filesystem;
std::wstring_convert<std::codecvt_utf8<wchar_t>> converter;

std::string wchar_to_string(const wchar_t* wide_str) {
    if (!wide_str) return "";

    // 1. Determine the required buffer size
    size_t size_needed = std::wcstombs(nullptr, wide_str, 0);
    if (size_needed == static_cast<size_t>(-1)) {
        return ""; // Conversion failed due to invalid character
    }

    // 2. Allocate string and convert
    std::string result(size_needed, '\0');
    std::wcstombs(&result[0], wide_str, size_needed);

    return result;
}

const char* wchar_to_char(const wchar_t* wide_str) {
    size_t buffer_size = (wcslen(wide_str) + 1);
    char* narrow_buffer = new char[buffer_size];
    std::wcstombs(narrow_buffer, wide_str, buffer_size);
    const char* result = narrow_buffer;
    delete[] narrow_buffer;
    return result;
}

class ModMenu : public CppUserModBase
{
public:
    LuaMadeSimple::Lua* m_lua_state = nullptr;

    ModMenu() : CppUserModBase()
    {
        ModName = STR("ModMenu");
        ModVersion = STR("1.1.0");
        ModDescription = STR("A mod menu and config editor for VotV");
        ModAuthors = STR("Questwalker");
    }

    ~ModMenu() override
    {
    }

    auto on_unreal_init() -> void override
    {
        // You are allowed to use the 'Unreal' namespace in this function and anywhere else after this function has fired.
        auto Object = UObjectGlobals::StaticFindObject<UObject*>(nullptr, nullptr, STR("/Script/CoreUObject.Object"));
    }

    virtual auto on_lua_start(LuaMadeSimple::Lua& lua, LuaMadeSimple::Lua& main_lua, LuaMadeSimple::Lua& async_lua, LuaMadeSimple::Lua* hook_lua) -> void
    {
        Output::send<LogLevel::Normal>(STR("[ModMenuDll] Lua mod loading detected, registering function\n"));
        m_lua_state = &lua;
        register_lua_functions(lua);
    }

    auto register_lua_functions(LuaMadeSimple::Lua& lua) -> void
    {
        // register lua function
        lua.register_function("DllGetMods", [](const LuaMadeSimple::Lua& lua) -> int {
            Output::send<LogLevel::Normal>(STR("[ModMenuDll] Lua requesting mods, gathering data\n"));
            // create tables to return
            auto maintable = lua.prepare_new_table();

            // get all mods
            auto& program = UE4SSProgram::get_program();
            int tablenumber = 1;
            for (const auto& mod : program.m_mods)
            {
                std::string mod_name = std::string(wchar_to_string(mod->get_name().data()));
                //mod->get_id(); // an arbitrary number
                //mod->get_name(); // the mod folder name (eg. "ConsoleCommandsMod" or "Author-ExampleMod")
                //mod->get_path(); // filepath to the folder that contains the dlls folder because fuck you
                bool mod_is_functional = mod->is_started(); // && mod->is_installed(); is_installed gets reset to false when mod hot-reloading
                std::string mod_type = "unknown";
                if (auto* cpp_mod = dynamic_cast<CppMod*>(mod.get()))
                {
                    mod_type = "cpp";
                }
                else if (auto* lua_mod = dynamic_cast<LuaMod*>(mod.get()))
                {
                    mod_type = "lua";
                }

                // generate mod table
                maintable.add_key(tablenumber);
                auto currentmoddata = lua.prepare_new_table();
                currentmoddata.add_pair("ModName", wchar_to_char(mod->get_name().data()));
                currentmoddata.add_pair("AbsoluteFilePath", mod->get_path().string().c_str());
                currentmoddata.add_pair("ModType", mod_type.c_str());
                currentmoddata.add_pair("ModFunctioning", mod_is_functional);
                currentmoddata.make_local();
                maintable.fuse_pair();
                tablenumber += 1;
            }

            return 1;
        });
    }
};

#define MODMENU_API __declspec(dllexport)
extern "C"
{
    MODMENU_API CppUserModBase* start_mod()
    {
        return new ModMenu();
    }

    MODMENU_API void uninstall_mod(CppUserModBase* mod)
    {
        delete mod;
    }
}

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
#include <string_view>
#include <UE4SSProgram.hpp>
#include <Mod/CppMod.hpp>
#include <Mod/LuaMod.hpp>
#include <Mod/Mod.hpp>
#include <LuaLibrary.hpp>
#include <LuaMadeSimple/LuaMadeSimple.hpp>
using namespace RC;
using namespace RC::Unreal;

std::filesystem::path find_modfile_cpp(StringViewType m_mod_name, std::filesystem::path m_mod_path) {
    // Code taken from CppMod.cpp which locates the path to the dll file
    std::filesystem::path m_dlls_path = m_mod_path / STR("dlls");

    if (!std::filesystem::exists(m_dlls_path))
    {
        return std::filesystem::path{};
    }

    auto dll_path = m_dlls_path / STR("main.dll");
    if (!std::filesystem::exists(dll_path))
    {
        dll_path = m_dlls_path / fmt::format(STR("{}.dll"), m_mod_name);

        if (!std::filesystem::exists(dll_path))
        {
            return std::filesystem::path{};
        }
    }

    return dll_path;
}

std::filesystem::path find_modfile_lua(std::filesystem::path m_mod_path) {
    // Code taken from LuaMod.cpp which locates the path to the lua file
    // first half
    std::filesystem::path scripts_path = m_mod_path / STR("Scripts");

    if (!std::filesystem::exists(scripts_path))
    {
        std::filesystem::path alt_scripts_path = m_mod_path / STR("scripts");
        if (std::filesystem::exists(alt_scripts_path))
        {
            scripts_path = alt_scripts_path;
        }
    }

    std::filesystem::path m_scripts_path = scripts_path;

    if (!std::filesystem::exists(m_scripts_path))
    {
        return std::filesystem::path{};
    }

    // second half
    std::filesystem::path main_script_path = m_scripts_path / STR("main.lua");

    if (std::filesystem::exists(main_script_path))
    {
        return main_script_path;
    }
    else
    {
        return std::filesystem::path{};
    }
}

class ModMenu : public CppUserModBase
{
public:
    LuaMadeSimple::Lua* m_lua_state = nullptr;

    ModMenu() : CppUserModBase()
    {
        ModName = STR("ModMenu");
        ModVersion = STR("1.2.0");
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
                //mod->get_id(); // an arbitrary number
                //mod->get_name(); // the mod folder name (eg. "ConsoleCommandsMod" or "Author-ExampleMod")
                //mod->get_path(); // filepath to the folder that contains the dlls folder because fuck you
                std::filesystem::path path_absolute_path = mod->get_path();
                std::string mod_type = "unknown";
                if (auto* cpp_mod = dynamic_cast<CppMod*>(mod.get()))
                {
                    mod_type = "cpp";
                    auto completefilepath = find_modfile_cpp(mod->get_name(), mod->get_path());
                    if (!completefilepath.empty()) {
                        path_absolute_path = completefilepath;
                    }
                }
                else if (auto* lua_mod = dynamic_cast<LuaMod*>(mod.get()))
                {
                    mod_type = "lua";
                    auto completefilepath = find_modfile_lua(mod->get_path());
                    if (!completefilepath.empty()) {
                        path_absolute_path = completefilepath;
                    }
                }
                std::string mod_name = to_utf8_string(mod->get_name());
                std::string mod_path = path_absolute_path.string();
                bool mod_is_functional = mod->is_started(); // && mod->is_installed(); is_installed gets reset to false when mod hot-reloading

                // print stuff
                //auto wpath = std::filesystem::path(path_absolute_path).wstring();
                //Output::send<LogLevel::Normal>(STR("[ModMenuDll] mod {}, filepath: {}\n"), ensure_str(mod_name), wpath);

                // generate mod table
                maintable.add_key(tablenumber);
                auto currentmoddata = lua.prepare_new_table();
                currentmoddata.add_pair("ModName", mod_name.c_str());
                currentmoddata.add_pair("AbsoluteFilePath", mod_path.c_str());
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

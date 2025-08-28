--[[ UI Settings ]]
local ReGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua",true))()

local Window = ReGui:TabsWindow({
    Title = "MyHub",
    Size = UDim2.fromOffset(336, 226),
    NoGradients = true,
    BackgroundTransparency = 0
})

--[[ Tabs ]]
local funcsTab = Window:CreateTab({Name = "Functions Tests"})
local gameTab = Window:CreateTab({Name = "Game Focused"})
local hubsTab = Window:CreateTab({Name = "Hubs"})
local utilsTab = Window:CreateTab({Name = "Utilities"})

--[[ Functions Tests ]]
funcsTab:Button({
    Text = "senSUNC",
    Callback = function()
        getgenv().sUNCDebug = {
            ["printcheckpoints"] = false,
            ["delaybetweentests"] = 0
        }
        
        loadstring(game:HttpGet("https://gitlab.com/sens3/nebunu/-/raw/main/HummingBird8's_sUNC_yes_i_moved_to_gitlab_because_my_github_acc_got_brickedd/sUNCm0m3n7.lua?ref_type=heads",true))()
    end
})
funcsTab:Button({
    Text = "Myriad General Validty Test",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Proton-Utilities/Myriad/refs/heads/main/dist.luau",true))()
    end
})
funcsTab:Button({
    Text = "Unified Naming Convention",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/unified-naming-convention/NamingStandard/refs/heads/main/UNCCheckEnv.lua",true))()
    end
})

--[[ Game Focused ]]
local jbHeader = gameTab:CollapsingHeader({Title = "Jailbreak", NoArrow = false})
local paNode = jbHeader:TreeNode({Title = "Project Auto", NoArrow = false})
paNode:Button({
    Text = "AutoRob",
    Callback = function()
        loadstring(game:HttpGet('https://scripts.projectauto.xyz/AutoRobV6',true))()
    end
})
paNode:Button({
    Text = "AutoArrest",
    Callback = function()
        loadstring(game:HttpGet('https://scripts.projectauto.xyz/AutoArrestV4',true))()
    end
})
local ufNode = jbHeader:TreeNode({Title = "Universal Farm", NoArrow = false})
ufNode:Button({
    Text = "Loader",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/BlitzIsKing/UniversalFarm/main/Loader/Regular',true))()
    end
})
ufNode:Button({
    Text = "AutoRob",
    Callback = function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/cf83df89dc364d86bafd481d72bdd953.lua",true))()
    end
})
ufNode:Button({
    Text = "AutoArrest",
    Callback = function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/ef2b75a1c0445997d44b7371f11ee88a.lua",true))()
    end
})
jbHeader:Button({
    Text = "Sensation",
    Callback = function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/730854e5b6499ee91deb1080e8e12ae3.lua",true))()
    end
})
jbHeader:Button({
    Text = "Ice Tray",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/piglex9/icetray3/main/latest.lua",true))()
    end
})
jbHeader:Button({
    Text = "PayPal",
    Callback = function()
        loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/472776ba5c9893001fd78d5a8f442b08.lua",true))()
    end
})
local rivalsHeader = gameTab:CollapsingHeader({Title = "Rivals", NoArrow = false})
rivalsHeader:Button({
    Text = "Gun Mods",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Gun%20Mods.lua",true))()
    end
})
rivalsHeader:Button({
    Text = "Duck Hub",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/HexFG/duckhub/refs/heads/main/loader.lua',true))()
    end
})
local bwHeader = gameTab:CollapsingHeader({Title = "BedWars", NoArrow = false})
bwHeader:Button({
    Text = "VapeV4",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua", true))()
    end
})
bwHeader:Button({
    Text = "VoidWare",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VW-Add/main/inkgame.lua", true))()
    end
})
bwHeader:Button({
    Text = "VapeLite",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeLiteForRoblox/main/NewMainScript.lua", true))()
    end
})
gameTab:Button({
    Text = "Thunder Client Lite (Arsenal)",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/andrewdarkyyofficial/thunderclient/main/main.lua',true))()
    end
})
gameTab:Button({
    Text = "ESP with Roles Color (MM2)",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Straden/Scripts/main/MM2.lua",true))()
    end
})

--[[ Hubs ]]
hubsTab:Button({
    Text = "OrcaHub",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/richie0866/orca/master/public/latest.lua",true))()
    end
})
hubsTab:Button({
    Text = "AirHub V2",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/AirHub-V2/main/src/Main.lua",true))()
    end
})
hubsTab:Button({
    Text = "AirHub",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Exunys/AirHub/main/AirHub.lua",true))()
    end
})
hubsTab:Button({
    Text = "SpaceHub",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Lucasfin000/Orbit-UI-Library/main/Library", true))()
    end
})
hubsTab:Button({
    Text = "NukeHub",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/NukeVsCity/TheALLHACKLoader/main/NukeLoader", true))()
    end
})

--[[ Utilities ]]
local gptHeader = utilsTab:CollapsingHeader({Title = "GPT", NoArrow = false})
gptHeader:Button({
    Text = "AntiLag",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/GPT/AntiLag.lua",true))()
    end
})
gptHeader:Button({
    Text = "ReJoin",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/GPT/ReJoin.lua",true))()
    end
})
utilsTab:Button({
    Text = "Infinite Yield FE",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source',true))()
    end
})
utilsTab:Button({
    Text = "WRD ESP",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/WRD/ESP.lua",true))()
    end
})
utilsTab:Button({
    Text = "WRD Aimbot",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/WRD/Aimbot.lua",true))()
    end
})
utilsTab:Button({
    Text = "USSI with Terrain",
    Callback = function()
        local synsaveinstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/verysigmapro/UniversalSynSaveInstance-With-Save-Terrain/refs/heads/main/saveinstance_rewrite.luau", true), "saveinstance")();
        local SaveinstanceOptions = { usekonstantdecompiler = false, ReadMe = false, SafeMode = true, timeout = -1, SaveBytecode = true, AntiIdle = true, mode = "full" }
        synsaveinstance(SaveinstanceOptions);
    end
})
utilsTab:Button({
    Text = "Scarlet Aimbot",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/ScarletLAB/scarlet/main/universal/main.lua",true))()
    end
})
utilsTab:Button({
    Text = "Kick yourself",
    Callback = function()
        game.Players.LocalPlayer:Kick("kicked")
    end
})
local slrHeader = utilsTab:CollapsingHeader({Title = "Solara Fixes", NoArrow = false})
slrHeader:Button({
    Text = "Upgrader",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Solara%20Fixes/Upgrader.lua",true))()
    end
})
slrHeader:Button({
    Text = "Vulnerability Patcher",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Solara%20Fixes/Vulnerability%20Patcher.lua",true))()
    end
})
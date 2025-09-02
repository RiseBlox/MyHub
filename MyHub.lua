local ReGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua", true))()

local Window = ReGui:TabsWindow({
	Title = "MyHub",
	Size = UDim2.fromOffset(296, 178),
	NoGradients = true,
	BackgroundTransparency = 0
})
local funcsTab = Window:CreateTab({
	Name = "Functions Tests"
})
local gameTab = Window:CreateTab({
	Name = "Game Focused"
})
local utilsTab = Window:CreateTab({
	Name = "Utilities"
})
funcsTab:Button({
	Text = "senS' Unified Naming Convention",
	Callback = function()
		getgenv().sUNCDebug = {
			["printcheckpoints"] = false,
			["delaybetweentests"] = 0
		}
		loadstring(game:HttpGet("https://gitlab.com/sens3/nebunu/-/raw/main/HummingBird8's_sUNC_yes_i_moved_to_gitlab_because_my_github_acc_got_brickedd/sUNCm0m3n7.lua?ref_type=heads", true))()
	end
})
funcsTab:Button({
	Text = "Myriad General Validty Test",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Proton-Utilities/Myriad/refs/heads/main/dist.luau", true))()
	end
})
funcsTab:Button({
	Text = "Unified Naming Convention",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/unified-naming-convention/NamingStandard/refs/heads/main/UNCCheckEnv.lua", true))()
	end
})
gameTab:Separator({
	Text = "Jailbreak"
})
local paHeader = gameTab:CollapsingHeader({
	Title = "Project Auto",
	NoArrow = false
})
paHeader:Button({
	Text = "AutoRob",
	Callback = function()
		loadstring(game:HttpGet('https://scripts.projectauto.xyz/AutoRobV6', true))()
	end
})
paHeader:Button({
	Text = "AutoArrest",
	Callback = function()
		loadstring(game:HttpGet('https://scripts.projectauto.xyz/AutoArrestV4', true))()
	end
})
local ufHeader = gameTab:CollapsingHeader({
	Title = "Universal Farm",
	NoArrow = false
})
ufHeader:Button({
	Text = "Loader",
	Callback = function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/BlitzIsKing/UniversalFarm/main/Loader/Regular', true))()
	end
})
ufHeader:Button({
	Text = "AutoRob",
	Callback = function()
		loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/cf83df89dc364d86bafd481d72bdd953.lua", true))()
	end
})
ufHeader:Button({
	Text = "AutoArrest",
	Callback = function()
		loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/ef2b75a1c0445997d44b7371f11ee88a.lua", true))()
	end
})
gameTab:Button({
	Text = "Sensation",
	Callback = function()
		loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/730854e5b6499ee91deb1080e8e12ae3.lua", true))()
	end
})

gameTab:Separator({
	Text = "BedWars"
})
gameTab:Button({
	Text = "VapeV4",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua", true))()
	end
})
gameTab:Button({
	Text = "VoidWare",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VWRewrite/main/NewMainScript.lua", true))()
	end
})

gameTab:Separator({
	Text = "Rivals"
})
gameTab:Button({
	Text = "Gun Mods",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/Misc/Gun%20Mods%20(Rivals).lua", true))()
	end
})
gameTab:Button({
	Text = "Duck Hub",
	Callback = function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/HexFG/duckhub/main/loader.lua', true))()
	end
})
gameTab:Button({
	Text = "kiciahook",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/kiciahook/kiciahook/main/loader.luau", true))()
	end
})
gameTab:Separator({
	Text = "Other"
})
gameTab:Button({
	Text = "Thunder Client Lite (Arsenal)",
	Callback = function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/andrewdarkyyofficial/thunderclient/main/main.lua', true))()
	end
})
gameTab:Button({
	Text = "VoidWare (Ink Game)",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VW-Add/main/inkgame.lua", true))()
	end
})
gameTab:Button({
	Text = "ESP with Roles Color (MM2)",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Straden/Scripts/main/MM2.lua", true))()
	end
})
utilsTab:Separator({
	Text = "GPT"
})
utilsTab:Button({
	Text = "AntiLag",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/GPT/AntiLag.lua", true))()
	end
})
utilsTab:Button({
	Text = "ReJoin",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/GPT/ReJoin.lua", true))()
	end
})

utilsTab:Separator({
	Text = "Random"
})
utilsTab:Button({
	Text = "Infinite Yield FE",
	Callback = function()
		loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source', true))()
	end
})
utilsTab:Button({
	Text = "USSI with Terrain",
	Callback = function()
		local synsaveinstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/verysigmapro/UniversalSynSaveInstance-With-Save-Terrain/refs/heads/main/saveinstance_rewrite.luau", true), "saveinstance")();
		local SaveinstanceOptions = {
			usekonstantdecompiler = false,
			ReadMe = false,
			SafeMode = true,
			timeout = -1,
			SaveBytecode = true,
			AntiIdle = true,
			mode = "full"
		}
		synsaveinstance(SaveinstanceOptions);
	end
})
utilsTab:Button({
	Text = "Freecam",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/Misc/Freecam.lua", true))()
	end
})
utilsTab:Button({
	Text = "OrcaHub",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/richie0866/orca/master/public/latest.lua", true))()
	end
})
utilsTab:Button({
	Text = "Kick yourself",
	Callback = function()
		game.Players.LocalPlayer:Kick("kicked")
	end
})
utilsTab:Separator({
	Text = "WRD"
})
utilsTab:Button({
	Text = "ESP",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/WRD/ESP.lua", true))()
	end
})
utilsTab:Button({
	Text = "Aimbot",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/WRD/Aimbot.lua", true))()
	end
})
utilsTab:Separator({
	Text = "Explorers"
})
utilsTab:Button({
	Text = "Dex",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/Misc/Dex.lua", true))()
	end
})
utilsTab:Button({
	Text = "TSDex",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/FaithfulAC/universal-stuff/main/true-secure-dex.lua", true))()
	end
})
utilsTab:Separator({
	Text = "Solara Fixes"
})
utilsTab:Button({
	Text = "Upgrader",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/Solara%20Fixes/Upgrader.lua", true))()
	end
})
utilsTab:Button({
	Text = "Vulnerability Patcher",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/Solara%20Fixes/Vulnerability%20Patcher.lua", true))()
	end
})

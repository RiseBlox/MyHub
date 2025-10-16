local ReGui = loadstring(game:HttpGet("https://raw.githubusercontent.com/depthso/Dear-ReGui/refs/heads/main/ReGui.lua", true))()
local Window = ReGui:TabsWindow({
	Title = "MyHub V2 - Mobile",
	Size = UDim2.fromOffset(322, 197),
	NoGradients = true,
	BackgroundTransparency = 100
})
---
local unTab = Window:CreateTab({
	Name = "Universal"
})
local jbTab = Window:CreateTab({
	Name = "Jailbreak"
})
local bwTab = Window:CreateTab({
	Name = "BedWars"
})
local rvTab = Window:CreateTab({
	Name = "Rivals"
})
local otTab = Window:CreateTab({
	Name = "Other"
})
---
unTab:Separator({
	Text = "Other"
})
unTab:Button({
	Text = "Infinite Yield",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", true))()
	end
})
unTab:Button({
	Text = "Freecam",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/Misc/Freecam.lua", true))()
	end
})
unTab:Button({
	Text = "USSI (with Terrain)",
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
unTab:Separator({
	Text = "Functions Tests"
})
unTab:Button({
	Text = "senS Unified Naming Convention",
	Callback = function()
		getgenv().sUNCDebug = {
			["printcheckpoints"] = false,
			["delaybetweentests"] = 0
		}
		loadstring(game:HttpGet("https://gitlab.com/sens3/nebunu/-/raw/main/HummingBird8's_sUNC_yes_i_moved_to_gitlab_because_my_github_acc_got_brickedd/sUNCm0m3n7.lua?ref_type=heads", true))()
	end
})
unTab:Button({
	Text = "Myriad General Validty Test",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Proton-Utilities/Myriad/refs/heads/main/dist.luau", true))()
	end
})
unTab:Button({
	Text = "Unified Naming Convention",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/unified-naming-convention/NamingStandard/refs/heads/main/UNCCheckEnv.lua", true))()
	end
})
unTab:Separator({
	Text = "GPT"
})
unTab:Button({
	Text = "AntiLag",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/GPT/AntiLag.lua", true))()
	end
})
unTab:Button({
	Text = "InfSession",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/GPT/InfSession.lua", true))()
	end
})
unTab:Separator({
	Text = "WRD"
})
unTab:Button({
	Text = "Extra-Sensory Perception",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/WRD/ESP.lua", true))()
	end
})
unTab:Button({
	Text = "Aimbot",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/WRD/Aimbot.lua", true))()
	end
})
unTab:Separator({
	Text = "Other 2"
})
unTab:Button({
	Text = "Dex",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/Misc/Dex.lua", true))()
	end
})
unTab:Button({
	Text = "OrcaHub",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/richie0866/orca/master/public/latest.lua", true))()
	end
})
unTab:Button({
	Text = "Kick yourself",
	Callback = function()
		game.Players.LocalPlayer:Kick("kicked")
	end
})
unTab:Button({
	Text = "Device Spoofer",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/Misc/Device%20Spoofer.lua", true))()
	end
})
unTab:Separator({
	Text = "IDE Enhancers"
})
unTab:Button({
	Text = "Upgrader",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/Solara%20Fixes/Upgrader.lua", true))()
	end
})
unTab:Button({
	Text = "Vulnerabilities Patcher",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/Solara%20Fixes/Vulnerability%20Patcher.lua", true))()
	end
})
---
jbTab:Separator({
	Text = "Project Auto"
})
jbTab:Button({
	Text = "AutoRob",
	Callback = function()
		loadstring(game:HttpGet("https://scripts.projectauto.xyz/AutoRobV6", true))()
	end
})
jbTab:Button({
	Text = "AutoArrest",
	Callback = function()
		loadstring(game:HttpGet("https://scripts.projectauto.xyz/AutoArrestV4", true))()
	end
})
jbTab:Separator({
	Text = "Universal Farm"
})
jbTab:Button({
	Text = "AutoRob",
	Callback = function()
		loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/cf83df89dc364d86bafd481d72bdd953.lua", true))()
	end
})
jbTab:Button({
	Text = "AutoArrest",
	Callback = function()
		loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/ef2b75a1c0445997d44b7371f11ee88a.lua", true))()
	end
})
jbTab:Separator({
	Text = "Other"
})
jbTab:Button({
	Text = "Sensation",
	Callback = function()
		loadstring(game:HttpGet("https://api.luarmor.net/files/v3/loaders/730854e5b6499ee91deb1080e8e12ae3.lua", true))()
	end
})
--jbTab:Button({
--	Text = "Solix Hub",
--	Callback = function()
--		loadstring(game:HttpGet("https://raw.githubusercontent.com/meobeo8/a/a/a",true))()
--	end
--})
--jbTab:Button({
--	Text = "Codecoat",
--	Callback = function()
--		loadstring(game:HttpGet("https://raw.githubusercontent.com/Breadido/Codecoat/refs/heads/main/looder.luau",true))()
--	end
--})
--jbTab:Button({
--	Text = "PXSTA Hack",
--	Callback = function()
--		getgenv().GuiUsePlayer = true
--        loadstring(game:HttpGet("https://scripts.projectauto.xyz/PxstaHackV7", true))()
--	end
--})
---
bwTab:Separator({
	Text = "Other"
})
bwTab:Button({
	Text = "VapeV4",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua", true))()
	end
})
bwTab:Button({
	Text = "VoidWare",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VW-Add/main/loader.lua", true))()
	end
})
bwTab:Separator({
	Text = "CatVape"
})
bwTab:Button({
	Text = "Normal",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/new-qwertyui/CatV5/main/init.lua",true), "init.lua")()
	end
})
bwTab:Button({
	Text = "Closet",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/new-qwertyui/CatV5/main/init.lua",true), "init.lua")({Closet = true})
	end
})
---
rvTab:Separator({
	Text = "Other"
})
rvTab:Button({
	Text = "Gun Mods (DETECTED)",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/Codes/Misc/Gun%20Mods%20(Rivals).lua", true))()
	end
})
rvTab:Button({
	Text = "Duck Hub",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/HexFG/duckhub/main/loader.lua", true))()
	end
})
--rvTab:Button({
--	Text = "Solix Hub",
--	Callback = function()
--		loadstring(game:HttpGet("https://raw.githubusercontent.com/meobeo8/a/a/a",true))()
--	end
--})
---
otTab:Separator({
	Text = "Other"
})
otTab:Button({
	Text = "Thunder Client Lite (Arsenal)",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/andrewdarkyyofficial/thunderclient/main/main.lua", true))()
	end
})
otTab:Button({
	Text = "VoidWare (Ink Game)",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/VapeVoidware/VW-Add/main/loader.lua", true))()
	end
})
otTab:Button({
	Text = "Extra-Sensory Perception (MM2)",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Straden/Scripts/main/MM2.lua", true))()
	end
})
otTab:Button({
	Text = "Atlas (Bee Swarm Simulator)",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Chris12089/atlasbss/main/script.lua", true))()
	end
})
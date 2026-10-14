if not game:IsLoaded() then
	game.Loaded:Wait()
end
local url = "https://raw.githubusercontent.com/RiseBlox/"
local ImGui = loadstring(game:HttpGet(url .. "Depthso-Roblox-ImGui/main/ImGui.lua", true))()
local Window = ImGui:CreateWindow({
	Title = "MyHub // REMASTERED                                  X",
	Size = UDim2.fromOffset(464, 276),
	Position = UDim2.fromOffset(9, 8),
	NoResize = false,
})
local function notify(text, duration, title)
	if game.GameId == 245662005 then
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = text,
			Duration = duration,
		})
	else
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title,
			Text = text,
		})
	end
end
local utlTab = Window:CreateTab({
	Name = "[ Utilities ]",
})
Window:ShowTab(utlTab)
utlTab:Separator({})
local iyRow = utlTab:Row()
iyRow:Button({
	Text = "Infinite Yield",
	Callback = function()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source", true))()
		notify("Successfully loaded!", 2, "Infinite Yield")
	end,
})
iyRow:Fill()
utlTab:Separator({})
local gptNode = utlTab:TreeNode({
	Title = "LLMs",
})
local gptRow1 = gptNode:Row()
gptRow1:Button({
	Text = "MapLoader",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/MapLoader.lua", true))()
		notify("Successfully loaded!", 2, "Map Loader")
	end,
})
gptRow1:Button({
	Text = "AntiLag",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/AntiLag.lua", true))()
		notify("Successfully optimized!", 2, "Anti Lag")
	end,
})
gptRow1:Fill()
local gptRow2 = gptNode:Row()
gptRow2:Button({
	Text = "FlingAll",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/FlingAll.lua", true))()
		notify("Successfully started!", 2, "Fling All")
	end,
})
gptRow2:Button({
	Text = "InfSession",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/InfSession.lua", true))()
		notify("Successfully enabled!", 2, "Infinite Session")
	end,
})
gptRow2:Fill()
utlTab:Separator({})
local randUtlNode = utlTab:TreeNode({
	Title = "Random",
})
local utlRow1 = randUtlNode:Row()
utlRow1:Button({
	Text = "UnnamedESP",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/UnnamedESP.lua", true))()
		notify("Successfully loaded!", 2, "UnnamedESP")
	end,
})
utlRow1:Button({
	Text = "WRD Aimbot",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/WRDAimbot.lua", true))()
		notify("Successfully enabled!", 2, "WRD Aimbot")
	end,
})
utlRow1:Button({
	Text = "Freecam",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/Freecam.lua", true))()
		notify("Successfully enabled!", 2, "Freecam")
	end,
})
utlRow1:Fill()
local utlRow3 = randUtlNode:Row()
utlRow3:Button({
	Text = "CachedServerhop",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/CachedServerhop.lua", true))
		notify("Hopping server...", 2, "CachedServerhop")
	end,
})
utlRow3:Fill()
local utlRow2 = randUtlNode:Row()
utlRow2:Button({
	Text = "Console Dumper",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/ConsoleDumper.lua", true))()
		notify("Successfully dumped!", 2, "Console Dumper")
	end,
})
utlRow2:Button({
	Text = "Kick yourself",
	Callback = function()
		game.Players.LocalPlayer:Kick("kicked")
	end,
})
utlRow2:Button({
	Text = "Reset character",
	Callback = function()
		if
			game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildWhichIsA("Humanoid")
		then
			game.Players.LocalPlayer.Character
				:FindFirstChildWhichIsA("Humanoid")
				:ChangeState(Enum.HumanoidStateType.Dead)
		else
			replicatesignal(game.Players.LocalPlayer.Kill)
		end
	end,
})
utlRow2:Fill()
utlTab:Separator({})
local exploreNode = utlTab:TreeNode({
	Title = "Explorers",
})
local dexRow = exploreNode:Row()
dexRow:Button({
	Text = "Dex++",
	Callback = function()
		loadstring(game:HttpGet("https://github.com/AZYsGithub/DexPlusPlus/releases/latest/download/out.lua", true))()
		notify("Successfully loaded!", 2, "Dex++")
	end,
})
dexRow:Button({
	Text = "DexRecontinued",
	Callback = function()
		loadstring(game:HttpGet("https://github.com/Tesker-103/DexRecontinued/releases/latest/download/out.lua", true))()
		notify("Successfully loaded!", 2, "DexRecontinued")
	end,
})
dexRow:Button({
	Text = "VexExplorer",
	Callback = function()
		loadstring(
			game:HttpGet("https://raw.githubusercontent.com/Vezise/2026/main/Vez/VexExplorer/VEXExplorer.lua", true)
		)()
		notify("Successfully loaded!", 2, "Vex Explorer")
	end,
})
dexRow:Fill()
utlTab:Separator({})
local siNode = utlTab:TreeNode({
	Title = "saveinstances()",
})
local ussiRow1 = siNode:Row()
ussiRow1:Button({
	Text = "SI420Edition",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/Pre420.lua", true))()
		notify("Successfully started!", 2, "SI420Edition")
	end,
})
ussiRow1:Button({
	Text = "UniversalSynSI",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/PreLuau.lua", true))()
		notify("Successfully started!", 2, "UniversalSynSI")
	end,
})
ussiRow1:Button({
	Text = "TerrainSI",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/SITerrainOnly.luau", true))()
		notify("Successfully saved!", 2, "TerrainSI")
	end,
})
ussiRow1:Fill()
utlTab:Separator({})
utlTab:Checkbox({
	Label = "3D Rendering",
	Value = true,
	Callback = function(self, Value)
		game:GetService("RunService"):Set3dRenderingEnabled(Value)
	end,
})
utlTab:Separator({})
local ideTab = Window:CreateTab({
	Name = "[ IDE Related ]",
})
ideTab:Separator({
	Text = "Functions Tests",
})
local realRow = ideTab:Row()
realRow:Button({
	Text = "sUNC",
	Callback = function()
		getgenv().sUNCDebug = {
			["printcheckpoints"] = false,
			["delaybetweentests"] = 0,
			["printtesttimetaken"] = false,
		}
		notify("Successfully started!", 2, "sUNC")
		loadstring(game:HttpGet("https://script.sunc.io", true))()
	end,
})
realRow:Button({
	Text = "Myriad",
	Callback = function()
		loadstring(game:HttpGet("https://github.com/Standard-2/Myriad/releases/latest/download/myriad.luau", true))()
		notify("Successfully loaded!", 2, "Myriad")
	end,
})
realRow:Button({
	Text = "UNC",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/UNC.lua", true))()
		notify("Successfully tested!", 2, "UNC")
	end,
})
realRow:Fill()
local fakeNode = ideTab:TreeNode({
	Title = "Fake tests (USE AT YOUR OWN DISCRETION)",
})
local fakeRow = fakeNode:Row()
fakeRow:Button({
	Text = "sUNC",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/FakeSUNC.lua", true))()
		notify("Successfully faked!", 2, "Fake sUNC")
	end,
})
fakeRow:Button({
	Text = "UNC",
	Callback = function()
		loadstring(game:HttpGet(url .. "MyHub/main/codes/FakeUNC.lua", true))()
		notify("Successfully faked!", 2, "Fake UNC")
	end,
})
fakeRow:Fill()
ideTab:Separator({})
if game.GameId == 245662005 then
	local jbTab = Window:CreateTab({
		Name = "[ Jailbreak ]",
	})
	jbTab:Separator({
		Text = "Utility Mods",
	})
	local senRow = jbTab:Row()
	senRow:Button({
		Text = "MyMenu",
		Callback = function()
			loadstring(game:HttpGet(url .. "MyMenu/main/MyMenu.luau", true))()
			notify("Successfully loaded!", 2, "MyMenu")
		end,
	})
	senRow:Button({
		Text = "Sensation",
		Callback = function()
			loadstring(game:HttpGet("https://api.luarmor.net/files/v4/loaders/730854e5b6499ee91deb1080e8e12ae3.lua", true))()
			notify("Successfully loaded!", 2, "Sensation")
		end,
	})
	senRow:Fill()
	jbTab:Separator({
		Text = "Independent Mods",
	})
	local indieRow1 = jbTab:Row()
	indieRow1:Button({
		Text = "Hypershift (Client-sided)",
		Callback = function()
			loadstring(game:HttpGet(url .. "MyHub/main/codes/JailbreakHypershift.lua", true))()
			notify("Successfully enabled!", 2, "Hypershift")
		end,
	})
	indieRow1:Button({
		Text = "Infinite Nitro",
		Callback = function()
			loadstring(game:HttpGet(url .. "MyHub/main/codes/JailbreakInfiniteNitro.lua", true))()
			notify("Successfully enabled!", 2, "Infinite Nitro")
		end,
	})
	indieRow1:Fill()
	local indieRow2 = jbTab:Row()
	indieRow2:Button({
		Text = "Weapon Mods",
		Callback = function()
			loadstring(game:HttpGet(url .. "MyHub/main/codes/JailbreakWeaponMods.lua", true))()
			notify("Successfully modded!", 2, "Gun Mods")
		end,
	})
	indieRow2:Button({
		Text = "QoL Mods",
		Callback = function()
			loadstring(game:HttpGet(url .. "MyHub/main/codes/JailbreakQoLMods.lua", true))()
			notify("Successfully modded!", 2, "QoL Mods")
		end,
	})
	indieRow2:Fill()
	jbTab:Separator({})
	local paNode = jbTab:TreeNode({
		Title = "Project Auto",
	})
	local paRow = paNode:Row()
	paRow:Button({
		Text = "AutoRob",
		Callback = function()
			getgenv().script_id = "parob"
			loadstring(game:HttpGet(url .. "MyHub/main/codes/MultiPremium.lua", true))()
			notify("Successfully loaded!", 2, "Project Auto - Auto Rob")
		end,
	})
	paRow:Button({
		Text = "AutoArrest",
		Callback = function()
			getgenv().script_id = "paarrest"
			loadstring(game:HttpGet(url .. "MyHub/main/codes/MultiPremium.lua", true))()
			notify("Successfully loaded!", 2, "Project Auto - Auto Arrest")
		end,
	})
	paRow:Fill()
	jbTab:Separator({})
	local ufNode = jbTab:TreeNode({
		Title = "Universal Farm",
	})
	local ufRow = ufNode:Row()
	ufRow:Button({
		Text = "AutoRob",
		Callback = function()
			getgenv().script_id = "ufrob"
			loadstring(game:HttpGet(url .. "MyHub/main/codes/MultiPremium.lua", true))()
			notify("Successfully loaded!", 2, "Universal Farm - Auto Rob")
		end,
	})
	ufRow:Button({
		Text = "AutoArrest",
		Callback = function()
			getgenv().script_id = "ufarrest"
			loadstring(game:HttpGet(url .. "MyHub/main/codes/MultiPremium.lua", true))()
			notify("Successfully loaded!", 2, "Universal Farm - Auto Arrest")
		end,
	})
	ufRow:Button({
		Text = "CrateFarm (PREMIUM)",
		Callback = function()
			getgenv().script_id = "ufcrate"
			loadstring(game:HttpGet(url .. "MyHub/main/codes/MultiPremium.lua", true))()
			notify("Successfully loaded!", 2, "Universal Farm - Crate Farm")
		end,
	})
	ufRow:Fill()
	jbTab:Separator({})
elseif game.GameId == 2440500124 then
	local doorsTab = Window:CreateTab({
		Name = "[ Doors ]",
	})
	doorsTab:Separator({
		Text = "Utility Mods"
	})
	local doorsRow1 = doorsTab:Row()
	doorsRow1:Button({
		Text = "mspaint",
		Callback = function()
			getgenv().script_id = "msp"
			loadstring(game:HttpGet(url .. "MyHub/main/codes/MultiPremium.lua", true))()
			notify("Successfully loaded!", 2, "mspaint")
		end,
	})
	doorsRow1:Button({
		Text = "Vynixius",
		Callback = function()
			getgenv().script_id = "vyn"
			loadstring(game:HttpGet(url .. "MyHub/main/codes/MultiPremium.lua", true))()
			notify("Successfully loaded!", 2, "Vynixius")
		end,
	})
	doorsRow1:Button({
		Text = "Abysall Continued",
		Callback = function()
			loadstring(
				game:HttpGet(
					"https://raw.githubusercontent.com/therealcookiemonsterof1966/AbysallContinued/main/Games/Doors/Main.luau",
					true
				)
			)()
			notify("Successfully loaded!", 2, "Abysall Continued")
		end,
	})
	doorsRow1:Fill()
	doorsTab:Separator({
		Text = "Independent Mods",
	})
	local doorsRow2 = doorsTab:Row()
	doorsRow2:Button({
		Text = "MorePerspectives",
		Callback = function()
			loadstring(game:HttpGet(url .. "MyHub/main/codes/DoorsMorePerspectives.lua", true))()
			notify("Successfully enabled!", 2, "MorePerspectives")
		end,
	})
	doorsRow2:Button({
		Text = "Solo Restart",
		Callback = function()
			require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).remotes.PlayAgain:FireServer()
			notify("Restarting...", 2, "Solo Restart")
		end,
	})
	doorsRow2:Fill()
	doorsTab:Separator({})
elseif game.GameId == 111958650 then
	local arsenalTab = Window:CreateTab({
		Name = "[ Arsenal ]",
	})
	arsenalTab:Separator({
		Text = "QoL Mods"
	})
	local arsenalRow = arsenalTab:Row()
	arsenalRow:Button({
		Text = "Thunder Client",
		Callback = function()
			loadstring(
				game:HttpGet("https://raw.githubusercontent.com/andrewdarkyyofficial/thunderclient/main/main.lua", true)
			)()
			notify("Successfully loaded!", 2, "Thunder Client")
		end,
	})
	arsenalRow:Button({
		Text = "FELIPEHUB",
		Callback = function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/FELIPEHUB1/Felipehub-scripts/main/Arsenal", true))()
			notify("Successfully loaded!", 2, "FELIPEHUB")
		end,
	})
	arsenalRow:Fill()
	arsenalTab:Separator({})
elseif game.GameId == 8795154789 then
	local flickTab = Window:CreateTab({
		Name = "[ Flick ]",
	})
	flickTab:Separator({
		Text = "QoL Mods"
	})
	local flickRow = flickTab:Row()
	flickRow:Button({
		Text = "NEVERLOSE",
		Callback = function()
			loadstring(
				game:HttpGet("https://raw.githubusercontent.com/CludeHub/NEVERLOSE/main/NEVERLOSE-FLICK-V2.lua", true)
			)()
			notify("Successfully loaded!", 2, "NEVERLOSE")
		end,
	})
	flickRow:Fill()
	flickTab:Separator({})
elseif game.GameId == 2619619496 then
	local bwTab = Window:CreateTab({
		Name = "[ BedWars ]",
	})
	bwTab:Separator({
		Text = "QoL Mods",
	})
	local bwRow = bwTab:Row()
	bwRow:Button({
		Text = "VapeV4",
		Callback = function()
			loadstring(
				game:HttpGet("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/NewMainScript.lua", true)
			)()
			notify("Successfully loaded!", 2, "VapeV4")
		end,
	})
	bwRow:Button({
		Text = "VapeVoidWare",
		Callback = function()
			loadstring(game:HttpGet("https://files.vapevoidware.xyz/VapeVoidware/VW-Add/main/loader2.lua", true))()
			notify("Successfully loaded!", 2, "VapeVoidWare")
		end,
	})
	bwRow:Button({
		Text = "CatVape",
		Callback = function()
			loadstring(game:HttpGet("https://raw.githubusercontent.com/MaxlaserTech/CatV6/main/init.lua", true), "init.lua")()
			notify("Successfully loaded!", 2, "CatVape")
		end,
	})
	bwRow:Fill()
	bwTab:Separator({})
elseif game.GameId == 66654135 then
	local mm2Tab = Window:CreateTab({
		Name = "[ Murder Mystery 2 ]",
	})
	mm2Tab:Separator({
		Text = "QoL Mods"
	})
	local mm2Row = mm2Tab:Row()
	mm2Row:Button({
		Text = "Reveal All",
		Callback = function()
			loadstring(game:HttpGet(url .. "MyHub/main/codes/MM2RevealAll.lua", true))()
			notify("Successfully revealed!", 2, "Reveal Everyone")
		end,
	})
	mm2Row:Fill()
	mm2Tab:Separator({})
elseif game.GameId == 65241 then
	local ndsTab = Window:CreateTab({
		Name = "[ Natural Disaster Survival ]",
	})
	ndsTab:Separator({
		Text = "QoL Mods"
	})
	local ndsRow = ndsTab:Row()
	ndsRow:Button({
		Text = "No Fall Damge",
		Callback = function()
			loadstring(game:HttpGet(url .. "MyHub/main/codes/NDSNoFallDamage.lua", true))()
			notify("Successfully disabled!", 2, "No Fall Damage")
		end,
	})
	ndsRow:Fill()
	ndsTab:Separator({})
elseif game.GameId == 279565647 then
	local luckyTab = Window:CreateTab({
		Name = "[ LUCKY BLOCKS Battlegrounds ]",
	})
	luckyTab:Separator({
		Text = "QoL Mods"
	})
	local luckyRow = luckyTab:Row()
	luckyRow:Button({
		Text = "Items Giver",
		Callback = function()
			local item = 1
			while item <= 10 do
				game:GetService("ReplicatedStorage"):WaitForChild("SpawnLuckyBlock"):FireServer()
				item = item + 1
			end
			notify("Successfully given!", 2, "Items Giver")
		end,
	})
	luckyRow:Fill()
	luckyTab:Separator({})
elseif game.GameId == 73885730 then
	local prisonTab = Window:CreateTab({
		Name = "[ Prison Life ]",
	})
	prisonTab:Separator({
		Text = "QoL Mods"
	})
	local lifeRow = prisonTab:Row()
	lifeRow:Button({
		Text = "ULTRA HAX",
		Callback = function()
			loadstring(game:HttpGet(url .. "MyHub/main/codes/PrisonLifeULTRAHAX.lua", true))()
			notify("Successfully loaded!", 2, "ULTRA HAX")
		end,
	})
	lifeRow:Button({
		Text = "Silent Aim & ESP",
		Callback = function()
			loadstring(game:HttpGet(url .. "MyHub/main/codes/PrisonLifeSilentAimESP.lua", true))()
			notify("Successfully loaded!", 2, "Silent Aim & ESP")
		end,
	})
	lifeRow:Fill()
	prisonTab:Separator({})
elseif game.GameId == 6035872082 then
	local rivalsTab = Window:CreateTab({
		Name = "[ Rivals ]",
	})
	rivalsTab:Separator({
		Text = "QoL Mods"
	})
	local rivalsRow = rivalsTab:Row()
	rivalsRow:Button({
		Text = "KiciaHook",
		Callback = function()
			getgenv().script_id = "kicia"
			loadstring(game:HttpGet(url .. "MyHub/main/codes/MultiPremium.lua", true))()
			notify("Successfully loaded!", 2, "KiciaHook")
		end,
	})
	rivalsRow:Button({
		Text = "ESP & Aimbot",
		Callback = function()
			loadstring(game:HttpGet(url .. "MyHub/main/codes/RivalsESPAimbot.lua", true))()
			notify("Successfully loaded!", 2, "ESP & Aimbot")
		end,
	})
	rivalsRow:Fill()
	rivalsTab:Separator({})
end
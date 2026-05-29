local configs = {
	parob = {
		name = "Project Auto - Auto Rob",
		key = "https://discord.gg/projectauto",
		load = "https://scripts.projectauto.xyz/AutoRobV6",
		free = {
			load = "https://scripts.projectauto.xyz/AutoRobV6"
		}
	},
	paarrest = {
		name = "Project Auto - Auto Arrest",
		key = "https://discord.gg/projectauto",
		load = "https://scripts.projectauto.xyz/AutoArrestV4",
		free = {
			load = "https://scripts.projectauto.xyz/AutoArrestV4"
		}
	},
	ufrob = {
		name = "Universal Farm - Auto Rob",
		key = "https://discord.gg/universalfarm",
		load = "https://api.luarmor.net/files/v3/loaders/cf83df89dc364d86bafd481d72bdd953.lua",
		free = {
			load = "https://api.luarmor.net/files/v3/loaders/cf83df89dc364d86bafd481d72bdd953.lua"
		}
	},
	ufarrest = {
		name = "Universal Farm - Auto Arrest",
		key = "https://discord.gg/universalfarm",
		load = "https://api.luarmor.net/files/v3/loaders/ef2b75a1c0445997d44b7371f11ee88a.lua",
		free = {
			load = "https://api.luarmor.net/files/v3/loaders/ef2b75a1c0445997d44b7371f11ee88a.lua"
		}
	},
	ufcrate = {
		name = "Universal Farm - Crate Farm",
		key = "https://discord.gg/universalfarm",
		load = "https://api.luarmor.net/files/v3/loaders/f97ac4e22e08eebaa6c0d99682cd0995.lua"
	},
	vyn = {
		name = "Vynixius / Astral",
		key = "https://vynixius.win/getkey",
		load = "https://vynixius.win/loader.luau"
	},
	msp = {
		name = "mspaint",
		key = "https://www.mspaint.cc/key",
		load = "https://api.luarmor.net/files/v3/loaders/002c19202c9946e6047b0c6e0ad51f84.lua"
	},
}

local id = getgenv().script_id

if not id then
	game:GetService("Players").LocalPlayer:Kick(
		"Missing script id."
	)
	return
end

local cfg = configs[id]

if not cfg then
	game:GetService("Players").LocalPlayer:Kick(
		"Invalid script id: "..tostring(id)
	)
	return
end

local p = game:GetService("Players").LocalPlayer

pcall(function()
    p:WaitForChild("PlayerGui"):FindFirstChild("KeyUI"):Destroy()
end)

local g = Instance.new("ScreenGui", p:WaitForChild("PlayerGui"))
g.Name = "KeyUI"
g.ResetOnSpawn = false
g.DisplayOrder = 999999
g.ZIndexBehavior = Enum.ZIndexBehavior.Global
g.IgnoreGuiInset = true

local main = Instance.new("Frame", g)
main.Size = UDim2.new(0,320,0,130)
main.Position = UDim2.new(.5,-160,.5,-70)
main.BackgroundColor3 = Color3.fromRGB(21,22,24)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true

local stroke = Instance.new("UIStroke", main)
stroke.Thickness = 1
stroke.Color = Color3.new(32, 32, 32)
stroke.Transparency = 0.75

local top = Instance.new("Frame", main)
top.Size = UDim2.new(1,0,0,32)
top.BackgroundColor3 = Color3.fromHex("#23456d")
top.BorderSizePixel = 0

local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(1,-64,1,0)
title.Position = UDim2.new(0,32,0,0)
title.BackgroundTransparency = 1
title.Text = cfg.name
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)

local close = Instance.new("TextButton", top)
close.Size = UDim2.new(0,32,1,0)
close.Position = UDim2.new(1,-32,0,0)
close.BackgroundTransparency = 1
close.Text = "X"
close.Font = Enum.Font.SourceSansBold
close.TextSize = 18
close.TextColor3 = Color3.new(1,1,1)

local box = Instance.new("TextBox", main)
box.Size = UDim2.new(.9,0,0,30)
box.Position = UDim2.new(.05,0,0,43)
box.BackgroundColor3 = Color3.fromHex("#1d2f49")
box.BorderSizePixel = 0
box.PlaceholderText = cfg.free and 'Enter Key (Premium) or "FREE"' or "Enter Key Here"
box.Text = ""
box.Font = Enum.Font.SourceSansBold
box.TextSize = 16
box.TextColor3 = Color3.new(1,1,1)

local get = Instance.new("TextButton", main)
get.Size = UDim2.new(.43,0,0,30)
get.Position = UDim2.new(.05,0,.96,-40)
get.BackgroundColor3 = Color3.fromHex("#23456d")
get.BorderSizePixel = 0
get.Text = "Get Key"
get.Font = Enum.Font.SourceSansBold
get.TextSize = 16
get.TextColor3 = Color3.new(1,1,1)

local enter = Instance.new("TextButton", main)
enter.Size = UDim2.new(.43,0,0,30)
enter.Position = UDim2.new(.516,0,.96,-40)
enter.BackgroundColor3 = Color3.fromHex("#23456d")
enter.BorderSizePixel = 0
enter.Text = "Enter"
enter.Font = Enum.Font.SourceSansBold
enter.TextSize = 16
enter.TextColor3 = Color3.new(1,1,1)

close.MouseButton1Click:Connect(function()
	g:Destroy()
end)

get.MouseButton1Click:Connect(function()
	setclipboard(cfg.key)
end)

enter.MouseButton1Click:Connect(function()
	local key = box.Text

	if key and key:gsub("%s","") ~= "" then
		g:Destroy()

		if cfg.free and key:upper() == "FREE" then
			loadstring(game:HttpGet(cfg.free.load, true))()
			return
		end

		getgenv().script_key = key

		loadstring(game:HttpGet(cfg.load, true))()
	end
end)
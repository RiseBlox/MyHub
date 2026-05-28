local p = game:GetService("Players").LocalPlayer
local g = Instance.new("ScreenGui", p:WaitForChild("PlayerGui"))
g.Name = "KeyUI"
g.ResetOnSpawn = false

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
top.BackgroundColor3 = Color3.fromHex("#02ba4b")
top.BorderSizePixel = 0

local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(1,-64,1,0)
title.Position = UDim2.new(0,32,0,0)
title.BackgroundTransparency = 1
title.Text = "Vynixius"
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
box.BackgroundColor3 = Color3.fromHex("#015e26")
box.BorderSizePixel = 0
box.PlaceholderText = "Enter Key Here"
box.Text = ""
box.Font = Enum.Font.SourceSansBold
box.TextSize = 16
box.TextColor3 = Color3.new(1,1,1)

local get = Instance.new("TextButton", main)
get.Size = UDim2.new(.43,0,0,30)
get.Position = UDim2.new(.05,0,.96,-40)
get.BackgroundColor3 = Color3.fromHex("#02ba4b")
get.BorderSizePixel = 0
get.Text = "Get Key"
get.Font = Enum.Font.SourceSansBold
get.TextSize = 16
get.TextColor3 = Color3.new(1,1,1)

local enter = Instance.new("TextButton", main)
enter.Size = UDim2.new(.43,0,0,30)
enter.Position = UDim2.new(.516,0,.96,-40)
enter.BackgroundColor3 = Color3.fromHex("#02ba4b")
enter.BorderSizePixel = 0
enter.Text = "Enter"
enter.Font = Enum.Font.SourceSansBold
enter.TextSize = 16
enter.TextColor3 = Color3.new(1,1,1)

close.MouseButton1Click:Connect(function()
	g:Destroy()
end)

get.MouseButton1Click:Connect(function()
	setclipboard("https://vynixius.win/getkey")
end)

enter.MouseButton1Click:Connect(function()
	local key = box.Text

	if key and key:gsub("%s","") ~= "" then
		getgenv().script_key = key

		g:Destroy()

		loadstring(game:HttpGet("https://vynixius.win/loader.luau"))()
	end
end)
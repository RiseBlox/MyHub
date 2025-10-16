if not game:IsLoaded() then
	game.Loaded:Wait()
end
---
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
---
local function safeDestroy(obj)
	if obj and obj.Destroy then
		pcall(function() obj:Destroy() end)
	end
end
---
local function stripCharacter(char)
	for _, c in ipairs(char:GetChildren()) do
		if c:IsA("Decal") or c:IsA("Texture") then
			local ok = pcall(function() safeDestroy(c) end)
			if not ok then
				c.Transparency = 1
				if c:IsA("Decal") then c.Texture = "" end
			end
		elseif c:IsA("ParticleEmitter") or c:IsA("Trail") or c:IsA("Fire") or c:IsA("Smoke") or c:IsA("Sparkles") then
			local ok = pcall(function() safeDestroy(c) end)
			if not ok then
				c.Enabled = false
				if c.Lifetime then c.Lifetime = NumberRange.new(0) end
				if c.Opacity then c.Opacity = NumberSequence.new(0) end
			end
		end
	end
end
---
local function optimizeTerrain()
	local Terrain = Workspace:FindFirstChildWhichIsA("Terrain")
	if Terrain then
		Terrain.WaterWaveSize = 0
		Terrain.WaterWaveSpeed = 0
		Terrain.WaterReflectance = 0
		Terrain.WaterTransparency = 1
	end
end
---
local function optimizeObject(obj)
	if obj:IsA("BasePart") then
		if obj.Transparency == 1 and obj.CanCollide == false then return end
		obj.Material = Enum.Material.Plastic
		obj.Reflectance = 0
		obj.CastShadow = false
		pcall(function()
			obj.BackSurface = Enum.SurfaceType.SmoothNoOutlines
			obj.BottomSurface = Enum.SurfaceType.SmoothNoOutlines
			obj.FrontSurface = Enum.SurfaceType.SmoothNoOutlines
			obj.LeftSurface = Enum.SurfaceType.SmoothNoOutlines
			obj.RightSurface = Enum.SurfaceType.SmoothNoOutlines
			obj.TopSurface = Enum.SurfaceType.SmoothNoOutlines
		end)
	elseif obj:IsA("Decal") or obj:IsA("Texture") then
		local ok = pcall(function() safeDestroy(obj) end)
		if not ok then
			obj.Transparency = 1
			if obj:IsA("Decal") then obj.Texture = "" end
		end
	elseif
		obj:IsA("Beam")
		or obj:IsA("Explosion")
		or obj:IsA("Fire")
		or obj:IsA("Highlight")
		or obj:IsA("ParticleEmitter")
		or obj:IsA("Smoke")
		or obj:IsA("Sparkles")
		or obj:IsA("Trail")
		or obj:IsA("WrapLayer")
		or obj:IsA("WrapTarget")
		or obj:IsA("Atmosphere")
		or obj:IsA("Clouds")
		or obj:IsA("Sky")
		or obj:IsA("PointLight")
		or obj:IsA("SpotLight")
		or obj:IsA("SurfaceLight")
		or obj:IsA("BloomEffect")
		or obj:IsA("BlurEffect")
		or obj:IsA("ColorCorrectionEffect")
		or obj:IsA("DepthOfFieldEffect")
		or obj:IsA("SunRaysEffect")
	then
		local ok = pcall(function() safeDestroy(obj) end)
		if not ok then
			if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
				obj.Enabled = false
				if obj.Lifetime then obj.Lifetime = NumberRange.new(0) end
				if obj.Opacity then obj.Opacity = NumberSequence.new(0) end
			elseif obj:IsA("Beam") then
				obj.Enabled = false
				obj.Width0 = 0
				obj.Width1 = 0
				obj.LightEmission = 0
			elseif obj:IsA("Explosion") then
				obj.BlastPressure = 0
				obj.BlastRadius = 0
				obj.Visible = false
			elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
				obj.Enabled = false
				if obj.Size then obj.Size = 0 end
				if obj.Opacity then obj.Opacity = 0 end
			elseif obj:IsA("Highlight") then
				obj.Enabled = false
				obj.FillTransparency = 1
				obj.OutlineTransparency = 1
			elseif obj:IsA("PointLight") or obj:IsA("SpotLight") or obj:IsA("SurfaceLight") then
				obj.Enabled = false
				obj.Brightness = 0
				obj.Range = 0
			elseif obj:IsA("Atmosphere") or obj:IsA("Clouds") or obj:IsA("Sky") then
				obj.Parent = nil
			elseif obj:IsA("BloomEffect") or obj:IsA("BlurEffect") or obj:IsA("ColorCorrectionEffect")
				or obj:IsA("DepthOfFieldEffect") or obj:IsA("SunRaysEffect") then
				obj.Enabled = false
			end
		end
	end
end
---
local function applyLighting()
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.FogEnd = 9e9
	Lighting.FogStart = 9e9
	Lighting.GlobalShadows = false
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end
---
local function streamedOptimize()
	local all = Workspace:GetDescendants()
	local count = 0
	for _, v in ipairs(all) do
		optimizeObject(v)
		count += 1
		if count % 200 == 0 then
			RunService.Heartbeat:Wait()
		end
	end
end
---
if brightLoop then brightLoop:Disconnect() end
---
brightLoop = RunService.RenderStepped:Connect(function()
	applyLighting()
end)
---
local function hookCharacter(char)
	stripCharacter(char)
	char.DescendantAdded:Connect(function(obj)
		task.defer(function()
			optimizeObject(obj)
		end)
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then hookCharacter(plr.Character) end
	plr.CharacterAdded:Connect(hookCharacter)
end
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(hookCharacter)
end)
---
Workspace.DescendantAdded:Connect(function(obj)
	task.defer(function()
		optimizeObject(obj)
	end)
end)
---
Lighting.ChildAdded:Connect(function(obj)
	if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
		safeDestroy(obj)
	elseif obj:IsA("PostEffect") then
		local ok = pcall(function() safeDestroy(obj) end)
		if not ok then obj.Enabled = false end
	end
end)
---
applyLighting()
optimizeTerrain()
streamedOptimize()

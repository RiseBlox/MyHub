if not game:IsLoaded() then
	game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Safe destroy
local function safeDestroy(obj)
	if obj and obj.Destroy then
		pcall(function() obj:Destroy() end)
	end
end

-- Minimal gray sky
local function setGraySky()
	for _, s in ipairs(Lighting:GetChildren()) do
		if s:IsA("Sky") then safeDestroy(s) end
	end
	local sky = Instance.new("Sky")
	sky.SkyboxBk, sky.SkyboxDn, sky.SkyboxFt = "", "", ""
	sky.SkyboxLf, sky.SkyboxRt, sky.SkyboxUp = "", "", ""
	sky.CelestialBodiesShown = false
	sky.SunTextureId, sky.MoonTextureId = "", ""
	sky.Parent = Lighting
end

-- Character cleaner (keeps accessories/clothing)
local function stripCharacter(char)
	for _, c in ipairs(char:GetChildren()) do
		if c:IsA("Decal") or c:IsA("Texture") then
			local ok = pcall(function() safeDestroy(c) end)
			if not ok and c:IsA("Decal") then
				c.Transparency = 1
				c.Texture = ""
			end
		elseif c:IsA("ParticleEmitter") or c:IsA("Trail") then
			local ok = pcall(function() safeDestroy(c) end)
			if not ok then
				c.Enabled = false
				c.Lifetime = NumberRange.new(0)
			end
		end
	end
end

-- Terrain optimization (from IY)
local function optimizeTerrain()
	local Terrain = Workspace:FindFirstChildWhichIsA("Terrain")
	if Terrain then
		Terrain.WaterWaveSize = 0
		Terrain.WaterWaveSpeed = 0
		Terrain.WaterReflectance = 0
		Terrain.WaterTransparency = 1
	end
end

-- Object optimization (merged logic)
local function optimizeObject(obj)
	if obj:IsA("BasePart") then
		if obj.Transparency == 1 and obj.CanCollide == false then return end
		obj.Material = Enum.Material.Plastic
		obj.Reflectance = 0
		obj.CastShadow = false
		-- Make surfaces smooth
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
	elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
		local ok = pcall(function() safeDestroy(obj) end)
		if not ok then
			obj.Enabled = false
			obj.Lifetime = NumberRange.new(0)
		end
	elseif obj:IsA("ForceField") or obj:IsA("Sparkles") or obj:IsA("Smoke")
		or obj:IsA("Fire") or obj:IsA("Beam") then
		safeDestroy(obj)
	elseif obj:IsA("Atmosphere")
		or obj:IsA("BloomEffect")
		or obj:IsA("BlurEffect")
		or obj:IsA("ColorCorrectionEffect")
		or obj:IsA("DepthOfFieldEffect")
		or obj:IsA("SunRaysEffect")
		or obj:IsA("ColorGradingEffect")
		or obj:IsA("PostEffect") then
		local ok = pcall(function() safeDestroy(obj) end)
		if not ok then
			obj.Enabled = false
		end
	end
end

-- Fullbright lighting baseline
local function applyLighting()
	Lighting.Brightness = 2
	Lighting.ClockTime = 14
	Lighting.FogEnd = 9e9
	Lighting.FogStart = 9e9
	Lighting.GlobalShadows = false
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	setGraySky()
end

-- Streamed optimization pass
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

-- Disconnect any old loops
if brightLoop then brightLoop:Disconnect() end
if charLoop then charLoop:Disconnect() end

-- Continuous lighting + terrain loop
brightLoop = RunService.RenderStepped:Connect(function()
	applyLighting()
	optimizeTerrain()
end)

-- Continuous character cleanup
charLoop = RunService.RenderStepped:Connect(function()
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr.Character then
			stripCharacter(plr.Character)
		end
	end
end)

-- Hooks for new objects
Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(stripCharacter)
end)

Workspace.DescendantAdded:Connect(function(obj)
	task.defer(function()
		optimizeObject(obj)
	end)
end)

Lighting.ChildAdded:Connect(function(obj)
	if obj:IsA("Sky") then
		safeDestroy(obj)
		setGraySky()
	elseif obj:IsA("PostEffect") or obj:IsA("Atmosphere") then
		local ok = pcall(function() safeDestroy(obj) end)
		if not ok then obj.Enabled = false end
	end
end)

-- Initial pass
applyLighting()
optimizeTerrain()
streamedOptimize()
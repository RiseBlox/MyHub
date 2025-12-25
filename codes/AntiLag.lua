local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

pcall(function()
	settings().Rendering.QualityLevel = 3
end)

local function applyLighting()
	Lighting.LightingStyle = Enum.LightingStyle.Soft
	Lighting.Technology = Enum.Technology.Voxel
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	Lighting.FogStart = 9e9
end

applyLighting()

Lighting.Changed:Connect(function()
	task.defer(applyLighting)
end)

for _, v in ipairs(Lighting:GetDescendants()) do
	if v:IsA("PostEffect") then
		v.Enabled = false
	end
end

Lighting.ChildAdded:Connect(function(obj)
	if obj:IsA("PostEffect") then
		obj.Enabled = false
	elseif obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
		obj.Enabled = false
	end
end)

local Terrain = Workspace:FindFirstChildWhichIsA("Terrain")
if Terrain then
	Terrain.WaterWaveSize = 0
	Terrain.WaterWaveSpeed = 0
	Terrain.WaterReflectance = 0
	Terrain.WaterTransparency = 1
end

for _, v in ipairs(Workspace:GetDescendants()) do
	if v:IsA("BasePart") then
		v.CastShadow = false
		v.Material = Enum.Material.Plastic
		v.Reflectance = 0
	end
end

local function throttleEffect(obj)
	if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
		obj.Lifetime = NumberRange.new(0)
	elseif obj:IsA("Beam") then
		obj.Enabled = false
	elseif obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
		obj.Enabled = false
	end
end

for _, v in ipairs(Workspace:GetDescendants()) do
	throttleEffect(v)
end

local function hookCharacter(char)
	for _, v in ipairs(char:GetDescendants()) do
		throttleEffect(v)
	end

	char.DescendantAdded:Connect(function(obj)
		throttleEffect(obj)
	end)
end

for _, plr in ipairs(Players:GetPlayers()) do
	if plr.Character then
		hookCharacter(plr.Character)
	end
	plr.CharacterAdded:Connect(hookCharacter)
end

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(hookCharacter)
end)

Workspace.DescendantAdded:Connect(function(obj)
	task.defer(function()
		if obj:IsA("BasePart") then
			obj.CastShadow = false
		elseif
			obj:IsA("ParticleEmitter")
			or obj:IsA("Trail")
			or obj:IsA("Fire")
			or obj:IsA("Smoke")
			or obj:IsA("Sparkles")
			or obj:IsA("Beam")
		then
			throttleEffect(obj)
		end
	end)
end)
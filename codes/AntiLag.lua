if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

------------------------------------------------------------------
-- UTILITIES
------------------------------------------------------------------

local function safeDestroy(obj)
    if obj and obj.Destroy then
        pcall(function() obj:Destroy() end)
    end
end

------------------------------------------------------------------
-- LIGHTING (one-time, not per-frame)
------------------------------------------------------------------

local function hardLighting()
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 1e9
    Lighting.FogStart = 1e9
    Lighting.GlobalShadows = false
    Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
end

Lighting.Changed:Connect(function()
    task.defer(hardLighting)
end)

hardLighting()

------------------------------------------------------------------
-- CHARACTER OPTIMIZATION (NO DECAL/TEXTURE REMOVAL)
------------------------------------------------------------------

local EFFECT_CLASSES = {
    ParticleEmitter = true,
    Trail = true,
    Fire = true,
    Smoke = true,
    Sparkles = true,
    Beam = true,
    Highlight = true
}

local function cleanCharacter(char)
    for _, obj in ipairs(char:GetDescendants()) do
        if EFFECT_CLASSES[obj.ClassName] then
            safeDestroy(obj)
        end
    end

    char.DescendantAdded:Connect(function(obj)
        if EFFECT_CLASSES[obj.ClassName] then
            task.defer(function()
                safeDestroy(obj)
            end)
        end
    end)
end

for _, plr in ipairs(Players:GetPlayers()) do
    if plr.Character then cleanCharacter(plr.Character) end
    plr.CharacterAdded:Connect(cleanCharacter)
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(cleanCharacter)
end)

------------------------------------------------------------------
-- ENVIRONMENT OPTIMIZATION (BATCHED, DECALS/TEXTURES SAFE)
------------------------------------------------------------------

local function batchOptimize()
    local targetClasses = {
        ["Explosion"] = true,
        ["Atmosphere"] = true,
        ["Clouds"] = true,
        ["Sky"] = true,
        ["BloomEffect"] = true,
        ["BlurEffect"] = true,
        ["ColorCorrectionEffect"] = true,
        ["DepthOfFieldEffect"] = true,
        ["SunRaysEffect"] = true,
        ["Smoke"] = true,
        ["Fire"] = true,
        ["Sparkles"] = true,
        ["Beam"] = true
    }

    local objects = Workspace:GetDescendants()
    local n = #objects

    for i = 1, n do
        local obj = objects[i]
        local class = obj.ClassName

        if targetClasses[class] then
            safeDestroy(obj)

        elseif obj:IsA("BasePart") then
            obj.CastShadow = false
            obj.Reflectance = 0
            obj.Material = Enum.Material.Plastic
        end

        if i % 300 == 0 then
            RunService.Heartbeat:Wait()
        end
    end
end

task.spawn(batchOptimize)

------------------------------------------------------------------
-- TERRAIN STREAMLINING
------------------------------------------------------------------

local Terrain = Workspace:FindFirstChildWhichIsA("Terrain")
if Terrain then
    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 1
end

------------------------------------------------------------------
-- LIGHTING OVERRIDE FOR NEW CHILDREN
------------------------------------------------------------------

Lighting.ChildAdded:Connect(function(obj)
    if obj:IsA("Sky") or obj:IsA("Atmosphere") or obj:IsA("Clouds") then
        safeDestroy(obj)
    elseif obj:IsA("PostEffect") then
        safeDestroy(obj)
    end
end)
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local function safeDestroy(obj)
    if obj and obj.Destroy then
        pcall(function() obj:Destroy() end)
    end
end

-- 🪐 Minimal gray sky
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

-- 🧍 Strip cosmetics from characters
local function stripCharacter(char)
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Accessory") or c:IsA("Shirt") or c:IsA("Pants")
        or c:IsA("Clothing") or c:IsA("BodyColors") or c:IsA("ShirtGraphic") then
            safeDestroy(c)
        elseif c:IsA("Decal") or c:IsA("Texture") then
            safeDestroy(c)
        elseif c:IsA("ParticleEmitter") or c:IsA("Trail") then
            c.Enabled = false
        end
    end
end

-- 🏗️ Optimize one object
local function optimizeObject(obj)
    if obj:IsA("BasePart") then
        if obj.Transparency == 1 and obj.CanCollide == false then return end -- skip invisible hitboxes
        obj.Material = Enum.Material.Plastic
        obj.Reflectance = 0
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        safeDestroy(obj)
    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
        obj.Enabled = false
    elseif obj:IsA("ForceField") or obj:IsA("Sparkles")
        or obj:IsA("Smoke") or obj:IsA("Fire")
        or obj:IsA("Beam") then
        safeDestroy(obj)
    elseif obj:IsA("PostEffect") or obj:IsA("Atmosphere") then
        safeDestroy(obj)
    end
end

-- 🌀 Streamed optimizer (one-time for map)
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

-- 🌌 Lighting baseline
local function lockLighting()
    Lighting.GlobalShadows = false
    Lighting.FogEnd, Lighting.FogStart = 9e9, 9e9
    Lighting.TimeOfDay = "14:00:00"
    setGraySky()
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    end)
end

-- 🔌 Hooks
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
        safeDestroy(obj)
    end
end)

-- 🚀 Initial run
lockLighting()
streamedOptimize()

-- 🔁 Character auto-clean every 5s
task.spawn(function()
    while true do
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr.Character then stripCharacter(plr.Character) end
        end
        task.wait(5)
    end
end)

-- 🔁 Lighting enforcement every 3s
task.spawn(function()
    while true do
        lockLighting()
        task.wait(3)
    end
end)

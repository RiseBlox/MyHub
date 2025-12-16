local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")

local Settings = {
    Enabled = true,
    TeamCheck = true,
    WallCheck = true,
    DeathCheck = true,
    ForceFieldCheck = true,
    HitChance = 100,
    MissSpread = 0,
    FOV = 150,
    ShowFOV = true,
    ShowTargetLine = false,
    AimPart = "Head",
    RandomAimParts = false,
    AimPartsList = {"Head", "Torso", "HumanoidRootPart", "LeftArm", "RightArm", "LeftLeg", "RightLeg"}
}

local GunRemotes = ReplicatedStorage:WaitForChild("GunRemotes", 5)
local ShootEvent = GunRemotes and GunRemotes:WaitForChild("ShootEvent", 5)
if not ShootEvent then return end

local WallCheckParams = RaycastParams.new()
WallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
WallCheckParams.IgnoreWater = true
WallCheckParams.RespectCanCollide = false

local FOVCircle = nil
local TargetLine = nil
local IsShooting = false
local LastShot = 0
local CurrentTarget = nil
local LastTargetUpdate = 0
local TARGET_UPDATE_INTERVAL = 0.05

local TracerPool = {
    bullets = {},
    tasers = {},
    maxPoolSize = 20
}

local function GetPooledPart(pool, createFunc)
    for i, part in ipairs(pool) do
        if not part.Parent then
            return table.remove(pool, i)
        end
    end
    if #pool < TracerPool.maxPoolSize then
        return createFunc()
    end
    return createFunc()
end

local function ReturnToPool(pool, part)
    part.Parent = nil
    if #pool < TracerPool.maxPoolSize then
        table.insert(pool, part)
    else
        part:Destroy()
    end
end

local function CreateBaseBulletPart()
    local bullet = Instance.new("Part")
    bullet.Name = "PooledBullet"
    bullet.Anchored = true
    bullet.CanCollide = false
    bullet.CastShadow = false
    bullet.Material = Enum.Material.Neon
    bullet.BrickColor = BrickColor.Yellow()
    
    local mesh = Instance.new("BlockMesh", bullet)
    mesh.Scale = Vector3.new(0.5, 0.5, 1)
    
    return bullet
end

local function CreateBaseTaserPart()
    local bullet = Instance.new("Part")
    bullet.Name = "PooledTaser"
    bullet.Anchored = true
    bullet.CanCollide = false
    bullet.CastShadow = false
    bullet.Material = Enum.Material.Neon
    bullet.BrickColor = BrickColor.new("Cyan")
    
    local mesh = Instance.new("BlockMesh", bullet)
    mesh.Scale = Vector3.new(0.8, 0.8, 1)
    
    local light = Instance.new("SurfaceLight", bullet)
    light.Name = "TaserLight"
    light.Color = Color3.fromRGB(0, 234, 255)
    light.Range = 7
    light.Face = Enum.NormalId.Bottom
    light.Angle = 180
    
    return bullet
end

for i = 1, 5 do
    table.insert(TracerPool.bullets, CreateBaseBulletPart())
    table.insert(TracerPool.tasers, CreateBaseTaserPart())
end

if Drawing and Drawing.new then
    pcall(function()
        FOVCircle = Drawing.new("Circle")
        FOVCircle.Color = Color3.fromRGB(255, 0, 0)
        FOVCircle.Thickness = 2
        FOVCircle.Filled = false
        FOVCircle.Radius = Settings.FOV
        FOVCircle.Visible = true
        FOVCircle.NumSides = 64

        TargetLine = Drawing.new("Line")
        TargetLine.Color = Color3.fromRGB(0, 255, 0)
        TargetLine.Thickness = 2
        TargetLine.Visible = false
    end)
end

local PartMappings = {
    ["Torso"] = {"Torso", "UpperTorso", "LowerTorso"},
    ["LeftArm"] = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    ["RightArm"] = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    ["LeftLeg"] = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    ["RightLeg"] = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
}

local function GetBodyPart(character, partName)
    if not character then return nil end
    
    local directPart = character:FindFirstChild(partName)
    if directPart then return directPart end

    local mappings = PartMappings[partName]
    if mappings then
        for _, name in ipairs(mappings) do
            local part = character:FindFirstChild(name)
            if part then return part end
        end
    end

    return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
end

local function GetTargetPart(character)
    if not character then return nil end
    local partName
    if Settings.RandomAimParts then
        local partsList = Settings.AimPartsList
        partName = (partsList and #partsList > 0) and partsList[math.random(1, #partsList)] or "Head"
    else
        partName = Settings.AimPart
    end
    return GetBodyPart(character, partName)
end

local function GetMissPosition(targetPos)
    local x = math.random(-100, 100)
    local y = math.random(-100, 100)
    local z = math.random(-100, 100)
    local mag = math.sqrt(x*x + y*y + z*z)
    if mag > 0 then
        x, y, z = x/mag, y/mag, z/mag
    end
    return targetPos + Vector3.new(x * Settings.MissSpread, y * Settings.MissSpread, z * Settings.MissSpread)
end

local ActiveSounds = {}
local function PlayGunSound(gun)
    if not gun then return end
    local handle = gun:FindFirstChild("Handle")
    if not handle then return end

    local shootSound = handle:FindFirstChild("ShootSound")
    if shootSound then
        local soundKey = gun:GetFullName() .. "_shoot"
        local sound = ActiveSounds[soundKey]
        
        if not sound or not sound.Parent then
            sound = shootSound:Clone()
            sound.Parent = handle
            ActiveSounds[soundKey] = sound
        end
        
        sound:Play()
    end

    local isShotgun = gun:GetAttribute("IsShotgun")
    local secondary = handle:FindFirstChild("SecondarySound")
    
    if isShotgun and secondary then
        task.delay(0.2, function()
            if handle and handle.Parent then
                local soundKey = gun:GetFullName() .. "_secondary"
                local sound = ActiveSounds[soundKey]
                
                if not sound or not sound.Parent then
                    sound = secondary:Clone()
                    sound.Parent = handle
                    ActiveSounds[soundKey] = sound
                end
                
                sound:Play()
            end
        end)
    end
end

local function CreateTaserTracer(startPos, endPos, gun)
    local distance = (endPos - startPos).Magnitude
    
    local bullet = GetPooledPart(TracerPool.tasers, CreateBaseTaserPart)
    bullet.Transparency = 0.5
    bullet.Size = Vector3.new(0.2, 0.2, distance)
    bullet.CFrame = CFrame.new(endPos, startPos) * CFrame.new(0, 0, -distance / 2)
    bullet.Parent = workspace
    
    local light = bullet:FindFirstChild("TaserLight")
    if light then
        light.Brightness = 5
    end
    
    local tweenInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local bulletTween = TweenService:Create(bullet, tweenInfo, { Transparency = 1 })
    
    if light then
        local lightTween = TweenService:Create(light, tweenInfo, { Brightness = 0 })
        lightTween:Play()
    end
    
    bulletTween:Play()
    bulletTween.Completed:Once(function()
        ReturnToPool(TracerPool.tasers, bullet)
    end)
    
    if gun then
        local handle = gun:FindFirstChild("Handle")
        if handle then
            local flare = handle:FindFirstChild("Flare")
            if flare then
                flare.Enabled = true
                task.delay(0.05, function() 
                    if flare then flare.Enabled = false end 
                end)
            end
        end
    end
end

local function CreateBulletTracer(startPos, endPos, gun)
    local distance = (endPos - startPos).Magnitude
    
    local bullet = GetPooledPart(TracerPool.bullets, CreateBaseBulletPart)
    bullet.Transparency = 0.5
    bullet.Size = Vector3.new(0.2, 0.2, distance)
    bullet.CFrame = CFrame.new(endPos, startPos) * CFrame.new(0, 0, -distance / 2)
    bullet.Parent = workspace
    
    task.delay(0.05, function()
        ReturnToPool(TracerPool.bullets, bullet)
    end)
    
    if gun then
        local handle = gun:FindFirstChild("Handle")
        if handle then
            local flare = handle:FindFirstChild("Flare")
            if flare then
                flare.Enabled = true
                task.delay(0.05, function() 
                    if flare then flare.Enabled = false end 
                end)
            end
        end
    end
end

local function CreateProjectileTracer(startPos, endPos, gun)
    if not gun then return end
    if gun:GetAttribute("Projectile") == "Taser" then
        CreateTaserTracer(startPos, endPos, gun)
    else
        CreateBulletTracer(startPos, endPos, gun)
    end
end

local function IsPlayerDead(plr)
    if not plr or not plr.Character then return true end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    return not hum or hum.Health <= 0
end

local function HasForceField(plr)
    if not plr or not plr.Character then return false end
    return plr.Character:FindFirstChildOfClass("ForceField") ~= nil
end

local function IsWallBetween(startPos, endPos, targetCharacter)
    local myChar = LocalPlayer.Character
    if not myChar then return true end
    
    WallCheckParams.FilterDescendantsInstances = { myChar }
    local direction = endPos - startPos
    local distance = direction.Magnitude
    local result = workspace:Raycast(startPos, direction.Unit * distance, WallCheckParams)

    if not result then return false end
    
    local hitPart = result.Instance
    if targetCharacter and hitPart:IsDescendantOf(targetCharacter) then return false end

    if hitPart.Transparency >= 0.8 or not hitPart.CanCollide then
        local newStart = result.Position + direction.Unit * 0.1
        local remainingDist = (endPos - newStart).Magnitude
        if remainingDist > 0.5 then
            local newResult = workspace:Raycast(newStart, direction.Unit * remainingDist, WallCheckParams)
            if not newResult then return false end
            if targetCharacter and newResult.Instance:IsDescendantOf(targetCharacter) then return false end
        else
            return false
        end
    end
    return true
end

local function IsValidTargetQuick(plr)
    if not plr or plr == LocalPlayer or not plr.Character then return false end
    if not GetTargetPart(plr.Character) then return false end
    if Settings.DeathCheck and IsPlayerDead(plr) then return false end
    if Settings.ForceFieldCheck and HasForceField(plr) then return false end
    if Settings.TeamCheck and plr.Team == LocalPlayer.Team then return false end
    return true
end

local function IsValidTargetFull(plr)
    if not IsValidTargetQuick(plr) then return false end
    
    if Settings.WallCheck then
        local myChar = LocalPlayer.Character
        local myHead = myChar and myChar:FindFirstChild("Head")
        local targetPart = GetTargetPart(plr.Character)
        if myHead and targetPart then
            if IsWallBetween(myHead.Position, targetPart.Position, plr.Character) then 
                return false 
            end
        end
    end
    return true
end

local function RollHitChance()
    if Settings.HitChance >= 100 then return true end
    if Settings.HitChance <= 0 then return false end
    return math.random(1, 100) <= Settings.HitChance
end

local function GetClosestTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    
    local mousePos = UserInputService:GetMouseLocation()
    local candidates = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTargetQuick(plr) then
            local targetPart = GetTargetPart(plr.Character)
            if targetPart then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                    if dist < Settings.FOV then
                        table.insert(candidates, {player = plr, distance = dist})
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b) return a.distance < b.distance end)

    for _, candidate in ipairs(candidates) do
        if IsValidTargetFull(candidate.player) then
            return candidate.player
        end
    end
    
    return nil
end

local function GetEquippedGun()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gun" then
            return tool
        end
    end
    return nil
end

local CachedBulletsLabel = nil
local function UpdateAmmoGUI(ammo, maxAmmo)
    if not CachedBulletsLabel or not CachedBulletsLabel.Parent then
        local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
        if not playerGui then return end
        local home = playerGui:FindFirstChild("Home")
        if not home then return end
        local hud = home:FindFirstChild("hud")
        if not hud then return end
        local gunFrame = hud:FindFirstChild("BottomRightFrame") and hud.BottomRightFrame:FindFirstChild("GunFrame")
        if not gunFrame then return end
        CachedBulletsLabel = gunFrame:FindFirstChild("BulletsLabel")
    end
    
    if CachedBulletsLabel then
        CachedBulletsLabel.Text = ammo .. "/" .. maxAmmo
    end
end

local function FireSilentAim(gun)
    local ammo = gun:GetAttribute("Local_CurrentAmmo") or 0
    if ammo <= 0 then return false end

    local fireRate = gun:GetAttribute("FireRate") or 0.12
    local now = tick()
    if now - LastShot < fireRate then return false end

    local char = LocalPlayer.Character
    local myHead = char and char:FindFirstChild("Head")
    if not myHead then return false end

    local hitPos, hitPart

    if Settings.Enabled and CurrentTarget and CurrentTarget.Character and IsValidTargetFull(CurrentTarget) then
        local targetPart = GetTargetPart(CurrentTarget.Character)
        if targetPart then
            if RollHitChance() then
                hitPos = targetPart.Position
                hitPart = targetPart
            else
                hitPos = GetMissPosition(targetPart.Position)
                hitPart = nil
            end
        end
    end

    if not hitPos then
        local mousePos = UserInputService:GetMouseLocation()
        local camera = workspace.CurrentCamera
        local ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        
        WallCheckParams.FilterDescendantsInstances = {char}
        local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, WallCheckParams)
        
        if result then
            hitPos = result.Position
            hitPart = result.Instance
        else
            hitPos = ray.Origin + (ray.Direction * 1000)
        end
    end

    gun:SetAttribute("Local_IsShooting", true)

    local muzzle = gun:FindFirstChild("Muzzle")
    local visualStart = muzzle and muzzle.Position or myHead.Position
    
    local projectileCount = gun:GetAttribute("ProjectileCount") or 1
    local bullets = table.create(projectileCount)
    for i = 1, projectileCount do
        bullets[i] = { myHead.Position, hitPos, hitPart }
    end

    LastShot = now

    PlayGunSound(gun)

    for i = 1, projectileCount do
        local ox = math.random(-10, 10) / 100
        local oy = math.random(-10, 10) / 100
        local oz = math.random(-10, 10) / 100
        CreateProjectileTracer(visualStart, hitPos + Vector3.new(ox, oy, oz), gun)
    end

    ShootEvent:FireServer(bullets)

    local newAmmo = ammo - 1
    gun:SetAttribute("Local_CurrentAmmo", newAmmo)
    UpdateAmmoGUI(newAmmo, gun:GetAttribute("MaxAmmo") or 0)

    return true
end

local function HandleAction(actionName, inputState, inputObject)
    if actionName == "SilentAimShoot" then
        if inputState == Enum.UserInputState.Begin then
            local gun = GetEquippedGun()
            if not gun then 
                return Enum.ContextActionResult.Pass 
            end
            
            if not gun:GetAttribute("AutoFire") then
                IsShooting = true
                FireSilentAim(gun)
                IsShooting = false
            else
                IsShooting = true
            end
            
            return Enum.ContextActionResult.Sink
        elseif inputState == Enum.UserInputState.End then
            IsShooting = false
            return Enum.ContextActionResult.Sink
        end
    end
    return Enum.ContextActionResult.Pass
end

ContextActionService:BindActionAtPriority("SilentAimShoot", HandleAction, false, 3000, Enum.UserInputType.MouseButton1)

RunService.RenderStepped:Connect(function()
    local mousePos = UserInputService:GetMouseLocation()
    
    if FOVCircle then
        FOVCircle.Position = mousePos
        FOVCircle.Radius = Settings.FOV
        FOVCircle.Visible = Settings.ShowFOV and Settings.Enabled
    end

    local now = tick()
    if Settings.Enabled and (now - LastTargetUpdate) >= TARGET_UPDATE_INTERVAL then
        LastTargetUpdate = now
        CurrentTarget = GetClosestTarget()
    elseif not Settings.Enabled then
        CurrentTarget = nil
    end

    if TargetLine then
        if Settings.ShowTargetLine and CurrentTarget and CurrentTarget.Character then
            local targetPart = GetTargetPart(CurrentTarget.Character)
            if targetPart then
                local camera = workspace.CurrentCamera
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    TargetLine.From = mousePos
                    TargetLine.To = Vector2.new(screenPos.X, screenPos.Y)
                    TargetLine.Visible = Settings.Enabled
                else
                    TargetLine.Visible = false
                end
            else
                TargetLine.Visible = false
            end
        else
            TargetLine.Visible = false
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if not IsShooting then return end
    local gun = GetEquippedGun()
    if gun and gun:GetAttribute("AutoFire") then
        FireSilentAim(gun)
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    CachedBulletsLabel = nil
    CurrentTarget = nil
    IsShooting = false
    
    for key, sound in pairs(ActiveSounds) do
        if sound and sound.Parent then
            sound:Destroy()
        end
    end
    table.clear(ActiveSounds)
end)

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Prison Life Silent Aim",
        Text = "Successfully loaded!",
        Duration = 5,
    })
end)
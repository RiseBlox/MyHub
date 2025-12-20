local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local Teams = game:GetService("Teams")

local Settings = {
    Enabled = true,
    TeamCheck = true,
    WallCheck = true,
    DeathCheck = true,
    ForceFieldCheck = true,
    HostileCheck = true,
    TrespassingCheck = true,
    VehicleCheck = true,
    TaserBypassHostile = true,
    TaserBypassTrespassing = true,
    TaserAlwaysHit = true,
    IfPlayerIsStill = true,
    StationaryThreshold = 0.5,
    HitChance = 100,
    MissSpread = 0,
    FOV = 150,
    ShowFOV = true,
    ShowTargetLine = false,
    AimPart = "Head",
    RandomAimParts = false,
    AimPartsList = {"Torso", "HumanoidRootPart", "LeftArm", "RightArm"},
    ESPEnabled = true,
    ESPTeamCheck = true,
    ESPTargets = {
        Guards = true,
        Inmates = true,
        Criminals = true
    },
    ESPMaxDistance = 500,
    ESPShowDistance = true,
    ESPColor = Color3.fromRGB(0, 170, 255),
    ESPGuardsColor = Color3.fromRGB(0, 170, 255),
    ESPInmatesColor = Color3.fromRGB(255, 150, 50),
    ESPCriminalsColor = Color3.fromRGB(255, 60, 60),
    ESPTeamColor = Color3.fromRGB(60, 255, 60),
    ESPUseTeamColors = true
}

local guardsTeam = Teams:FindFirstChild("Guards")
local inmatesTeam = Teams:FindFirstChild("Inmates")
local criminalsTeam = Teams:FindFirstChild("Criminals")

local WallCheckParams = RaycastParams.new()
WallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
WallCheckParams.IgnoreWater = true
WallCheckParams.RespectCanCollide = false
WallCheckParams.CollisionGroup = "ClientBullet"

local CurrentGun = nil

local fov_circle = Drawing.new("Circle")
fov_circle.Color = Color3.fromRGB(255, 0, 0)
fov_circle.Radius = Settings.FOV
fov_circle.Transparency = 0.8
fov_circle.Filled = false
fov_circle.NumSides = 64
fov_circle.Thickness = 1
fov_circle.Visible = Settings.ShowFOV and Settings.Enabled

local target_line = Drawing.new("Line")
target_line.Color = Color3.fromRGB(0, 255, 0)
target_line.Thickness = 1
target_line.Transparency = 0.5
target_line.Visible = false

local Visuals = { Gui = nil }
local ESPCache = {}

local function CreateVisuals()
    local sg = Instance.new("ScreenGui")
    sg.Name = "SilentAimESP"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    pcall(function() sg.Parent = CoreGui end)
    if not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
    Visuals.Gui = sg
end

local function CreateESPMarker(player)
    if ESPCache[player] then return ESPCache[player] end

    local espGui = Instance.new("BillboardGui")
    espGui.Name = "ESP_" .. player.Name
    espGui.AlwaysOnTop = true
    espGui.Size = UDim2.new(0, 20, 0, 20)
    espGui.StudsOffset = Vector3.new(0, 3, 0)
    espGui.LightInfluence = 0

    local diamond = Instance.new("Frame")
    diamond.Name = "Diamond"
    diamond.BackgroundColor3 = Settings.ESPColor
    diamond.BorderSizePixel = 0
    diamond.Size = UDim2.new(0, 10, 0, 10)
    diamond.Position = UDim2.new(0.5, -5, 0.5, -5)
    diamond.Rotation = 45
    diamond.Parent = espGui

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = diamond

    local distLabel = Instance.new("TextLabel")
    distLabel.Name = "DistanceLabel"
    distLabel.BackgroundTransparency = 1
    distLabel.Size = UDim2.new(0, 60, 0, 16)
    distLabel.Position = UDim2.new(0.5, -30, 1, 2)
    distLabel.Font = Enum.Font.GothamBold
    distLabel.TextSize = 11
    distLabel.TextColor3 = Color3.new(1, 1, 1)
    distLabel.TextStrokeTransparency = 0.5
    distLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    distLabel.Text = ""
    distLabel.Parent = espGui

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Name = "NameLabel"
    nameLabel.BackgroundTransparency = 1
    nameLabel.Size = UDim2.new(0, 100, 0, 14)
    nameLabel.Position = UDim2.new(0.5, -50, 0, -16)
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 10
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextStrokeTransparency = 0.5
    nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    nameLabel.Text = player.Name
    nameLabel.Parent = espGui

    ESPCache[player] = espGui
    return espGui
end

local function RemoveESPMarker(player)
    local esp = ESPCache[player]
    if esp then
        esp:Destroy()
        ESPCache[player] = nil
    end
end

local function ShouldShowESP(player)
    if not player or player == LocalPlayer then return false end
    if not player.Character then return false end

    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end

    local hrp = player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local myHRP = myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return false end

    local distance = (hrp.Position - myHRP.Position).Magnitude
    if distance > Settings.ESPMaxDistance then return false end

    local myTeam = LocalPlayer.Team
    local theirTeam = player.Team

    if theirTeam == myTeam then return false end

    if Settings.ESPTeamCheck then
        local iAmCriminalOrInmate = (myTeam == criminalsTeam or myTeam == inmatesTeam)
        local theyAreCriminalOrInmate = (theirTeam == criminalsTeam or theirTeam == inmatesTeam)
        if iAmCriminalOrInmate and theyAreCriminalOrInmate then return false end
    end

    if theirTeam == guardsTeam then return Settings.ESPTargets.Guards
    elseif theirTeam == inmatesTeam then return Settings.ESPTargets.Inmates
    elseif theirTeam == criminalsTeam then return Settings.ESPTargets.Criminals
    end

    return false
end

local function UpdateESP()
    if not Settings.ESPEnabled or not Visuals.Gui then
        for _, esp in pairs(ESPCache) do esp.Parent = nil end
        return
    end

    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")

    for _, player in ipairs(Players:GetPlayers()) do
        local shouldShow = ShouldShowESP(player)

        if shouldShow then
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")

            if hrp and head then
                local esp = CreateESPMarker(player)
                esp.Adornee = head
                esp.Parent = Visuals.Gui

                local diamond = esp:FindFirstChild("Diamond")
                if diamond and Settings.ESPUseTeamColors then
                    local playerTeam = player.Team
                    if playerTeam == guardsTeam then
                        diamond.BackgroundColor3 = Settings.ESPGuardsColor
                    elseif playerTeam == inmatesTeam then
                        diamond.BackgroundColor3 = Settings.ESPInmatesColor
                    elseif playerTeam == criminalsTeam then
                        diamond.BackgroundColor3 = Settings.ESPCriminalsColor
                    else
                        diamond.BackgroundColor3 = Settings.ESPColor
                    end
                end

                if Settings.ESPShowDistance and myHRP then
                    local distLabel = esp:FindFirstChild("DistanceLabel")
                    if distLabel then
                        distLabel.Text = math.floor((hrp.Position - myHRP.Position).Magnitude) .. "m"
                        distLabel.Visible = true
                    end
                end
            end
        else
            local esp = ESPCache[player]
            if esp then esp.Parent = nil end
        end
    end
end

CreateVisuals()

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

local function IsPlayerDead(plr)
    if not plr or not plr.Character then return true end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    return not hum or hum.Health <= 0
end

local function IsPlayerStationary(plr)
    if not plr or not plr.Character then return false end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local velocity = hrp.AssemblyLinearVelocity
    return Vector2.new(velocity.X, velocity.Z).Magnitude <= Settings.StationaryThreshold
end

local function HasForceField(plr)
    if not plr or not plr.Character then return false end
    return plr.Character:FindFirstChildOfClass("ForceField") ~= nil
end

local function IsWallBetween(startPos, endPos, targetCharacter)
    local myChar = LocalPlayer.Character
    if not myChar then return true end

    local filterList = {myChar}
    if targetCharacter then table.insert(filterList, targetCharacter) end
    WallCheckParams.FilterDescendantsInstances = filterList

    local direction = endPos - startPos
    local distance = direction.Magnitude
    local directionUnit = direction.Unit

    local currentStart = startPos
    local remainingDistance = distance

    for _ = 1, 10 do
        local result = workspace:Raycast(currentStart, directionUnit * remainingDistance, WallCheckParams)
        if not result then return false end

        local hitPart = result.Instance
        if hitPart.Transparency < 0.8 and hitPart.CanCollide then return true end

        local hitDistance = (result.Position - currentStart).Magnitude
        remainingDistance = remainingDistance - hitDistance - 0.01
        if remainingDistance <= 0 then return false end

        currentStart = result.Position + directionUnit * 0.01
    end
    return false
end

local function IsValidTargetQuick(plr)
    if not plr or plr == LocalPlayer or not plr.Character then return false end
    if not GetTargetPart(plr.Character) then return false end
    if Settings.DeathCheck and IsPlayerDead(plr) then return false end
    if Settings.ForceFieldCheck and HasForceField(plr) then return false end
    if Settings.TeamCheck and plr.Team == LocalPlayer.Team then return false end

    if Settings.HostileCheck or Settings.TrespassingCheck then
        local isTaser = CurrentGun and CurrentGun:GetAttribute("Projectile") == "Taser"
        local bypassHostile = Settings.TaserBypassHostile and isTaser
        local bypassTrespassing = Settings.TaserBypassTrespassing and isTaser
        local targetChar = plr.Character

        if LocalPlayer.Team == guardsTeam and plr.Team == inmatesTeam then
            local isHostile = targetChar:GetAttribute("Hostile")
            local isTrespassing = targetChar:GetAttribute("Trespassing")

            if Settings.HostileCheck and Settings.TrespassingCheck then
                if not bypassHostile and not bypassTrespassing then
                    if not isHostile and not isTrespassing then return false end
                end
            elseif Settings.HostileCheck and not bypassHostile then
                if not isHostile then return false end
            elseif Settings.TrespassingCheck and not bypassTrespassing then
                if not isTrespassing then return false end
            end
        end
    end

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

local function GetMissPosition(targetPos)
    local spreadRadius = Settings.MissSpread
    local angle = math.random() * math.pi * 2
    local dist = math.random() * spreadRadius
    return targetPos + Vector3.new(math.cos(angle) * dist, (math.random() - 0.5) * spreadRadius, math.sin(angle) * dist)
end

local function GetClosestTarget(fov)
    fov = fov or Settings.FOV
    local camera = workspace.CurrentCamera
    if not camera then return nil, nil end

    local lastInputType = UserInputService:GetLastInputType()
    local isLockedOrMobile = (lastInputType == Enum.UserInputType.Touch) or (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)

    local aimPos
    if isLockedOrMobile then
        local viewportSize = camera.ViewportSize
        aimPos = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    else
        aimPos = UserInputService:GetMouseLocation()
    end

    local candidates = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if IsValidTargetQuick(plr) then
            local targetPart = GetTargetPart(plr.Character)
            if targetPart then
                local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
                if onScreen and screenPos.Z > 0 then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - aimPos).Magnitude
                    if dist < fov then
                        table.insert(candidates, {player = plr, distance = dist, part = targetPart})
                    end
                end
            end
        end
    end

    table.sort(candidates, function(a, b) return a.distance < b.distance end)

    for _, candidate in ipairs(candidates) do
        if IsValidTargetFull(candidate.player) then
            return candidate.player, candidate.part.Position
        end
    end

    return nil, nil
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

RunService.Heartbeat:Connect(function()
    CurrentGun = GetEquippedGun()
end)

RunService.PreRender:Connect(function()
    local aimPos = UserInputService:GetMouseLocation()
    local camera = workspace.CurrentCamera

    if camera then
        local lastInputType = UserInputService:GetLastInputType()
        local isLockedOrMobile = (lastInputType == Enum.UserInputType.Touch) or (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)

        if isLockedOrMobile then
            local viewportSize = camera.ViewportSize
            aimPos = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
        end
    end

    fov_circle.Position = aimPos
    fov_circle.Radius = Settings.FOV
    fov_circle.Visible = Settings.ShowFOV and Settings.Enabled

    if Settings.ShowTargetLine and Settings.Enabled then
        local target, targetPos = GetClosestTarget()
        if target and targetPos and camera then
            local screenPos, onScreen = camera:WorldToViewportPoint(targetPos)
            if onScreen then
                target_line.From = aimPos
                target_line.To = Vector2.new(screenPos.X, screenPos.Y)
                target_line.Visible = true
            else
                target_line.Visible = false
            end
        else
            target_line.Visible = false
        end
    else
        target_line.Visible = false
    end

    UpdateESP()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
end)

Players.PlayerRemoving:Connect(RemoveESPMarker)

LPH_NO_UPVALUES = function(func)
    return function(...)
        return func(...)
    end
end

local castRay = filtergc("function", {Name = "castRay"}, true)
local old_castRay
old_castRay = hookfunction(castRay, LPH_NO_UPVALUES(function(...)
    if not Settings.Enabled then
        return old_castRay(...)
    end

    local closest_player, closest_position = GetClosestTarget(Settings.FOV)

    if closest_player and closest_player.Character then
        local isTaser = CurrentGun and CurrentGun:GetAttribute("Projectile") == "Taser"
        local shouldHit = false

        if Settings.TaserAlwaysHit and isTaser then
            shouldHit = true
        elseif Settings.IfPlayerIsStill and IsPlayerStationary(closest_player) then
            shouldHit = true
        elseif RollHitChance() then
            shouldHit = true
        end

        if shouldHit then
            local targetPart = GetTargetPart(closest_player.Character)
            if targetPart then
                return targetPart, closest_position
            end
        elseif Settings.MissSpread > 0 then
            local targetPart = GetTargetPart(closest_player.Character)
            if targetPart then
                local missPos = GetMissPosition(targetPart.Position)
                return nil, missPos
            end
        end
    end

    return old_castRay(...)
end))

pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "Silent Aim + ESP",
        Text = "Successfully loaded!",
        Duration = 5,
    })
end)
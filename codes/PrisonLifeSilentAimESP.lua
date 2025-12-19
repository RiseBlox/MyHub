local game = game
local workspace = workspace
local getService = game.GetService

local Players = getService(game, "Players")
local RunService = getService(game, "RunService")
local UserInputService = getService(game, "UserInputService")
local ContextActionService = getService(game, "ContextActionService")
local ReplicatedStorage = getService(game, "ReplicatedStorage")
local StarterGui = getService(game, "StarterGui")
local TweenService = getService(game, "TweenService")
local CoreGui = getService(game, "CoreGui")
local GuiService = getService(game, "GuiService")
local Debris = getService(game, "Debris")
local Teams = getService(game, "Teams")

local math_random = math.random
local math_cos = math.cos
local math_sin = math.sin
local math_pi = math.pi
local math_rad = math.rad
local math_deg = math.deg
local math_atan2 = math.atan2
local math_floor = math.floor
local math_max = math.max

local table_insert = table.insert
local table_remove = table.remove
local table_clear = table.clear
local table_create = table.create
local table_sort = table.sort

local task_delay = task.delay
local task_defer = task.defer

local tick = tick
local os_clock = os.clock
local pcall = pcall
local require = require
local typeof = typeof
local type = type
local ipairs = ipairs
local pairs = pairs
local setmetatable = setmetatable
local tostring = tostring

local Vector2_new = Vector2.new
local Vector3_new = Vector3.new
local CFrame_new = CFrame.new
local CFrame_Angles = CFrame.Angles
local UDim_new = UDim.new
local UDim2_new = UDim2.new
local UDim2_fromOffset = UDim2.fromOffset
local Color3_new = Color3.new
local Color3_fromRGB = Color3.fromRGB
local BrickColor_new = BrickColor.new
local BrickColor_Yellow = BrickColor.Yellow
local Instance_new = Instance.new
local RaycastParams_new = RaycastParams.new
local TweenInfo_new = TweenInfo.new

local LocalPlayer = Players.LocalPlayer

local Settings = {
	Enabled = true,
	TeamCheck = true,
	WallCheck = true,
	DeathCheck = true,
	ForceFieldCheck = true,
	HostileCheck = false,
	TrespassingCheck = false,
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
	AimPart = "Torso",
	RandomAimParts = true,
	AimPartsList = {
		"Torso",
		"HumanoidRootPart",
		"LeftArm",
		"RightArm"
	},
	ESPEnabled = true,
	ESPTeamCheck = true,
	ESPTargets = {
		Guards = true,
		Inmates = true,
		Criminals = true
	},
	ESPMaxDistance = 500,
	ESPShowDistance = true,
	ESPColor = Color3_fromRGB(0, 170, 255),
	ESPGuardsColor = Color3_fromRGB(0, 170, 255),
	ESPInmatesColor = Color3_fromRGB(255, 150, 50),
	ESPCriminalsColor = Color3_fromRGB(255, 60, 60),
	ESPTeamColor = Color3_fromRGB(60, 255, 60),
	ESPUseTeamColors = true
}

local isInsideDynThumbFrame = require(ReplicatedStorage.SharedModules.isInsideDynThumbFrame)
local PlayerSettings = ReplicatedStorage.PlayerSettings
local MobileCursorOffset = 0

local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local HomeHud = PlayerGui:WaitForChild("Home"):WaitForChild("hud")
local MobileGunFrame = HomeHud:WaitForChild("MobileGunFrame")
local IgnoreTouchArea = MobileGunFrame:WaitForChild("IgnoreTouchArea")
local ActionArea = HomeHud:WaitForChild("ActionArea")
local MobileCursor = MobileGunFrame:WaitForChild("MobileCursor")

local function UpdateMobileOffset()
	local offset = PlayerSettings:GetAttribute("MobileCursorOffset")
	if offset then
		MobileCursorOffset = offset * 15
	end
end

if PlayerSettings:GetAttribute("Settings_Loaded") then
	UpdateMobileOffset()
	PlayerSettings:GetAttributeChangedSignal("MobileCursorOffset"):Connect(UpdateMobileOffset)
else
	PlayerSettings:GetAttributeChangedSignal("Settings_Loaded"):Once(function()
		UpdateMobileOffset()
		PlayerSettings:GetAttributeChangedSignal("MobileCursorOffset"):Connect(UpdateMobileOffset)
	end)
end

local GunRemotes = ReplicatedStorage:WaitForChild("GunRemotes", 10)
local ShootEvent = GunRemotes and GunRemotes:WaitForChild("ShootEvent", 10)

if not ShootEvent then
	return
end

local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({
		_tasks = {}
	}, Maid)
end

function Maid:GiveTask(task)
	table_insert(self._tasks, task)
	return task
end

local MainMaid = Maid.new()
local EquipMaid = Maid.new()

local WallCheckParams = RaycastParams_new()
WallCheckParams.FilterType = Enum.RaycastFilterType.Exclude
WallCheckParams.IgnoreWater = true
WallCheckParams.RespectCanCollide = false
WallCheckParams.CollisionGroup = "ClientBullet"

local BulletTweenInfo = TweenInfo_new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local TaserTweenInfo = TweenInfo_new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local FadeProperties = {
	Transparency = 1
}

local Visuals = {
	Gui = nil,
	Circle = nil,
	Line = nil
}

local ESPCache = {}

local function CreateVisuals()
	local sg = Instance_new("ScreenGui")
	sg.Name = "SilentAimVisuals"
	sg.ResetOnSpawn = false
	sg.IgnoreGuiInset = true
	pcall(function()
		sg.Parent = CoreGui
	end)
	if not sg.Parent then
		sg.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	Visuals.Gui = sg
	local circleFrame = Instance_new("Frame")
	circleFrame.Name = "FOVCircle"
	circleFrame.BackgroundTransparency = 1
	circleFrame.AnchorPoint = Vector2_new(0.5, 0.5)
	circleFrame.Visible = false
	circleFrame.Parent = sg
	local stroke = Instance_new("UIStroke")
	stroke.Color = Color3_fromRGB(255, 0, 0)
	stroke.Thickness = 2
	stroke.Transparency = 0.3
	stroke.Parent = circleFrame
	local corner = Instance_new("UICorner")
	corner.CornerRadius = UDim_new(1, 0)
	corner.Parent = circleFrame
	Visuals.Circle = circleFrame
	local lineFrame = Instance_new("Frame")
	lineFrame.Name = "TargetLine"
	lineFrame.BackgroundColor3 = Color3_fromRGB(0, 255, 0)
	lineFrame.BorderSizePixel = 0
	lineFrame.AnchorPoint = Vector2_new(0.5, 0.5)
	lineFrame.Visible = false
	lineFrame.Parent = sg
	Visuals.Line = lineFrame
end

local function CreateESPMarker(player)
	local existing = ESPCache[player]
	if existing then
		return existing
	end
	local espGui = Instance_new("BillboardGui")
	espGui.Name = "ESP_" .. player.Name
	espGui.AlwaysOnTop = true
	espGui.Size = UDim2_new(0, 20, 0, 20)
	espGui.StudsOffset = Vector3_new(0, 3, 0)
	espGui.LightInfluence = 0
	local diamond = Instance_new("Frame")
	diamond.Name = "Diamond"
	diamond.BackgroundColor3 = Settings.ESPColor
	diamond.BorderSizePixel = 0
	diamond.Size = UDim2_new(0, 10, 0, 10)
	diamond.Position = UDim2_new(0.5, -5, 0.5, -5)
	diamond.Rotation = 45
	diamond.Parent = espGui
	local stroke = Instance_new("UIStroke")
	stroke.Color = Color3_new(0, 0, 0)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3
	stroke.Parent = diamond
	local distLabel = Instance_new("TextLabel")
	distLabel.Name = "DistanceLabel"
	distLabel.BackgroundTransparency = 1
	distLabel.Size = UDim2_new(0, 60, 0, 16)
	distLabel.Position = UDim2_new(0.5, -30, 1, 2)
	distLabel.Font = Enum.Font.GothamBold
	distLabel.TextSize = 11
	distLabel.TextColor3 = Color3_new(1, 1, 1)
	distLabel.TextStrokeTransparency = 0.5
	distLabel.TextStrokeColor3 = Color3_new(0, 0, 0)
	distLabel.Text = ""
	distLabel.Parent = espGui
	local nameLabel = Instance_new("TextLabel")
	nameLabel.Name = "NameLabel"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Size = UDim2_new(0, 100, 0, 14)
	nameLabel.Position = UDim2_new(0.5, -50, 0, -16)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 10
	nameLabel.TextColor3 = Color3_new(1, 1, 1)
	nameLabel.TextStrokeTransparency = 0.5
	nameLabel.TextStrokeColor3 = Color3_new(0, 0, 0)
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

local guardsTeam = Teams:FindFirstChild("Guards")
local inmatesTeam = Teams:FindFirstChild("Inmates")
local criminalsTeam = Teams:FindFirstChild("Criminals")

local function ShouldShowESP(player)
	if not player or player == LocalPlayer then
		return false
	end
	local char = player.Character
	if not char then
		return false
	end
	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	local myChar = LocalPlayer.Character
	if not myChar then
		return false
	end
	local myHRP = myChar:FindFirstChild("HumanoidRootPart")
	if not myHRP then
		return false
	end
	local distance = (hrp.Position - myHRP.Position).Magnitude
	if distance > Settings.ESPMaxDistance then
		return false
	end
	local myTeam = LocalPlayer.Team
	local theirTeam = player.Team
	if theirTeam == myTeam then
		return false
	end
	if Settings.ESPTeamCheck then
		local iAmCriminalOrInmate = (myTeam == criminalsTeam or myTeam == inmatesTeam)
		local theyAreCriminalOrInmate = (theirTeam == criminalsTeam or theirTeam == inmatesTeam)
		if iAmCriminalOrInmate and theyAreCriminalOrInmate then
			return false
		end
	end
	if theirTeam == guardsTeam then
		return Settings.ESPTargets.Guards
	elseif theirTeam == inmatesTeam then
		return Settings.ESPTargets.Inmates
	elseif theirTeam == criminalsTeam then
		return Settings.ESPTargets.Criminals
	end
	return false
end

local function UpdateESP()
	if not Settings.ESPEnabled then
		for _, esp in pairs(ESPCache) do
			esp.Parent = nil
		end
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
				if diamond then
					if Settings.ESPUseTeamColors then
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
					else
						diamond.BackgroundColor3 = Settings.ESPColor
					end
				end
				if Settings.ESPShowDistance and myHRP then
					local distLabel = esp:FindFirstChild("DistanceLabel")
					if distLabel then
						distLabel.Text = math_floor((hrp.Position - myHRP.Position).Magnitude) .. "m"
						distLabel.Visible = true
					end
				else
					local distLabel = esp:FindFirstChild("DistanceLabel")
					if distLabel then
						distLabel.Visible = false
					end
				end
			end
		else
			local esp = ESPCache[player]
			if esp then
				esp.Parent = nil
			end
		end
	end
end

CreateVisuals()

local IsShooting = false
local LastShot = 0
local CurrentTarget = nil
local LastTargetUpdate = 0
local TARGET_UPDATE_INTERVAL = 0.05
local CurrentGun = nil
local GunSettings = nil
local LoadedAnimations = {}
local CurrentTouchInput = nil
local LastTouchTime = 0

local TracerPool = {
	bullets = {},
	tasers = {},
	maxPoolSize = 20
}

local function GetPooledPart(pool, createFunc)
	local poolCount = # pool
	for i = poolCount, 1, -1 do
		local part = pool[i]
		if not part.Parent then
			table_remove(pool, i)
			return part
		end
	end
	return createFunc()
end

local function ReturnToPool(pool, part)
	part.Parent = nil
	if # pool < TracerPool.maxPoolSize then
		table_insert(pool, part)
	else
		part:Destroy()
	end
end

local function CreateBaseBulletPart()
	local bullet = Instance_new("Part")
	bullet.Name = "PooledBullet"
	bullet.Anchored = true
	bullet.CanCollide = false
	bullet.CastShadow = false
	bullet.Material = Enum.Material.Neon
	bullet.BrickColor = BrickColor_Yellow()
	bullet.CollisionGroup = "Nothing"
	local mesh = Instance_new("BlockMesh", bullet)
	mesh.Scale = Vector3_new(0.5, 0.5, 1)
	return bullet
end

local function CreateBaseTaserPart()
	local bullet = Instance_new("Part")
	bullet.Name = "PooledTaser"
	bullet.Anchored = true
	bullet.CanCollide = false
	bullet.CastShadow = false
	bullet.Material = Enum.Material.Neon
	bullet.BrickColor = BrickColor_new("Cyan")
	bullet.CollisionGroup = "Nothing"
	local mesh = Instance_new("BlockMesh", bullet)
	mesh.Scale = Vector3_new(0.8, 0.8, 1)
	return bullet
end

for _ = 1, 5 do
	table_insert(TracerPool.bullets, CreateBaseBulletPart())
	table_insert(TracerPool.tasers, CreateBaseTaserPart())
end

local PartMappings = {
	["Torso"] = {
		"Torso",
		"UpperTorso",
		"LowerTorso"
	},
	["LeftArm"] = {
		"Left Arm",
		"LeftUpperArm",
		"LeftLowerArm",
		"LeftHand"
	},
	["RightArm"] = {
		"Right Arm",
		"RightUpperArm",
		"RightLowerArm",
		"RightHand"
	},
	["LeftLeg"] = {
		"Left Leg",
		"LeftUpperLeg",
		"LeftLowerLeg",
		"LeftFoot"
	},
	["RightLeg"] = {
		"Right Leg",
		"RightUpperLeg",
		"RightLowerLeg",
		"RightFoot"
	}
}

local function GetBodyPart(character, partName)
	if not character then
		return nil
	end
	local directPart = character:FindFirstChild(partName)
	if directPart then
		return directPart
	end
	local mappings = PartMappings[partName]
	if mappings then
		for _, name in ipairs(mappings) do
			local part = character:FindFirstChild(name)
			if part then
				return part
			end
		end
	end
	return character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Head")
end

local function GetTargetPart(character)
	if not character then
		return nil
	end
	local partName
	if Settings.RandomAimParts then
		local partsList = Settings.AimPartsList
		partName = (partsList and # partsList > 0) and partsList[math_random(1, # partsList)] or "Head"
	else
		partName = Settings.AimPart
	end
	return GetBodyPart(character, partName)
end

local function GetMissPosition(targetPos, gun)
	local spreadRadius = Settings.MissSpread
	if gun and GunSettings and GunSettings.SpreadRadius then
		spreadRadius = math_max(spreadRadius, GunSettings.SpreadRadius * 10)
	end
	local angle = math_random() * math_pi * 2
	local dist = math_random() * spreadRadius
	local x = math_cos(angle) * dist
	local y = (math_random() - 0.5) * spreadRadius
	local z = math_sin(angle) * dist
	return targetPos + Vector3_new(x, y, z)
end

local ActiveSounds = {}
local function PlayGunSound(gun)
	if not gun then
		return
	end
	local handle = gun:FindFirstChild("Handle")
	if not handle then
		return
	end
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
end

local function EnableMuzzleFlare(gun)
	if not gun then
		return
	end
	local handle = gun:FindFirstChild("Handle")
	if handle then
		local flare = handle:FindFirstChild("Flare")
		if flare then
			flare.Enabled = true
			task_delay(0.05, function()
				if flare and flare.Parent then
					flare.Enabled = false
				end
			end)
		end
	end
end

local function CreateProjectileTracer(startPos, endPos, gun)
	local isTaser = gun and gun:GetAttribute("Projectile") == "Taser"
	local muzzle = gun and gun:FindFirstChild("Muzzle")
	local visualStart = muzzle and muzzle.Position or startPos
	local bullet
	local tweenInfo
	if isTaser then
		bullet = GetPooledPart(TracerPool.tasers, CreateBaseTaserPart)
		tweenInfo = TaserTweenInfo
		local light = bullet:FindFirstChild("SurfaceLight")
		if not light then
			light = Instance_new("SurfaceLight", bullet)
			light.Color = Color3_fromRGB(0, 234, 255)
			light.Range = 7
			light.Face = Enum.NormalId.Bottom
			light.Brightness = 5
			light.Angle = 180
		end
		light.Brightness = 5
	else
		bullet = GetPooledPart(TracerPool.bullets, CreateBaseBulletPart)
		tweenInfo = BulletTweenInfo
	end
	local actualDist = (endPos - visualStart).Magnitude
	bullet.Transparency = 0.5
	bullet.Size = Vector3_new(0.2, 0.2, actualDist)
	bullet.CFrame = CFrame_new(endPos, visualStart) * CFrame_new(0, 0, - actualDist / 2)
	bullet.Parent = workspace
	local fade = TweenService:Create(bullet, tweenInfo, FadeProperties)
	if isTaser then
		local light = bullet:FindFirstChild("SurfaceLight")
		if light then
			local lightFade = TweenService:Create(light, tweenInfo, {
				Brightness = 0
			})
			lightFade:Play()
		end
	end
	fade:Play()
	fade.Completed:Once(function()
		ReturnToPool(isTaser and TracerPool.tasers or TracerPool.bullets, bullet)
	end)
end

local function IsPlayerDead(plr)
	if not plr then
		return true
	end
	local char = plr.Character
	if not char then
		return true
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	return not hum or hum.Health <= 0
end

local function IsPlayerStationary(plr)
	local char = plr and plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	local velocity = hrp.AssemblyLinearVelocity
	return (Vector2_new(velocity.X, velocity.Z)).Magnitude <= Settings.StationaryThreshold
end

local function HasForceField(plr)
	local char = plr and plr.Character
	return char and char:FindFirstChildOfClass("ForceField") ~= nil
end

local function IsWallBetween(startPos, endPos, targetCharacter)
	local myChar = LocalPlayer.Character
	if not myChar then
		return true
	end
	local filterList = {
		myChar
	}
	if targetCharacter then
		table_insert(filterList, targetCharacter)
	end
	WallCheckParams.FilterDescendantsInstances = filterList
	local direction = endPos - startPos
	local distance = direction.Magnitude
	local directionUnit = direction.Unit
	local currentStart = startPos
	local remainingDistance = distance
	local maxIterations = 10
	for _ = 1, maxIterations do
		local result = workspace:Raycast(currentStart, directionUnit * remainingDistance, WallCheckParams)
		if not result then
			return false
		end
		local hitPart = result.Instance
		if hitPart.Transparency < 0.8 and hitPart.CanCollide then
			return true
		end
		local hitDistance = (result.Position - currentStart).Magnitude
		remainingDistance = remainingDistance - hitDistance - 0.01
		if remainingDistance <= 0 then
			return false
		end
		currentStart = result.Position + directionUnit * 0.01
	end
	return false
end

local function IsValidTargetQuick(plr)
	if not plr or plr == LocalPlayer or not plr.Character then
		return false
	end
	if not GetTargetPart(plr.Character) then
		return false
	end
	if Settings.DeathCheck and IsPlayerDead(plr) then
		return false
	end
	if Settings.ForceFieldCheck and HasForceField(plr) then
		return false
	end
	if Settings.TeamCheck and plr.Team == LocalPlayer.Team then
		return false
	end
	if Settings.HostileCheck or Settings.TrespassingCheck then
		local isTasersOnly = CurrentGun and CurrentGun:GetAttribute("Projectile") == "Taser"
		local bypassHostile = Settings.TaserBypassHostile and isTasersOnly
		local bypassTrespassing = Settings.TaserBypassTrespassing and isTasersOnly
		local targetChar = plr.Character
		local guardsTeamObj = Teams:FindFirstChild("Guards")
		local inmatesTeamObj = Teams:FindFirstChild("Inmates")
		if LocalPlayer.Team == guardsTeamObj then
			if plr.Team == inmatesTeamObj then
				local isHostile = targetChar:GetAttribute("Hostile")
				local isTrespassing = targetChar:GetAttribute("Trespassing")
				if Settings.HostileCheck and Settings.TrespassingCheck then
					if not bypassHostile and not bypassTrespassing then
						if not isHostile and not isTrespassing then
							return false
						end
					end
				elseif Settings.HostileCheck and not bypassHostile then
					if not isHostile then
						return false
					end
				elseif Settings.TrespassingCheck and not bypassTrespassing then
					if not isTrespassing then
						return false
					end
				end
			end
		end
	end
	return true
end

local function IsValidTargetFull(plr)
	if not IsValidTargetQuick(plr) then
		return false
	end
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
	local chance = Settings.HitChance
	if chance >= 100 then
		return true
	end
	if chance <= 0 then
		return false
	end
	return math_random(1, 100) <= chance
end

local function GetClosestTarget()
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local lastInputType = UserInputService:GetLastInputType()
	local isLockedOrMobile = (lastInputType == Enum.UserInputType.Touch) or (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
	local aimPos
	if isLockedOrMobile then
		local viewportSize = camera.ViewportSize
		aimPos = Vector2_new(viewportSize.X / 2, viewportSize.Y / 2)
	else
		aimPos = UserInputService:GetMouseLocation()
	end
	local candidates = {}
	local candidatesCount = 0
	local fovLimit = Settings.FOV
	for _, plr in ipairs(Players:GetPlayers()) do
		if IsValidTargetQuick(plr) then
			local targetPart = GetTargetPart(plr.Character)
			if targetPart then
				local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
				if onScreen then
					local dist = (Vector2_new(screenPos.X, screenPos.Y) - aimPos).Magnitude
					if dist < fovLimit then
						candidatesCount = candidatesCount + 1
						candidates[candidatesCount] = {
							player = plr,
							distance = dist
						}
					end
				end
			end
		end
	end
	if candidatesCount > 0 then
		table_sort(candidates, function(a, b)
			return a.distance < b.distance
		end)
		for i = 1, candidatesCount do
			local candidate = candidates[i]
			if IsValidTargetFull(candidate.player) then
				return candidate.player
			end
		end
	end
	return nil
end

local function GetEquippedGun()
	local char = LocalPlayer.Character
	if not char then
		return nil
	end
	for _, tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gun" then
			return tool
		end
	end
	return nil
end

local function LoadAnimations(gun)
	if not gun then
		return
	end
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local animIds = {
		ShootBullet = "rbxassetid://389472570",
		ShootShell = "rbxassetid://405194080"
	}
	for name, id in pairs(animIds) do
		local anim = Instance_new("Animation")
		anim.AnimationId = id
		local track = animator:LoadAnimation(anim)
		track.Priority = Enum.AnimationPriority.Action2
		LoadedAnimations[name] = track
		anim:Destroy()
	end
end

local function PlayShootAnimation(gun)
	if not gun then
		return
	end
	local animName = gun:GetAttribute("IsShotgun") and "ShootShell" or "ShootBullet"
	local anim = LoadedAnimations[animName]
	if anim then
		anim:Play()
	end
end

local CachedBulletsLabel = nil
local CachedBulletsLabel = nil
local function UpdateAmmoGUI(ammo, maxAmmo)
	pcall(function()
		if not CachedBulletsLabel or not CachedBulletsLabel.Parent then
			local home = PlayerGui:FindFirstChild("Home")
			local hud = home and home:FindFirstChild("hud")
			local gunFrame = hud and hud:FindFirstChild("BottomRightFrame") and hud.BottomRightFrame:FindFirstChild("GunFrame")
			if not gunFrame then
				return
			end
			CachedBulletsLabel = gunFrame:FindFirstChild("BulletsLabel")
		end
		if CachedBulletsLabel then
			CachedBulletsLabel.Text = ammo .. "/" .. maxAmmo
		end
	end)
end

local function CastBulletRay(startPos, targetPos)
	local spreadRadius = GunSettings and GunSettings.SpreadRadius or 0
	local range = GunSettings and GunSettings.Range or 1000
	local baseCFrame = CFrame_new(startPos, targetPos)
	local randomAngle = math_rad(math_random(-360, 360))
	local spreadAngle = math_random() * spreadRadius
	local direction = (baseCFrame * CFrame_Angles(0, 0, randomAngle) * CFrame_Angles(0, spreadAngle, 0)).LookVector * range
	WallCheckParams.FilterDescendantsInstances = {
		LocalPlayer.Character
	}
	local result = workspace:Raycast(startPos, direction, WallCheckParams)
	return result and result.Instance, result and result.Position or startPos + direction
end

local function FireSilentAim(gun, touchInput)
	if not gun then
		return false
	end
	local ammo = gun:GetAttribute("Local_CurrentAmmo") or 0
	if ammo <= 0 then
		return false
	end
	local fireRate = (GunSettings and GunSettings.FireRate) or gun:GetAttribute("FireRate") or 0.12
	local now = tick()
	if now - LastShot < fireRate then
		return false
	end
	local char = LocalPlayer.Character
	local humanoid = char and char:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	if Settings.VehicleCheck and humanoid.SeatPart and humanoid.SeatPart:IsDescendantOf(workspace:FindFirstChild("CarContainer") or workspace) then
		return false
	end
	local myHead = char:FindFirstChild("Head")
	if not myHead then
		return false
	end
	local reloadSession = gun:GetAttribute("Local_ReloadSession") or 0
	if reloadSession > 0 then
		return false
	end
	local hitPos, hitPart
	local forceHit = false
	if Settings.Enabled and CurrentTarget and CurrentTarget.Character and IsValidTargetFull(CurrentTarget) then
		local targetPart = GetTargetPart(CurrentTarget.Character)
		if targetPart then
			local isTaser = Settings.TaserAlwaysHit and gun:GetAttribute("Projectile") == "Taser"
			local isStationary = Settings.IfPlayerIsStill and IsPlayerStationary(CurrentTarget)
			if isTaser or isStationary or RollHitChance() then
				hitPos = targetPart.Position
				hitPart = targetPart
				forceHit = true
			else
				hitPos = GetMissPosition(targetPart.Position, gun)
				hitPart = nil
				forceHit = false
			end
		end
	end
	if not hitPos then
		local camera = workspace.CurrentCamera
		local screenX, screenY
		if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
			local viewportSize = camera.ViewportSize
			screenX = viewportSize.X / 2
			screenY = viewportSize.Y / 2
		elseif touchInput and touchInput.UserInputType == Enum.UserInputType.Touch then
			local guiInset = GuiService:GetGuiInset()
			local touchPos = touchInput.Position
			screenX = touchPos.X + guiInset.X
			screenY = touchPos.Y + guiInset.Y - MobileCursorOffset
			MobileCursor.Position = UDim2_fromOffset(touchPos.X, touchPos.Y - MobileCursorOffset)
			MobileCursor.Visible = true
			LastTouchTime = os_clock()
		else
			local mousePos = UserInputService:GetMouseLocation()
			screenX = mousePos.X
			screenY = mousePos.Y
		end
		local ray = camera:ViewportPointToRay(screenX, screenY)
		WallCheckParams.FilterDescendantsInstances = {
			char
		}
		local result = workspace:Raycast(ray.Origin, ray.Direction * 1500, WallCheckParams)
		if result then
			hitPos = result.Position
			hitPart = result.Instance
		else
			hitPos = ray.Origin + (ray.Direction * 500)
		end
	end
	gun:SetAttribute("Local_IsShooting", true)
	local muzzle = gun:FindFirstChild("Muzzle")
	local visualStart = muzzle and muzzle.Position or myHead.Position
	local projectileCount = GunSettings and GunSettings.ProjectileCount or 1
	local bullets = table_create(projectileCount)
	local bulletPositions = table_create(projectileCount)
	local headPos = myHead.Position
	for i = 1, projectileCount do
		local bulletPart, bulletPos
		if forceHit and hitPart then
			bulletPart = hitPart
			bulletPos = hitPos
		else
			bulletPart, bulletPos = CastBulletRay(headPos, hitPos)
		end
		bullets[i] = {
			headPos,
			bulletPos,
			bulletPart
		}
		bulletPositions[i] = bulletPos
	end
	LastShot = now
	PlayGunSound(gun)
	EnableMuzzleFlare(gun)
	PlayShootAnimation(gun)
	for i = 1, projectileCount do
		CreateProjectileTracer(visualStart, bulletPositions[i], gun)
	end
	ShootEvent:FireServer(bullets)
	local newAmmo = ammo - 1
	gun:SetAttribute("Local_CurrentAmmo", newAmmo)
	UpdateAmmoGUI(newAmmo, gun:GetAttribute("MaxAmmo") or 0)
	task_defer(function()
		if gun and gun.Parent then
			gun:SetAttribute("Local_IsShooting", false)
		end
	end)
	return true
end

local function IsInsideIgnoreTouchArea(x, y)
	local absPos = IgnoreTouchArea.AbsolutePosition
	local absSize = IgnoreTouchArea.AbsoluteSize
	return x >= absPos.X and x <= absPos.X + absSize.X and y >= absPos.Y and y <= absPos.Y + absSize.Y
end

local function HandleAction(actionName, inputState, inputObject)
	if actionName == "SilentAimShoot" then
		if inputState == Enum.UserInputState.Begin then
			local gun = GetEquippedGun()
			if not gun then
				return Enum.ContextActionResult.Pass
			end
			if inputObject.UserInputType == Enum.UserInputType.Touch then
				local touchPos = inputObject.Position
				if MobileGunFrame.Visible then
					if IsInsideIgnoreTouchArea(touchPos.X, touchPos.Y) then
						return Enum.ContextActionResult.Pass
					end
				end
				if isInsideDynThumbFrame(touchPos.X, touchPos.Y) then
					return Enum.ContextActionResult.Pass
				end
				if ActionArea.Visible then
					return Enum.ContextActionResult.Pass
				end
			end
			CurrentGun = gun
			GunSettings = gun:GetAttributes()
			local touchInput = nil
			if inputObject.UserInputType == Enum.UserInputType.Touch then
				touchInput = inputObject
				CurrentTouchInput = inputObject
				LastTouchTime = os_clock()
			end
			if not gun:GetAttribute("AutoFire") then
				IsShooting = true
				FireSilentAim(gun, touchInput)
				IsShooting = false
			else
				IsShooting = true
			end
			return Enum.ContextActionResult.Sink
		elseif inputState == Enum.UserInputState.End then
			IsShooting = false
			CurrentTouchInput = nil
			return Enum.ContextActionResult.Sink
		end
	end
	return Enum.ContextActionResult.Pass
end

pcall(function()
	ContextActionService:BindActionAtPriority("SilentAimShoot", HandleAction, false, 3000, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
end)

local function HandleTouchShoot(input)
	local gun = GetEquippedGun()
	if not gun then
		return
	end
	gun:SetAttribute("Local_IsShooting", true)
	local touchPos = input.Position
	if MobileGunFrame.Visible then
		if IsInsideIgnoreTouchArea(touchPos.X, touchPos.Y) then
			gun:SetAttribute("Local_IsShooting", false)
			return
		end
	end
	if isInsideDynThumbFrame(touchPos.X, touchPos.Y) then
		gun:SetAttribute("Local_IsShooting", false)
		return
	end
	if ActionArea.Visible then
		gun:SetAttribute("Local_IsShooting", false)
		return
	end
	CurrentGun = gun
	GunSettings = gun:GetAttributes()
	CurrentTouchInput = input
	LastTouchTime = os_clock()
	IsShooting = true
end

MainMaid:GiveTask(UserInputService.InputBegan:Connect(function(input, gpe)
	local inputType = input.UserInputType
	if inputType == Enum.UserInputType.Touch then
		HandleTouchShoot(input)
	elseif not gpe then
	end
end))

MainMaid:GiveTask(UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		if CurrentTouchInput then
			CurrentTouchInput = nil
			IsShooting = false
			local gun = GetEquippedGun()
			if gun then
				gun:SetAttribute("Local_IsShooting", false)
			end
		end
	end
end))

MainMaid:GiveTask(RunService.Heartbeat:Connect(function()
	if UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter then
		MobileCursor.Visible = true
		local guiInset = GuiService:GetGuiInset()
		local camera = workspace.CurrentCamera
		local viewportSize = camera and camera.ViewportSize or Vector2_new(0, 0)
		MobileCursor.Position = UDim2_fromOffset(viewportSize.X / 2 - guiInset.X, viewportSize.Y / 2 - guiInset.Y)
	elseif os_clock() - LastTouchTime > 1 then
		MobileCursor.Visible = false
	end
end))

MainMaid:GiveTask(RunService.RenderStepped:Connect(function()
	local lastInputType = UserInputService:GetLastInputType()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local isLockedOrMobile = (lastInputType == Enum.UserInputType.Touch) or (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
	local aimPos
	if isLockedOrMobile then
		local viewportSize = camera.ViewportSize
		aimPos = Vector2_new(viewportSize.X / 2, viewportSize.Y / 2)
	else
		aimPos = UserInputService:GetMouseLocation()
	end
	local circle = Visuals.Circle
	if circle then
		local showFOV = Settings.ShowFOV and Settings.Enabled
		circle.Visible = showFOV
		if showFOV then
			local fovSize = Settings.FOV * 2
			circle.Size = UDim2_new(0, fovSize, 0, fovSize)
			circle.Position = UDim2_new(0, aimPos.X, 0, aimPos.Y)
		end
	end
	local now = tick()
	if Settings.Enabled then
		if (now - LastTargetUpdate) >= TARGET_UPDATE_INTERVAL then
			LastTargetUpdate = now
			CurrentTarget = GetClosestTarget()
		end
	else
		CurrentTarget = nil
	end
	local line = Visuals.Line
	if line then
		local shouldShowLine = Settings.ShowTargetLine and Settings.Enabled and CurrentTarget and CurrentTarget.Character
		line.Visible = shouldShowLine
		if shouldShowLine then
			local targetPart = GetTargetPart(CurrentTarget.Character)
			if targetPart then
				local screenPos, onScreen = camera:WorldToViewportPoint(targetPart.Position)
				if onScreen then
					local endPos = Vector2_new(screenPos.X, screenPos.Y)
					local distance = (endPos - aimPos).Magnitude
					local center = (aimPos + endPos) / 2
					local rotation = math_atan2(endPos.Y - aimPos.Y, endPos.X - aimPos.X)
					line.Size = UDim2_new(0, distance, 0, 2)
					line.Position = UDim2_new(0, center.X, 0, center.Y)
					line.Rotation = math_deg(rotation)
				else
					line.Visible = false
				end
			end
		end
	end
	UpdateESP()
end))

MainMaid:GiveTask(RunService.Heartbeat:Connect(function()
	if not IsShooting then
		return
	end
	local gun = GetEquippedGun()
	if not gun then
		return
	end
	CurrentGun = gun
	GunSettings = gun:GetAttributes()
	FireSilentAim(gun, CurrentTouchInput)
	if not gun:GetAttribute("AutoFire") then
		IsShooting = false
		CurrentTouchInput = nil
		gun:SetAttribute("Local_IsShooting", false)
	end
end))

local function OnCharacterAdded(char)
	CachedBulletsLabel = nil
	CurrentTarget = nil
	CurrentGun = nil
	GunSettings = nil
	IsShooting = false
	table_clear(LoadedAnimations)
	for _, sound in pairs(ActiveSounds) do
		if sound and sound.Parent then
			sound:Destroy()
		end
	end
	table_clear(ActiveSounds)
	WallCheckParams.FilterDescendantsInstances = {
		char
	}
	EquipMaid:GiveTask(char.ChildAdded:Connect(function(tool)
		if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gun" then
			CurrentGun = tool
			GunSettings = tool:GetAttributes()
			tool:SetAttribute("Local_CurrentAmmo", tool:GetAttribute("CurrentAmmo"))
			LoadAnimations(tool)
		end
	end))
	EquipMaid:GiveTask(char.ChildRemoved:Connect(function(tool)
		if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gun" then
			if CurrentGun == tool then
				CurrentGun = nil
				GunSettings = nil
				IsShooting = false
			end
			table_clear(LoadedAnimations)
		end
	end))
end

MainMaid:GiveTask(Players.PlayerRemoving:Connect(RemoveESPMarker))

MainMaid:GiveTask(LocalPlayer.CharacterAdded:Connect(OnCharacterAdded))
if LocalPlayer.Character then
	OnCharacterAdded(LocalPlayer.Character)
end

pcall(StarterGui.SetCore, StarterGui, "SendNotification", {
	Title = "Prison Life Silent Aim + ESP",
	Text = "Successfully loaded!",
	Duration = 5,
})
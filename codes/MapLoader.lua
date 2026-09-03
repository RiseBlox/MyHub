local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local STREAMING_ENABLED = (function()
	local ok, v = pcall(function()
		return Workspace.StreamingEnabled
	end)
	return ok and v or false
end)()

print("[MapLoader] StreamingEnabled:", STREAMING_ENABLED)

local LIVE_STREAM_RADIUS = 1024
pcall(function()
	local r = gethiddenproperty(Workspace, "StreamingTargetRadius")
	if type(r) == "number" and r > 0 then
		LIVE_STREAM_RADIUS = r
	end
end)
print("[MapLoader] StreamingTargetRadius:", LIVE_STREAM_RADIUS)

local originalStreamOutBehavior = nil
local originalStreamingTargetRadius = nil
local originalStreamingIntegrity = nil
local originalModelStreamingBehavior = nil

local function applyStreamingOverrides()
	if not sethiddenproperty or not STREAMING_ENABLED then
		return
	end
	pcall(function()
		originalStreamOutBehavior = gethiddenproperty(Workspace, "StreamOutBehavior")
	end)
	pcall(function()
		originalStreamingTargetRadius = gethiddenproperty(Workspace, "StreamingTargetRadius")
	end)
	pcall(function()
		originalStreamingIntegrity = gethiddenproperty(Workspace, "StreamingIntegrityMode")
	end)
	pcall(function()
		originalModelStreamingBehavior = gethiddenproperty(Workspace, "ModelStreamingBehavior")
	end)

	pcall(function()
		sethiddenproperty(Workspace, "StreamOutBehavior", Enum.StreamOutBehavior.LowMemory)
	end)
	pcall(function()
		sethiddenproperty(Workspace, "StreamingTargetRadius", 8192)
	end)
	pcall(function()
		sethiddenproperty(Workspace, "StreamingIntegrityMode", Enum.StreamingIntegrityMode.Disabled)
	end)
	pcall(function()
		sethiddenproperty(Workspace, "ModelStreamingBehavior", Enum.ModelStreamingBehavior.Improved)
	end)
	pcall(function()
		sethiddenproperty(Workspace, "StreamingMinRadius", 5000)
	end)
end

local function restoreStreamingOverrides()
	if not sethiddenproperty or not STREAMING_ENABLED then
		return
	end
	if originalStreamOutBehavior then
		pcall(function()
			sethiddenproperty(Workspace, "StreamOutBehavior", originalStreamOutBehavior)
		end)
	end
	if originalStreamingTargetRadius then
		pcall(function()
			sethiddenproperty(Workspace, "StreamingTargetRadius", originalStreamingTargetRadius)
		end)
	end
	if originalStreamingIntegrity then
		pcall(function()
			sethiddenproperty(Workspace, "StreamingIntegrityMode", originalStreamingIntegrity)
		end)
	end
	if originalModelStreamingBehavior then
		pcall(function()
			sethiddenproperty(Workspace, "ModelStreamingBehavior", originalModelStreamingBehavior)
		end)
	end
end

local function applyPersistentStreaming(obj)
	if obj:IsA("Model") then
		pcall(function()
			obj.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
		end)
	end
end

for _, d in ipairs(game:GetDescendants()) do
	applyPersistentStreaming(d)
end
game.DescendantAdded:Connect(applyPersistentStreaming)

local States = {
	IDLE = "idle",
	INITIALIZING = "initializing",
	STREAMING = "streaming",
	PHASE1 = "phase1",
	PHASE2 = "phase2",
	ROAMING = "roaming",
	ERROR = "error",
}

local StateMachine = {
	current = States.IDLE,
	previous = nil,
	transitions = {
		[States.IDLE] = { States.INITIALIZING, States.ERROR },
		[States.INITIALIZING] = { States.STREAMING, States.PHASE1, States.ERROR, States.IDLE },
		[States.STREAMING] = { States.PHASE1, States.ERROR, States.IDLE },
		[States.PHASE1] = { States.PHASE2, States.ERROR, States.IDLE },
		[States.PHASE2] = { States.ROAMING, States.ERROR, States.IDLE },
		[States.ROAMING] = { States.IDLE, States.ERROR },
		[States.ERROR] = { States.IDLE },
	},
}

function StateMachine:transition(newState)
	local allowed = self.transitions[self.current]
	if not allowed or not table.find(allowed, newState) then
		warn("[MapLoader] Invalid transition:", self.current, "->", newState)
		return false
	end
	self.previous = self.current
	self.current = newState
	return true
end

local LoadStrategies = {
	SLOW = {
		name = "Slow",
		chunkSize = 250,
		batchSize = 100,
		fastWait = 2.5,
		hopInterval = 0.35,
		hopRadius = 60,
		hopYRange = 20,
		stabilityTime = 2.0,
		chunkTimeout = 25,
	},
	FAST = {
		name = "Fast",
		chunkSize = 250,
		batchSize = 100,
		fastWait = 0.12,
		hopInterval = 0.05,
		hopRadius = 60,
		hopYRange = 20,
		stabilityTime = 0.5,
		chunkTimeout = 8,
	},
}

local FlyMethods = { CFLY = "cfly", SFLY = "sfly" }
local MoveMethods = { TPPOS = "tppos", TWEENTPPOS = "tweentppos" }

local currentStrategy = LoadStrategies.SLOW
local currentFlyMethod = FlyMethods.CFLY
local currentMoveMethod = MoveMethods.TPPOS
local tweenSpeedForMovement = 0.5

local ROAM_WAIT = 0.35

local STREAMING_TIMEOUT = 25
local STABILITY_CHECK_INTERVAL = 0.25
local GROWTH_THRESHOLD = 5
local IDLE_SCALE_DIVISOR = 400
local MAX_IDLE_MULTIPLIER = 6
local MIN_MONITOR_TIME = 2
local MAX_CHUNK_RETRIES = 3
local STREAM_CONCURRENCY = 8
local VERTICAL_SLICES = 2
local POST_SWEEP_SETTLE = 3

local GAME_ID = game.PlaceId

local GameConfigs = {
	[606849621] = {
		name = "Jailbreak",
		useCustomBounds = true,
		bounds = {
			topLeft = Vector3.new(-2898.492, 15.887, -5235.022),
			topRight = Vector3.new(3003.559, 15.887, -5235.022),
			bottomLeft = Vector3.new(-2898.484, 16.062, 3514.802),
			bottomRight = Vector3.new(3003.488, 16.159, 3514.865),
		},
		chunkSize = 800,
		gridSpacing = 700,
		heightOffset = 150,
		skipStabilityCheck = true,
		fastWait = 0.04,
		phaseTimeTarget = 240,
	},
}

local currentGameConfig = GameConfigs[GAME_ID]

local FLYING = false
local flyKeyDown = nil
local flyKeyUp = nil
local iyflyspeed = 50
local vehicleflyspeed = 50
local QEfly = true

local cflyLoop = nil
local cflyActive = false
local cflyPaused = false
local cflyRespawnConn = nil

local function sFLY(vfly)
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end

	if flyKeyDown then
		flyKeyDown:Disconnect()
	end
	if flyKeyUp then
		flyKeyUp:Disconnect()
	end

	local T = char:FindFirstChild("HumanoidRootPart")
	if not T then
		return
	end

	local CONTROL = { F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0 }
	local lCONTROL = { F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0 }
	local SPEED = 0

	local function FLY()
		FLYING = true
		local BG = Instance.new("BodyGyro")
		local BV = Instance.new("BodyVelocity")
		BG.P = 9e4
		BG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
		BG.CFrame = T.CFrame
		BG.Parent = T
		BV.Velocity = Vector3.zero
		BV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
		BV.Parent = T

		task.spawn(function()
			repeat
				task.wait()
				local cam = Workspace.CurrentCamera
				if not vfly and humanoid then
					humanoid.PlatformStand = true
				end
				local moving = CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0
				SPEED = moving and 50 or 0
				if moving then
					BV.Velocity = (
						(cam.CFrame.LookVector * (CONTROL.F + CONTROL.B))
						+ (
							(
								cam.CFrame
								* CFrame.new(
									CONTROL.L + CONTROL.R,
									(CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2,
									0
								).p
							) - cam.CFrame.p
						)
					) * SPEED
					lCONTROL = { F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R }
				elseif SPEED ~= 0 then
					BV.Velocity = (
						(cam.CFrame.LookVector * (lCONTROL.F + lCONTROL.B))
						+ (
							(
								cam.CFrame
								* CFrame.new(
									lCONTROL.L + lCONTROL.R,
									(lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2,
									0
								).p
							) - cam.CFrame.p
						)
					) * SPEED
				else
					BV.Velocity = Vector3.zero
				end
				BG.CFrame = cam.CFrame
			until not FLYING
			BG:Destroy()
			BV:Destroy()
			if humanoid then
				humanoid.PlatformStand = false
			end
		end)
	end

	flyKeyDown = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		local spd = vfly and vehicleflyspeed or iyflyspeed
		if input.KeyCode == Enum.KeyCode.W then
			CONTROL.F = spd
		elseif input.KeyCode == Enum.KeyCode.S then
			CONTROL.B = -spd
		elseif input.KeyCode == Enum.KeyCode.A then
			CONTROL.L = -spd
		elseif input.KeyCode == Enum.KeyCode.D then
			CONTROL.R = spd
		elseif input.KeyCode == Enum.KeyCode.E and QEfly then
			CONTROL.Q = spd * 2
		elseif input.KeyCode == Enum.KeyCode.Q and QEfly then
			CONTROL.E = -spd * 2
		end
		pcall(function()
			camera.CameraType = Enum.CameraType.Track
		end)
	end)

	flyKeyUp = UserInputService.InputEnded:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.W then
			CONTROL.F = 0
		elseif input.KeyCode == Enum.KeyCode.S then
			CONTROL.B = 0
		elseif input.KeyCode == Enum.KeyCode.A then
			CONTROL.L = 0
		elseif input.KeyCode == Enum.KeyCode.D then
			CONTROL.R = 0
		elseif input.KeyCode == Enum.KeyCode.E then
			CONTROL.Q = 0
		elseif input.KeyCode == Enum.KeyCode.Q then
			CONTROL.E = 0
		end
	end)
	FLY()
end

local function sNOFLY()
	FLYING = false
	if flyKeyDown then
		flyKeyDown:Disconnect()
	end
	if flyKeyUp then
		flyKeyUp:Disconnect()
	end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.PlatformStand = false
	end
	pcall(function()
		Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	end)
end

local function applyCflyToCharacter(character)
	if not character then
		return
	end
	local hum = character:FindFirstChildOfClass("Humanoid")
	local head = character:FindFirstChild("Head")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hum then
		hum.PlatformStand = true
	end
	if hrp then
		hrp.Anchored = true
	end
	if head then
		head.Anchored = true
	end
end

local function startCfly()
	if cflyActive then
		return
	end
	cflyActive = true
	cflyPaused = false
	applyCflyToCharacter(player.Character)

	if cflyRespawnConn then
		cflyRespawnConn:Disconnect()
	end
	cflyRespawnConn = player.CharacterAdded:Connect(function(newChar)
		if not cflyActive then
			return
		end
		newChar:WaitForChild("HumanoidRootPart", 10)
		newChar:WaitForChild("Head", 10)
		newChar:WaitForChild("Humanoid", 10)
		task.wait(0.1)
		applyCflyToCharacter(newChar)
	end)

	if cflyLoop then
		cflyLoop:Disconnect()
	end
	cflyLoop = RunService.Heartbeat:Connect(function()
		if cflyPaused then
			return
		end
		local char = player.Character
		if not char then
			return
		end
		local hum = char:FindFirstChildOfClass("Humanoid")
		local h = char:FindFirstChild("Head")
		if not hum or not h then
			return
		end
		local moveDir = hum.MoveDirection * (50 * 1 / 60)
		local headCF = h.CFrame
		local cam = Workspace.CurrentCamera
		local camCF = cam.CFrame
		local camOffset = headCF:ToObjectSpace(camCF).Position
		camCF = camCF * CFrame.new(-camOffset.X, -camOffset.Y, -camOffset.Z + 1)
		local camPos = camCF.Position
		local headPos = headCF.Position
		local objVel = CFrame.new(camPos, Vector3.new(headPos.X, camPos.Y, headPos.Z)):VectorToObjectSpace(moveDir)
		h.CFrame = CFrame.new(headPos) * (camCF - camPos) * CFrame.new(objVel)
	end)
end

local function stopCfly()
	if not cflyActive then
		return
	end
	cflyActive = false
	cflyPaused = false
	if cflyLoop then
		cflyLoop:Disconnect()
		cflyLoop = nil
	end
	if cflyRespawnConn then
		cflyRespawnConn:Disconnect()
		cflyRespawnConn = nil
	end
	local char = player.Character
	if not char then
		return
	end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if hum then
		hum.PlatformStand = false
	end
	if hrp then
		hrp.Anchored = false
	end
	if head then
		head.Anchored = false
	end
end

local function tpCharTo(pos)
	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	local head = character:FindFirstChild("Head")
	if not hrp then
		return
	end
	cflyPaused = true
	hrp.CFrame = CFrame.new(pos)
	if head then
		head.CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0))
	end
	RunService.Heartbeat:Wait()
	cflyPaused = false
end

local function tweenTpPos(pos)
	local character = player.Character
	if not character then
		return
	end
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	if currentFlyMethod == FlyMethods.SFLY then
		if flyKeyDown then
			flyKeyDown:Disconnect()
		end
		if flyKeyUp then
			flyKeyUp:Disconnect()
		end
	end
	local tween = TweenService:Create(
		hrp,
		TweenInfo.new(tweenSpeedForMovement, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.new(pos) }
	)
	tween:Play()
	tween.Completed:Wait()
	if currentFlyMethod == FlyMethods.SFLY and FLYING then
		sFLY(false)
	end
end

local function moveCharacter(pos)
	if currentMoveMethod == MoveMethods.TWEENTPPOS then
		tweenTpPos(pos)
	else
		tpCharTo(pos)
	end
end

local function startFly()
	if currentFlyMethod == FlyMethods.SFLY then
		sFLY(false)
	else
		startCfly()
	end
end

local function stopFly()
	if currentFlyMethod == FlyMethods.SFLY then
		sNOFLY()
	else
		stopCfly()
	end
end

local function countPartsInRadius(position, radius)
	local ok, parts = pcall(function()
		return Workspace:GetPartBoundsInRadius(position, radius)
	end)
	if not ok or not parts then
		return 0
	end
	local n = 0
	for _, p in ipairs(parts) do
		if p:IsA("BasePart") and p.Anchored then
			n += 1
		end
	end
	return n
end

local function waitRegionLoaded(pos, radius, maxWait, stabilityNeeded)
	stabilityNeeded = stabilityNeeded or currentStrategy.stabilityTime
	local last, stableFor, elapsed = countPartsInRadius(pos, radius), 0, 0
	local minObserve = math.max(math.min(MIN_MONITOR_TIME, stabilityNeeded), STABILITY_CHECK_INTERVAL * 2)
	while elapsed < maxWait do
		task.wait(STABILITY_CHECK_INTERVAL)
		elapsed += STABILITY_CHECK_INTERVAL
		local now = countPartsInRadius(pos, radius)
		local delta = math.max(0, now - last)
		last = now
		if delta >= GROWTH_THRESHOLD then
			stableFor = 0
			local extra = math.floor(now / IDLE_SCALE_DIVISOR)
			maxWait = math.clamp(maxWait, stabilityNeeded + extra, stabilityNeeded * MAX_IDLE_MULTIPLIER)
		else
			stableFor += STABILITY_CHECK_INTERVAL
		end
		if elapsed >= minObserve and stableFor >= stabilityNeeded then
			break
		end
	end
end

local function sortByNearest(points, origin)
	table.sort(points, function(a, b)
		return (a.position - origin).Magnitude < (b.position - origin).Magnitude
	end)
end

local function runConcurrentStream(points, radius, stopSignal, onProgress)
	local total = #points
	if total == 0 then
		return
	end

	local nextIndex = 0
	local done = 0
	local active = math.min(STREAM_CONCURRENCY, total)
	local chunkTimeout = currentStrategy.chunkTimeout or STREAMING_TIMEOUT

	local driveRunning = true
	task.spawn(function()
		local stride = math.max(1, math.floor(total / 24))
		local i = 1
		while driveRunning and not stopSignal.stop do
			local pt = points[i]
			if pt then
				pcall(function()
					local char = player.Character
					if char then
						char:PivotTo(CFrame.new(pt.position))
					end
				end)
			end
			i += stride
			if i > total then
				i = 1
			end
			task.wait(0.15)
		end
	end)

	for _ = 1, active do
		task.spawn(function()
			pcall(function()
				while not stopSignal.stop do
					nextIndex += 1
					local pt = points[nextIndex]
					if not pt then
						return
					end

					task.spawn(function()
						pcall(function()
							player:RequestStreamAroundAsync(pt.position, chunkTimeout)
						end)
					end)

					waitRegionLoaded(pt.position, radius, chunkTimeout)

					done += 1
					if onProgress then
						onProgress(done, total)
					end
				end
			end)
			active -= 1
		end)
	end

	while active > 0 and not stopSignal.stop do
		task.wait(0.1)
	end
	driveRunning = false

	if not stopSignal.stop and POST_SWEEP_SETTLE > 0 then
		task.wait(POST_SWEEP_SETTLE)
	end
end

local function calculateMapBounds()
	print("[MapLoader] Calculating map bounds...")
	local positions = {}
	local partCount = 0
	for _, part in ipairs(Workspace:GetDescendants()) do
		if part:IsA("BasePart") and part.Anchored then
			table.insert(positions, part.Position)
			partCount += 1
			if partCount % 500 == 0 then
				task.wait()
			end
		end
	end
	if #positions == 0 then
		return nil
	end

	local function trimOutliers(coords)
		table.sort(coords)
		local n = #coords
		local q1 = coords[math.max(1, math.floor(n * 0.25))]
		local q3 = coords[math.min(n, math.floor(n * 0.75))]
		local iqr = q3 - q1
		return q1 - 1.5 * iqr, q3 + 1.5 * iqr
	end

	local xC, yC, zC = {}, {}, {}
	for _, pos in ipairs(positions) do
		table.insert(xC, pos.X)
		table.insert(yC, pos.Y)
		table.insert(zC, pos.Z)
	end
	local minX, maxX = trimOutliers(xC)
	local minY, maxY = trimOutliers(yC)
	local minZ, maxZ = trimOutliers(zC)
	local avgY = (minY + maxY) / 2

	return {
		topLeft = Vector3.new(minX, avgY, minZ),
		topRight = Vector3.new(maxX, avgY, minZ),
		bottomLeft = Vector3.new(minX, avgY, maxZ),
		bottomRight = Vector3.new(maxX, avgY, maxZ),
		center = Vector3.new((minX + maxX) / 2, avgY, (minZ + maxZ) / 2),
		dimensions = Vector3.new(maxX - minX, maxY - minY, maxZ - minZ),
		partCount = partCount,
	}
end

local function calculateOptimalSpacing(dimensions)
	return math.clamp(math.sqrt(dimensions.X * dimensions.Z / 200), 300, 1000)
end

local function hasTerrainInMap()
	if not gethiddenproperty then
		return false
	end
	pcall(function()
		writefile("MLSG.txt", gethiddenproperty(Workspace.Terrain, "SmoothGrid"))
		writefile("MLPG.txt", gethiddenproperty(Workspace.Terrain, "PhysicsGrid"))
	end)
	task.wait(0.5)
	local sg, pg = "", ""
	pcall(function()
		sg = readfile("MLSG.txt") or ""
	end)
	pcall(function()
		pg = readfile("MLPG.txt") or ""
	end)
	pcall(function()
		delfile("MLSG.txt")
		delfile("MLPG.txt")
	end)
	return (sg ~= "" and sg ~= "nil") or (pg ~= "" and pg ~= "nil")
end

local function expandBounds(bounds, offset)
	local o = Vector3.new(offset, 0, offset)
	return {
		topLeft = bounds.topLeft - o,
		topRight = bounds.topRight + o,
		bottomLeft = bounds.bottomLeft - o,
		bottomRight = bounds.bottomRight + o,
		center = bounds.center,
		dimensions = bounds.dimensions + Vector3.new(offset * 2, 0, offset * 2),
		partCount = bounds.partCount,
	}
end

local function shouldUseBoundedMode(bounds)
	if not bounds then
		return false, nil
	end
	local dims = bounds.dimensions
	if dims.X > 3000 or dims.Z > 3000 then
		local spacing = calculateOptimalSpacing(dims)
		if hasTerrainInMap() then
			bounds = expandBounds(bounds, 2048)
			print("[MapLoader] Terrain detected, expanding bounds by 2048 studs")
		end
		print(string.format("[MapLoader] Large map: %.0fx%.0f | spacing %.0f", dims.X, dims.Z, spacing))
		return true,
			{
				name = "Auto-Detected Map",
				useCustomBounds = true,
				bounds = bounds,
				chunkSize = math.clamp(spacing * 1.2, 400, 1000),
				gridSpacing = spacing,
				heightOffset = 150,
				skipStabilityCheck = true,
				fastWait = 0.04,
			}
	end
	print(string.format("[MapLoader] Standard map: %.0fx%.0f", dims.X, dims.Z))
	return false, nil
end

local function boundsExtents(bounds)
	local minX = math.min(bounds.topLeft.X, bounds.topRight.X, bounds.bottomLeft.X, bounds.bottomRight.X)
	local maxX = math.max(bounds.topLeft.X, bounds.topRight.X, bounds.bottomLeft.X, bounds.bottomRight.X)
	local minZ = math.min(bounds.topLeft.Z, bounds.topRight.Z, bounds.bottomLeft.Z, bounds.bottomRight.Z)
	local maxZ = math.max(bounds.topLeft.Z, bounds.topRight.Z, bounds.bottomLeft.Z, bounds.bottomRight.Z)
	local avgY = (bounds.topLeft.Y + bounds.topRight.Y + bounds.bottomLeft.Y + bounds.bottomRight.Y) / 4
	return minX, maxX, minZ, maxZ, avgY
end

local function generateBoundedGrid(config)
	local minX, maxX, minZ, maxZ, avgY = boundsExtents(config.bounds)
	local spacing = config.gridSpacing
	local slices = VERTICAL_SLICES
	local centers = {}

	for x = minX, maxX, spacing do
		for z = minZ, maxZ, spacing do
			for s = 0, slices - 1 do
				local yOffset = (s - math.floor((slices - 1) / 2)) * (LIVE_STREAM_RADIUS * 0.8)
				table.insert(centers, {
					position = Vector3.new(x, avgY + yOffset, z),
					parts = {},
					retries = 0,
					maxRetries = MAX_CHUNK_RETRIES,
				})
			end
		end
	end
	return centers
end

local function calculateOptimalChunkSize(parts)
	if #parts == 0 then
		return currentStrategy.chunkSize
	end
	local bMin = Vector3.new(math.huge, math.huge, math.huge)
	local bMax = -bMin
	for _, p in ipairs(parts) do
		bMin =
			Vector3.new(math.min(bMin.X, p.Position.X), math.min(bMin.Y, p.Position.Y), math.min(bMin.Z, p.Position.Z))
		bMax =
			Vector3.new(math.max(bMax.X, p.Position.X), math.max(bMax.Y, p.Position.Y), math.max(bMax.Z, p.Position.Z))
	end
	local vol = (bMax - bMin)
	local totalVol = vol.X * vol.Y * vol.Z
	if totalVol <= 0 then
		return currentStrategy.chunkSize
	end
	local density = #parts / totalVol
	return math.floor(math.clamp(500 / math.sqrt(math.max(density, 0.0001)), 250, 2000))
end

local function buildCenters(parts, chunkSizeOverride)
	local size = chunkSizeOverride or currentStrategy.chunkSize
	local buckets = {}
	for _, p in ipairs(parts) do
		local key = math.floor(p.Position.X / size)
			.. ","
			.. math.floor(p.Position.Y / size)
			.. ","
			.. math.floor(p.Position.Z / size)
		if not buckets[key] then
			buckets[key] = { sum = Vector3.zero, count = 0, parts = {} }
		end
		buckets[key].sum += p.Position
		buckets[key].count += 1
		table.insert(buckets[key].parts, p)
	end
	local centers = {}
	for _, b in pairs(buckets) do
		table.insert(
			centers,
			{ position = b.sum / b.count, parts = b.parts, retries = 0, maxRetries = MAX_CHUNK_RETRIES }
		)
	end
	return centers
end

local function buildColumns(centers, chunkSizeOverride)
	local size = chunkSizeOverride or currentStrategy.chunkSize
	local minX = math.huge
	for _, c in ipairs(centers) do
		minX = math.min(minX, c.position.X)
	end
	local columns = {}
	for _, c in ipairs(centers) do
		local col = math.floor((c.position.X - minX) / size)
		columns[col] = columns[col] or {}
		table.insert(columns[col], c)
	end
	return columns
end

local DUMMY_FOLDER = Instance.new("Folder")
local running = false
local minimized = false
local stopRequested = false
local skipPhase = false

local originalCFrame, originalCameraType, savedFramePos

local gui, frame, content
local barBg, progressFill, progressText
local actionBtn, strategyBtn, flyMethodBtn, moveMethodBtn, skipBtn
local seWarningLabel

local globalStartTime, totalWorkItems, globalDone
local allParts, chunkCenters, chunkSize = {}, {}, currentStrategy.chunkSize

local function setRendering(on)
	RunService:Set3dRenderingEnabled(on)
end

local function restoreCamera()
	setRendering(true)
	stopFly()
	restoreStreamingOverrides()
	if originalCameraType then
		camera.CameraType = originalCameraType
	end
	if originalCFrame then
		camera.CFrame = originalCFrame
	end
end

local function formatETA(startTime, done, total)
	if done >= total then
		return "00:00"
	end
	local elapsed = tick() - startTime
	local remain = math.max(0, total - done)
	local eta = math.floor((elapsed / math.max(done, 1)) * remain)
	return string.format("%02d:%02d", math.floor(eta / 60), eta % 60)
end

local function phaseText(phase, done, total, eta)
	return string.format("Phase %s | %d/%d | ETA %s", phase, done, total, eta)
end

local function setProgress(alpha, text)
	progressFill.Size = UDim2.new(math.clamp(alpha, 0, 1), 0, 1, 0)
	progressText.Text = text
	barBg.BackgroundColor3 = Color3.fromHex("#1d2f49")
end

local function setSkipBtnVisible(on)
	if not skipBtn then
		return
	end
	skipBtn.BackgroundColor3 = on and Color3.fromHex("#5a3a7a") or Color3.fromHex("#1a1a2e")
	skipBtn.TextColor3 = on and Color3.new(1, 1, 1) or Color3.fromHex("#4c4c6a")
end

local function hopAroundChunk(chunkPos, duration)
	local elapsed = 0
	local hopInterval = currentStrategy.hopInterval
	local hopRadius = currentStrategy.hopRadius
	local hopYRange = currentStrategy.hopYRange
	moveCharacter(chunkPos)
	while elapsed < duration do
		if stopRequested or skipPhase then
			return
		end
		moveCharacter(
			Vector3.new(
				chunkPos.X + math.random(-hopRadius * 10, hopRadius * 10) / 10,
				chunkPos.Y + math.random(-hopYRange * 10, hopYRange * 10) / 10,
				chunkPos.Z + math.random(-hopRadius * 10, hopRadius * 10) / 10
			)
		)
		task.wait(hopInterval)
		elapsed += hopInterval
	end
end

local function executePhase1(centers, stopSignal)
	if not StateMachine:transition(States.PHASE1) then
		return false
	end
	skipPhase = false
	setRendering(false)
	setSkipBtnVisible(true)

	local skipStability = (currentGameConfig and currentGameConfig.skipStabilityCheck) or not STREAMING_ENABLED

	if STREAMING_ENABLED and not skipStability then
		task.spawn(function()
			for _, center in ipairs(centers) do
				if stopSignal.stop or skipPhase then
					break
				end
				hopAroundChunk(center.position, currentStrategy.fastWait)
			end
		end)

		runConcurrentStream(centers, LIVE_STREAM_RADIUS, stopSignal, function(done, total)
			globalDone = math.min(globalDone + 1, totalWorkItems)
			setProgress(
				globalDone / totalWorkItems,
				phaseText("1/2", globalDone, totalWorkItems, formatETA(globalStartTime, globalDone, totalWorkItems))
			)
		end)

		if stopSignal.stop then
			setSkipBtnVisible(false)
			return false
		end
	else
		for _, center in ipairs(centers) do
			if stopRequested then
				setSkipBtnVisible(false)
				return false
			end
			if skipPhase then
				break
			end
			globalDone += 1
			hopAroundChunk(center.position, currentStrategy.fastWait)
			setProgress(
				globalDone / totalWorkItems,
				phaseText("1/2", globalDone, totalWorkItems, formatETA(globalStartTime, globalDone, totalWorkItems))
			)
		end
	end

	setRendering(true)
	setSkipBtnVisible(false)
	skipPhase = false
	return true
end

local function executePhase2(columns, stopSignal)
	if not StateMachine:transition(States.PHASE2) then
		return false
	end
	skipPhase = false
	setRendering(false)
	setSkipBtnVisible(true)

	local skipStability = (currentGameConfig and currentGameConfig.skipStabilityCheck) or not STREAMING_ENABLED

	local flatList = {}
	for col = 0, math.huge do
		local list = columns[col]
		if not list then
			break
		end
		table.sort(list, function(a, b)
			return a.position.Z > b.position.Z
		end)
		for _, c in ipairs(list) do
			table.insert(flatList, c)
		end
	end

	if STREAMING_ENABLED and not skipStability then
		task.spawn(function()
			for _, center in ipairs(flatList) do
				if stopSignal.stop or skipPhase then
					break
				end
				hopAroundChunk(center.position, currentStrategy.fastWait)
			end
		end)

		runConcurrentStream(flatList, LIVE_STREAM_RADIUS, stopSignal, function(done, total)
			globalDone = math.min(globalDone + 1, totalWorkItems)
			setProgress(
				globalDone / totalWorkItems,
				phaseText("2/2", globalDone, totalWorkItems, formatETA(globalStartTime, globalDone, totalWorkItems))
			)
		end)

		if stopSignal.stop then
			setSkipBtnVisible(false)
			return false
		end
	else
		for _, c in ipairs(flatList) do
			if stopRequested then
				setSkipBtnVisible(false)
				return false
			end
			if skipPhase then
				break
			end
			globalDone += 1
			hopAroundChunk(c.position, currentStrategy.fastWait)
			setProgress(
				globalDone / totalWorkItems,
				phaseText("2/2", globalDone, totalWorkItems, formatETA(globalStartTime, globalDone, totalWorkItems))
			)
		end
	end

	setRendering(true)
	setSkipBtnVisible(false)
	skipPhase = false
	return true
end

local function executeRoaming(centers)
	if not StateMachine:transition(States.ROAMING) then
		return false
	end
	setProgress(1, "Roaming")
	while not stopRequested do
		local center = centers[math.random(1, #centers)]
		moveCharacter(center.position)
		task.wait(ROAM_WAIT)
	end
	return true
end

local function streamParts(callback)
	StateMachine:transition(States.STREAMING)
	local batch = {}
	local charModel = player.Character or DUMMY_FOLDER
	local processedCount = 0
	setProgress(0, "Streaming parts... 0 found")

	for _, inst in ipairs(Workspace:GetDescendants()) do
		if stopRequested then
			return false
		end
		if inst:IsA("BasePart") and inst.Transparency < 1 and not inst:IsDescendantOf(charModel) then
			batch[#batch + 1] = inst
			processedCount += 1
			if #batch >= currentStrategy.batchSize then
				callback(batch)
				batch = {}
				task.wait()
				setProgress(0, string.format("Streaming parts... %d found", processedCount))
			end
		end
	end
	if #batch > 0 then
		callback(batch)
	end
	return true
end

local function runLoader()
	running = true
	stopRequested = false
	skipPhase = false

	originalCFrame = camera.CFrame
	originalCameraType = camera.CameraType

	applyStreamingOverrides()
	startFly()

	actionBtn.Text = "Stop"
	actionBtn.BackgroundColor3 = Color3.fromHex("#c4302b")

	if not StateMachine:transition(States.INITIALIZING) then
		restoreCamera()
		running = false
		StateMachine:transition(States.ERROR)
		return
	end

	if not currentGameConfig then
		setProgress(0.1, "Analyzing map boundaries...")
		local detectedBounds = calculateMapBounds()
		if detectedBounds then
			local useBounded, autoConfig = shouldUseBoundedMode(detectedBounds)
			if useBounded then
				currentGameConfig = autoConfig
			end
		end
	end

	local stopSignal = { stop = false }

	local function runPhases(centers, cfgChunkSize)
		local columns = buildColumns(centers, cfgChunkSize)
		local p1Total, p2Total = #centers, 0
		for _, col in pairs(columns) do
			p2Total += #col
		end
		totalWorkItems = p1Total + p2Total
		globalDone = 0
		globalStartTime = tick()

		local ok = executePhase1(centers, stopSignal)
		if not ok then
			return false
		end
		ok = executePhase2(columns, stopSignal)
		return ok
	end

	if currentGameConfig and currentGameConfig.useCustomBounds then
		print("[MapLoader] Config:", currentGameConfig.name)
		chunkCenters = generateBoundedGrid(currentGameConfig)

		if #chunkCenters == 0 then
			restoreCamera()
			running = false
			StateMachine:transition(States.IDLE)
			setProgress(0, "Grid generation failed")
			actionBtn.Text = "Start"
			return
		end

		local origFW = currentStrategy.fastWait
		if currentGameConfig.fastWait then
			currentStrategy.fastWait = currentGameConfig.fastWait
		end

		local success = runPhases(chunkCenters, currentGameConfig.chunkSize)

		currentStrategy.fastWait = origFW

		if success then
			print(string.format("[MapLoader] Phases done in %.1fs", tick() - globalStartTime))
			executeRoaming(chunkCenters)
			setProgress(1, string.format("Complete | %s", currentGameConfig.name))
		else
			setProgress(0, "Stopped")
		end

		restoreCamera()
		running = false
		StateMachine:transition(States.IDLE)
		actionBtn.Text = "Start"
		if not GameConfigs[GAME_ID] then
			currentGameConfig = nil
		end
		return
	end

	allParts = {}
	local streamSuccess = streamParts(function(batch)
		for _, part in ipairs(batch) do
			table.insert(allParts, part)
		end
	end)

	if not streamSuccess or #allParts == 0 then
		restoreCamera()
		running = false
		StateMachine:transition(States.IDLE)
		setProgress(0, "No parts found or stopped")
		actionBtn.Text = "Start"
		return
	end

	chunkSize = calculateOptimalChunkSize(allParts)
	chunkCenters = buildCenters(allParts, chunkSize)

	sortByNearest(chunkCenters, player.Character and player.Character:GetPivot().Position or Vector3.new(0, 50, 0))

	if #chunkCenters == 0 then
		restoreCamera()
		running = false
		StateMachine:transition(States.IDLE)
		setProgress(0, "No chunks generated")
		actionBtn.Text = "Start"
		return
	end

	local success = runPhases(chunkCenters, chunkSize)

	if success then
		executeRoaming(chunkCenters)
		setProgress(0, "Complete")
	else
		setProgress(0, "Stopped")
	end

	restoreCamera()
	running = false
	StateMachine:transition(States.IDLE)
	actionBtn.Text = "Start"
end

pcall(function()
	player.PlayerGui:FindFirstChild("MapLoader"):Destroy()
end)

gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "MapLoader"
gui.ResetOnSpawn = false
gui.DisplayOrder = 999999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.IgnoreGuiInset = true

frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 369, 0, 188)
frame.Position = UDim2.new(0.5, -184, 0.5, -94)
frame.BackgroundColor3 = Color3.fromHex("#151618")
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 1
stroke.Color = Color3.new(1, 1, 1)
stroke.Transparency = 0.75

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 36)
title.BackgroundColor3 = Color3.fromHex("#294a7a")
title.Text = currentGameConfig and ("MapLoader | " .. currentGameConfig.name) or "MapLoader"
title.Font = Enum.Font.BuilderSansExtraBold
title.TextSize = 18
title.TextColor3 = Color3.new(1, 1, 1)
title.TextXAlignment = Enum.TextXAlignment.Center
title.BorderSizePixel = 0

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0, 36, 0, 36)
close.Position = UDim2.new(1, -36, 0, 0)
close.Text = "x"
close.Font = Enum.Font.BuilderSansExtraBold
close.TextSize = 20
close.TextColor3 = Color3.new(1, 1, 1)
close.BackgroundTransparency = 1
close.BorderSizePixel = 0

local minimize = Instance.new("TextButton", frame)
minimize.Size = UDim2.new(0, 36, 0, 36)
minimize.Position = UDim2.new(1, -60, 0, 0)
minimize.Text = "-"
minimize.Font = Enum.Font.BuilderSansExtraBold
minimize.TextSize = 24
minimize.TextColor3 = Color3.new(1, 1, 1)
minimize.BackgroundTransparency = 1
minimize.BorderSizePixel = 0

content = Instance.new("Frame", frame)
content.Position = UDim2.new(0, 0, 0, 36)
content.Size = UDim2.new(1, 0, 1, -36)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0

seWarningLabel = Instance.new("TextLabel", content)
seWarningLabel.Size = UDim2.new(0, 347, 0, 16)
seWarningLabel.Position = UDim2.new(0, 11, 0, 0)
seWarningLabel.BackgroundColor3 = Color3.fromHex("#7a4a00")
seWarningLabel.TextColor3 = Color3.fromHex("#ffcc66")
seWarningLabel.Font = Enum.Font.BuilderSansBold
seWarningLabel.TextSize = 11
seWarningLabel.Text = "[ ! ]  StreamingEnabled is OFF  [ ! ]"
seWarningLabel.BorderSizePixel = 0
seWarningLabel.Visible = not STREAMING_ENABLED

local barTop = STREAMING_ENABLED and 14 or 34

barBg = Instance.new("Frame", content)
barBg.Size = UDim2.new(0, 347, 0, 20)
barBg.Position = UDim2.new(0, 11, 0, barTop)
barBg.BackgroundColor3 = Color3.fromHex("#1d2f49")
barBg.BorderSizePixel = 0

progressFill = Instance.new("Frame", barBg)
progressFill.Size = UDim2.new(0, 0, 1, 0)
progressFill.BackgroundColor3 = Color3.fromHex("#e6b32f")
progressFill.BorderSizePixel = 0

progressText = Instance.new("TextLabel", barBg)
progressText.Size = UDim2.new(1, 0, 1, 0)
progressText.BackgroundTransparency = 1
progressText.Text = "Idle"
progressText.Font = Enum.Font.BuilderSansExtraBold
progressText.TextSize = 12
progressText.TextColor3 = Color3.new(1, 1, 1)
progressText.BorderSizePixel = 0

local stratTop = barTop + 24
local flyTop = stratTop + 32
local actionTop = flyTop + 32

strategyBtn = Instance.new("TextButton", content)
strategyBtn.Size = UDim2.new(0, 347, 0, 28)
strategyBtn.Position = UDim2.new(0, 11, 0, stratTop)
strategyBtn.Text = "Strategy: " .. currentStrategy.name
strategyBtn.Font = Enum.Font.BuilderSansExtraBold
strategyBtn.TextSize = 12
strategyBtn.BackgroundColor3 = Color3.fromHex("#23456d")
strategyBtn.TextColor3 = Color3.new(1, 1, 1)
strategyBtn.BorderSizePixel = 0
strategyBtn.AutoButtonColor = false

flyMethodBtn = Instance.new("TextButton", content)
flyMethodBtn.Size = UDim2.new(0, 171, 0, 28)
flyMethodBtn.Position = UDim2.new(0, 11, 0, flyTop)
flyMethodBtn.Text = "Fly: cFLY"
flyMethodBtn.Font = Enum.Font.BuilderSansExtraBold
flyMethodBtn.TextSize = 12
flyMethodBtn.BackgroundColor3 = Color3.fromHex("#23456d")
flyMethodBtn.TextColor3 = Color3.new(1, 1, 1)
flyMethodBtn.BorderSizePixel = 0
flyMethodBtn.AutoButtonColor = false

moveMethodBtn = Instance.new("TextButton", content)
moveMethodBtn.Size = UDim2.new(0, 171, 0, 28)
moveMethodBtn.Position = UDim2.new(0, 186, 0, flyTop)
moveMethodBtn.Text = "Move: tpPos"
moveMethodBtn.Font = Enum.Font.BuilderSansExtraBold
moveMethodBtn.TextSize = 12
moveMethodBtn.BackgroundColor3 = Color3.fromHex("#23456d")
moveMethodBtn.TextColor3 = Color3.new(1, 1, 1)
moveMethodBtn.BorderSizePixel = 0
moveMethodBtn.AutoButtonColor = false

local skipTop = actionTop
local startTop = actionTop + 32

skipBtn = Instance.new("TextButton", content)
skipBtn.Size = UDim2.new(0, 347, 0, 28)
skipBtn.Position = UDim2.new(0, 11, 0, skipTop)
skipBtn.Text = "Skip Current Phase"
skipBtn.Font = Enum.Font.BuilderSansExtraBold
skipBtn.TextSize = 12
skipBtn.BackgroundColor3 = Color3.fromHex("#5a3a7a")
skipBtn.TextColor3 = Color3.new(1, 1, 1)
skipBtn.BorderSizePixel = 0
skipBtn.AutoButtonColor = false
skipBtn.Visible = true
skipBtn.BackgroundColor3 = Color3.fromHex("#1a1a2e")
skipBtn.TextColor3 = Color3.fromHex("#4c4c6a")

actionBtn = Instance.new("TextButton", content)
actionBtn.Size = UDim2.new(0, 347, 0, 32)
actionBtn.Position = UDim2.new(0, 11, 0, startTop)
actionBtn.Text = "Start"
actionBtn.Font = Enum.Font.BuilderSansExtraBold
actionBtn.TextSize = 15
actionBtn.BackgroundColor3 = Color3.fromHex("#57993d")
actionBtn.TextColor3 = Color3.new(1, 1, 1)
actionBtn.BorderSizePixel = 0
actionBtn.AutoButtonColor = false

frame.Size = UDim2.new(0, 369, 0, 36 + startTop + 40)

local BTN_ACTION_DEFAULT = Color3.fromHex("#57993d")
local BTN_ACTION_HOVER = Color3.fromHex("#5cb337")
local BTN_ACTION_DOWN = Color3.fromHex("#6bcd2b")
local BTN_STOP_DEFAULT = Color3.fromHex("#993d3d")
local BTN_STOP_HOVER = Color3.fromHex("#b33636")
local BTN_STOP_DOWN = Color3.fromHex("#cd362c")
local BTN_OPTION_DEFAULT = Color3.fromHex("#23456d")
local BTN_OPTION_HOVER = Color3.fromHex("#4296fa")
local BTN_OPTION_DOWN = Color3.fromHex("#1b87fa")
local BTN_SKIP_DEFAULT = Color3.fromHex("#5a3a7a")
local BTN_SKIP_HOVER = Color3.fromHex("#7a4aaa")
local BTN_SKIP_DOWN = Color3.fromHex("#9a5acc")
local BTN_DISABLED_BG = Color3.fromHex("#1a1a2e")
local BTN_DISABLED_TEXT = Color3.fromHex("#4c4c6a")

local isJailbreak = currentGameConfig and currentGameConfig.name == "Jailbreak"
local JB_BG_DEFAULT = Color3.fromHex("#122337")
local JB_BG_HOVER = Color3.fromHex("#142d4b")
local JB_TEXT_DISABLED = Color3.fromHex("#4c4c4c")

local function updateFlyMoveAppearance()
	moveMethodBtn.BackgroundColor3 = isJailbreak and BTN_DISABLED_BG or BTN_OPTION_DEFAULT
	moveMethodBtn.TextColor3 = isJailbreak and BTN_DISABLED_TEXT or Color3.new(1, 1, 1)
	flyMethodBtn.BackgroundColor3 = isJailbreak and JB_BG_DEFAULT or BTN_OPTION_DEFAULT
	flyMethodBtn.TextColor3 = isJailbreak and JB_TEXT_DISABLED or Color3.new(1, 1, 1)

	flyMethodBtn.Text = "Fly: " .. (currentFlyMethod == FlyMethods.CFLY and "cFLY" or "sFLY")
	moveMethodBtn.Text = "Move: " .. (currentMoveMethod == MoveMethods.TPPOS and "tpPos" or "tweenTpPos")
end
updateFlyMoveAppearance()

local actionHov, stratHov, flyHov, moveHov, skipHov = false, false, false, false, false

actionBtn.MouseEnter:Connect(function()
	actionHov = true
	actionBtn.BackgroundColor3 = running and BTN_STOP_HOVER or BTN_ACTION_HOVER
end)
actionBtn.MouseLeave:Connect(function()
	actionHov = false
	actionBtn.BackgroundColor3 = running and BTN_STOP_DEFAULT or BTN_ACTION_DEFAULT
end)
actionBtn.MouseButton1Down:Connect(function()
	actionBtn.BackgroundColor3 = running and BTN_STOP_DOWN or BTN_ACTION_DOWN
end)
actionBtn.MouseButton1Up:Connect(function()
	actionBtn.BackgroundColor3 = running and (actionHov and BTN_STOP_HOVER or BTN_STOP_DEFAULT)
		or (actionHov and BTN_ACTION_HOVER or BTN_ACTION_DEFAULT)
end)

strategyBtn.MouseEnter:Connect(function()
	stratHov = true
	strategyBtn.BackgroundColor3 = BTN_OPTION_HOVER
end)
strategyBtn.MouseLeave:Connect(function()
	stratHov = false
	strategyBtn.BackgroundColor3 = BTN_OPTION_DEFAULT
end)
strategyBtn.MouseButton1Down:Connect(function()
	strategyBtn.BackgroundColor3 = BTN_OPTION_DOWN
end)
strategyBtn.MouseButton1Up:Connect(function()
	strategyBtn.BackgroundColor3 = stratHov and BTN_OPTION_HOVER or BTN_OPTION_DEFAULT
end)

flyMethodBtn.MouseEnter:Connect(function()
	flyHov = true
	if not isJailbreak then
		flyMethodBtn.BackgroundColor3 = BTN_OPTION_HOVER
	end
end)
flyMethodBtn.MouseLeave:Connect(function()
	flyHov = false
	flyMethodBtn.BackgroundColor3 = isJailbreak and JB_BG_DEFAULT or BTN_OPTION_DEFAULT
end)
flyMethodBtn.MouseButton1Down:Connect(function()
	if not isJailbreak then
		flyMethodBtn.BackgroundColor3 = BTN_OPTION_DOWN
	end
end)
flyMethodBtn.MouseButton1Up:Connect(function()
	flyMethodBtn.BackgroundColor3 = isJailbreak and (flyHov and JB_BG_HOVER or JB_BG_DEFAULT)
		or (flyHov and BTN_OPTION_HOVER or BTN_OPTION_DEFAULT)
end)

moveMethodBtn.MouseEnter:Connect(function()
	moveHov = true
	local disabled = isJailbreak
	if not disabled then
		moveMethodBtn.BackgroundColor3 = BTN_OPTION_HOVER
	end
end)
moveMethodBtn.MouseLeave:Connect(function()
	moveHov = false
	updateFlyMoveAppearance()
end)
moveMethodBtn.MouseButton1Down:Connect(function()
	local disabled = isJailbreak
	if not disabled then
		moveMethodBtn.BackgroundColor3 = BTN_OPTION_DOWN
	end
end)
moveMethodBtn.MouseButton1Up:Connect(function()
	local disabled = isJailbreak
	if not disabled then
		moveMethodBtn.BackgroundColor3 = moveHov and BTN_OPTION_HOVER or BTN_OPTION_DEFAULT
	end
end)

skipBtn.MouseEnter:Connect(function()
	skipHov = true
	if skipBtn.BackgroundColor3 ~= BTN_DISABLED_BG then
		skipBtn.BackgroundColor3 = BTN_SKIP_HOVER
	end
end)
skipBtn.MouseLeave:Connect(function()
	skipHov = false
	if skipBtn.BackgroundColor3 ~= BTN_DISABLED_BG then
		skipBtn.BackgroundColor3 = BTN_SKIP_DEFAULT
	end
end)
skipBtn.MouseButton1Down:Connect(function()
	if skipBtn.BackgroundColor3 ~= BTN_DISABLED_BG then
		skipBtn.BackgroundColor3 = BTN_SKIP_DOWN
	end
end)
skipBtn.MouseButton1Up:Connect(function()
	if skipBtn.BackgroundColor3 ~= BTN_DISABLED_BG then
		skipBtn.BackgroundColor3 = skipHov and BTN_SKIP_HOVER or BTN_SKIP_DEFAULT
	end
end)

actionBtn.MouseButton1Click:Connect(function()
	if running then
		stopRequested = true
		StateMachine:transition(States.IDLE)
		restoreCamera()
		running = false
		setSkipBtnVisible(false)
		actionBtn.Text = "Start"
		actionBtn.BackgroundColor3 = BTN_ACTION_DEFAULT
		setProgress(0, "Idle")
	else
		task.spawn(runLoader)
	end
end)

strategyBtn.MouseButton1Click:Connect(function()
	if running then
		return
	end
	currentStrategy = currentStrategy == LoadStrategies.SLOW and LoadStrategies.FAST or LoadStrategies.SLOW
	strategyBtn.Text = "Strategy: " .. currentStrategy.name
end)

flyMethodBtn.MouseButton1Click:Connect(function()
	currentFlyMethod = currentFlyMethod == FlyMethods.CFLY and FlyMethods.SFLY or FlyMethods.CFLY
	updateFlyMoveAppearance()
end)

moveMethodBtn.MouseButton1Click:Connect(function()
	if running or isJailbreak then
		return
	end
	currentMoveMethod = currentMoveMethod == MoveMethods.TPPOS and MoveMethods.TWEENTPPOS or MoveMethods.TPPOS
	updateFlyMoveAppearance()
end)

skipBtn.MouseButton1Click:Connect(function()
	if not running or skipBtn.BackgroundColor3 == BTN_DISABLED_BG then
		return
	end
	skipPhase = true
	print("[MapLoader] Skip phase requested")
end)

close.MouseButton1Click:Connect(function()
	frame:Destroy()
end)

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		savedFramePos = frame.Position
		content.Visible = false
		frame.Size = UDim2.new(0, 220, 0, 36)
		frame.Position = UDim2.new(0, 10, 1, -46)
	else
		content.Visible = true
		frame.Size = UDim2.new(0, 369, 0, 36 + startTop + 40)
		frame.Position = savedFramePos or frame.Position
	end
end)

print(
	string.format(
		"[MapLoader] SE: %s | StreamRadius: %d | State: %s | Fly: %s | Move: %s",
		tostring(STREAMING_ENABLED),
		LIVE_STREAM_RADIUS,
		StateMachine.current,
		currentFlyMethod,
		currentMoveMethod
	)
)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local lp = Players.LocalPlayer

local SPIN_Y = 99999
local SPIN_XZ = 45000

local MAGNET_SPEED = 800
local CONTACT_RADIUS = 8
local CONTACT_TIME = 1.1
local STEP = 0.03

local IMPACT_SPIKE = 1200
local IMPACT_DECAY = 0.12

local MAX_VELOCITY = 900
local MAX_DISTANCE = 2500
local MAP_CENTER = Vector3.new(0, 20, 0)

local char, hum, hrp
local bav, linVel, linAttach

local function setupCharacter(c)
	char = c
	hum = c:WaitForChild("Humanoid")
	hrp = c:WaitForChild("HumanoidRootPart")

	for _, v in pairs(c:GetDescendants()) do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Massless = true
			v.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
		end
	end
end

local function startSpin()
	if bav then bav:Destroy() end

	bav = Instance.new("BodyAngularVelocity")
	bav.Parent = hrp
	bav.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
	bav.P = math.huge

	task.spawn(function()
		while hum.Health > 0 do
			bav.AngularVelocity = Vector3.new(
				math.random(-SPIN_XZ, SPIN_XZ),
				SPIN_Y,
				math.random(-SPIN_XZ, SPIN_XZ)
			)
			RunService.Heartbeat:Wait()
		end
	end)
end

local function buildMagnet()
	if linVel then linVel:Destroy() end

	linAttach = Instance.new("Attachment")
	linAttach.Parent = hrp

	linVel = Instance.new("LinearVelocity")
	linVel.Parent = hrp
	linVel.Attachment0 = linAttach
	linVel.MaxForce = math.huge
	linVel.RelativeTo = Enum.ActuatorRelativeTo.World
end

local function magnetize(thrp, speed)
	if not thrp or not thrp.Parent then return end
	local dir = thrp.Position - hrp.Position
	if dir.Magnitude < 1 then return end
	linVel.VectorVelocity = dir.Unit * speed
end

local function stopMagnet()
	if linVel then
		linVel.VectorVelocity = Vector3.zero
	end
end

local function clampVelocity()
	if hrp.Velocity.Magnitude > MAX_VELOCITY then
		hrp.Velocity = hrp.Velocity.Unit * MAX_VELOCITY
	end
end

local function targetValid(thrp)
	return thrp
		and thrp.Parent
		and (thrp.Position - hrp.Position).Magnitude < 2000
end

RunService.Heartbeat:Connect(function()
	if not hrp then return end

	if (hrp.Position - MAP_CENTER).Magnitude > MAX_DISTANCE then
		stopMagnet()
		hrp.Velocity = Vector3.zero
		hrp.CFrame = CFrame.new(MAP_CENTER)
	end

	clampVelocity()
end)

task.spawn(function()
	while true do
		if not hum or hum.Health <= 0 then
			task.wait(0.1)
			continue
        end

		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= lp and plr.Character then
				local thrp = plr.Character:FindFirstChild("HumanoidRootPart")
				local thum = plr.Character:FindFirstChildOfClass("Humanoid")
				if not (thrp and thum and thum.Health > 0) then continue end

				-- PHASE 1: CHASE
				while hum.Health > 0 and targetValid(thrp) do
					if (hrp.Position - thrp.Position).Magnitude <= CONTACT_RADIUS then
						break
					end
					magnetize(thrp, MAGNET_SPEED)
					task.wait(STEP)
				end

				if not targetValid(thrp) then
					stopMagnet()
					hrp.Velocity *= 0.25
					continue
				end

				-- FIRST-CONTACT IMPACT SPIKE
				local dir = (thrp.Position - hrp.Position).Unit
				hrp.Velocity = dir * IMPACT_SPIKE
				clampVelocity()
				task.wait(IMPACT_DECAY)

				-- PHASE 2: CONTACT DWELL
				local t0 = os.clock()
				while hum.Health > 0 and targetValid(thrp)
					and os.clock() - t0 < CONTACT_TIME do
					magnetize(thrp, MAGNET_SPEED)
					task.wait(STEP)
				end

				stopMagnet()
				hrp.Velocity *= 0.25
			end
		end

		task.wait(0.05)
	end
end)

setupCharacter(lp.Character or lp.CharacterAdded:Wait())
buildMagnet()
startSpin()

RunService.Stepped:Connect(function()
	if char then
		for _, v in pairs(char:GetChildren()) do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end
end)

lp.CharacterAdded:Connect(function(c)
	task.wait(0.1)
	setupCharacter(c)
	buildMagnet()
	startSpin()
end)
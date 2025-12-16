if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local HEIGHT_OFFSET = 180
local FAST_WAIT = 0.03
local SMOOTH_TWEEN = 0.18
local CHUNK_SIZE = 520
local PERIMETER_RADIUS = 420

local running = false
local stopRequested = false
local originalCFrame
local originalCameraType
local guiRef

local fps = 60
RunService.RenderStepped:Connect(function(dt)
	fps = 1 / math.max(dt, 1e-4)
end)

local function setRendering(on)
	RunService:Set3dRenderingEnabled(on)
end

local function formatETA(startTime, done, total)
	local elapsed = tick() - startTime
	local avg = elapsed / math.max(done, 1)
	local remaining = math.max(0, total - done)
	local eta = math.floor(avg * remaining)
	return string.format("%02d:%02d", math.floor(eta / 60), eta % 60)
end

local function collectParts()
	local parts = {}
	for _, inst in ipairs(Workspace:GetDescendants()) do
		if inst:IsA("BasePart")
			and inst.Transparency < 1
			and not inst:IsDescendantOf(player.Character or Instance.new("Folder")) then
			parts[#parts+1] = inst
		end
	end
	return parts
end

local function buildCenters(parts)
	local chunks = {}
	for _, p in ipairs(parts) do
		local cx = math.floor(p.Position.X / CHUNK_SIZE)
		local cy = math.floor(p.Position.Y / CHUNK_SIZE)
		local cz = math.floor(p.Position.Z / CHUNK_SIZE)
		local key = cx..","..cy..","..cz
		if not chunks[key] then
			chunks[key] = {sum = Vector3.zero, count = 0}
		end
		chunks[key].sum += p.Position
		chunks[key].count += 1
	end

	local centers = {}
	for _, c in pairs(chunks) do
		centers[#centers+1] = c.sum / c.count
	end
	return centers
end

local function tweenTo(pos)
	local tween = TweenService:Create(
		camera,
		TweenInfo.new(SMOOTH_TWEEN, Enum.EasingStyle.Linear),
		{CFrame = CFrame.new(pos)}
	)
	tween:Play()
	tween.Completed:Wait()
end

local function hardStop()
	stopRequested = true
	running = false
	setRendering(true)
	if originalCameraType then
		camera.CameraType = originalCameraType
	end
	if originalCFrame then
		camera.CFrame = originalCFrame
	end
	if guiRef then
		guiRef:Destroy()
	end
end

local function runLoader(status)
	status.Text = "Scanning map…"
	local parts = collectParts()
	if #parts == 0 then
		status.Text = "No geometry found"
		return
	end

	local centers = buildCenters(parts)
	local centerCount = #centers

	camera.CameraType = Enum.CameraType.Scriptable

	-- PHASE 1
	setRendering(false)
	local start1 = tick()

	for i, center in ipairs(centers) do
		if stopRequested then return end
		camera.CFrame = CFrame.new(center + Vector3.new(0, HEIGHT_OFFSET, 0))
		task.wait(FAST_WAIT)

		status.Text = string.format(
			"Phase 1 %d/%d | ETA %s | FPS %d",
			i, centerCount,
			formatETA(start1, i, centerCount),
			fps
		)
	end

	setRendering(true)

	-- PHASE 2
	local offsets = {
		Vector3.zero,
		Vector3.new(PERIMETER_RADIUS,0,0),
		Vector3.new(-PERIMETER_RADIUS,0,0),
		Vector3.new(0,0,PERIMETER_RADIUS),
		Vector3.new(0,0,-PERIMETER_RADIUS)
	}

	local totalSteps = centerCount * #offsets
	local step = 0
	local start2 = tick()

	for _, center in ipairs(centers) do
		for _, off in ipairs(offsets) do
			if stopRequested then return end
			step += 1
			tweenTo(center + off + Vector3.new(0, HEIGHT_OFFSET, 0))

			status.Text = string.format(
				"Phase 2 %d/%d | ETA %s | FPS %d",
				step, totalSteps,
				formatETA(start2, step, totalSteps),
				fps
			)
		end
	end
end

local function createGui()
	local gui = Instance.new("ScreenGui", player.PlayerGui)
	gui.Name = "SmoothMapLoader"
	gui.ResetOnSpawn = false
	guiRef = gui

	local frame = Instance.new("Frame", gui)
	frame.Size = UDim2.new(0, 360, 0, 200)
	frame.Position = UDim2.new(0.5, -180, 0.5, -100)
	frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
	frame.Active = true
	frame.Draggable = true

	local title = Instance.new("TextLabel", frame)
	title.Size = UDim2.new(1, -36, 0, 36)
	title.BackgroundColor3 = Color3.fromRGB(45,45,45)
	title.Text = "Map Loader"
	title.TextColor3 = Color3.new(1,1,1)
	title.Font = Enum.Font.SourceSansBold
	title.TextSize = 17

	local close = Instance.new("TextButton", frame)
	close.Size = UDim2.new(0, 36, 0, 36)
	close.Position = UDim2.new(1, -36, 0, 0)
	close.Text = "X"
	close.Font = Enum.Font.SourceSansBold
	close.TextSize = 18
	close.TextColor3 = Color3.new(1,1,1)
	close.BackgroundColor3 = Color3.fromRGB(140, 40, 40)

	close.MouseButton1Click:Connect(hardStop)

	local status = Instance.new("TextLabel", frame)
	status.Size = UDim2.new(1, -20, 0, 40)
	status.Position = UDim2.new(0,10,0,60)
	status.BackgroundTransparency = 1
	status.TextWrapped = true
	status.TextColor3 = Color3.new(1,1,1)
	status.Text = "Idle"

	local startBtn = Instance.new("TextButton", frame)
	startBtn.Size = UDim2.new(0.8,0,0,36)
	startBtn.Position = UDim2.new(0.1,0,0,120)
	startBtn.Text = "Start Full Load"
	startBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
	startBtn.TextColor3 = Color3.new(1,1,1)

	local stopBtn = Instance.new("TextButton", frame)
	stopBtn.Size = UDim2.new(0.8,0,0,34)
	stopBtn.Position = UDim2.new(0.1,0,0,160)
	stopBtn.Text = "Stop"
	stopBtn.Visible = false
	stopBtn.BackgroundColor3 = Color3.fromRGB(170,0,0)
	stopBtn.TextColor3 = Color3.new(1,1,1)

	startBtn.MouseButton1Click:Connect(function()
		if running then return end
		running = true
		stopRequested = false

		originalCFrame = camera.CFrame
		originalCameraType = camera.CameraType

		startBtn.Visible = false
		stopBtn.Visible = true

		runLoader(status)

		hardStop()
	end)

	stopBtn.MouseButton1Click:Connect(function()
		stopRequested = true
	end)
end

createGui()
game.StarterGui:SetCore("SendNotification", {Text="Successfully loaded!", Title="Map Loader"})
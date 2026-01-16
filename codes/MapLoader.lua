local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local CHUNK_SIZE   = 700
local HEIGHT_PAD   = 120

local FAST_WAIT   = 0.01
local SWEEP_TWEEN = 0.01
local SWEEP_WAIT  = 0.01

local running = false
local stopRequested = false
local minimized = false

local originalCFrame
local originalCameraType
local savedFramePos

local CURRENT_PHASE = 0
local TOTAL_PHASES = 2

-- UI refs
local gui, frame, content
local barBg, progressFill, progressText
local startBtn

local function setRendering(on)
	RunService:Set3dRenderingEnabled(on)
end

local function restoreCamera()
	setRendering(true)
	if originalCameraType then camera.CameraType = originalCameraType end
	if originalCFrame then camera.CFrame = originalCFrame end
end

local function formatETA(startTime, done, total)
	local elapsed = tick() - startTime
	local avg = elapsed / math.max(done, 1)
	local remain = math.max(0, total - done)
	local eta = math.floor(avg * remain)
	return string.format("%02d:%02d", math.floor(eta / 60), eta % 60)
end

local function phaseText(done, total, eta)
	return string.format(
		"Phase %d/%d | %d/%d | ETA %s",
		CURRENT_PHASE, TOTAL_PHASES, done, total, eta
	)
end

local function setProgress(alpha, text, active)
	progressFill.Size = UDim2.new(math.clamp(alpha,0,1),0,1,0)
	progressText.Text = text
	barBg.BackgroundColor3 = active
		and Color3.fromRGB(45,45,45)
		or Color3.fromRGB(60,60,60)
end

local function tweenTo(pos)
	local t = TweenService:Create(
		camera,
		TweenInfo.new(SWEEP_TWEEN, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.new(pos) }
	)
	t:Play()
	t.Completed:Wait()
	task.wait(SWEEP_WAIT)
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

local function buildChunks(parts)
	local chunks = {}

	for _, p in ipairs(parts) do
		local cx = math.floor(p.Position.X / CHUNK_SIZE)
		local cy = math.floor(p.Position.Y / CHUNK_SIZE)
		local cz = math.floor(p.Position.Z / CHUNK_SIZE)
		local key = cx..","..cy..","..cz

		local c = chunks[key]
		if not c then
			c = {
				min = p.Position,
				max = p.Position
			}
			chunks[key] = c
		else
			c.min = Vector3.new(
				math.min(c.min.X, p.Position.X),
				math.min(c.min.Y, p.Position.Y),
				math.min(c.min.Z, p.Position.Z)
			)
			c.max = Vector3.new(
				math.max(c.max.X, p.Position.X),
				math.max(c.max.Y, p.Position.Y),
				math.max(c.max.Z, p.Position.Z)
			)
		end
	end

	local list = {}
	for _, c in pairs(chunks) do
		list[#list+1] = c
	end
	return list
end

local function runLoader()
	running = true
	stopRequested = false

	originalCFrame = camera.CFrame
	originalCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	startBtn.Text = "Stop"
	startBtn.BackgroundColor3 = Color3.fromRGB(170,0,0)

	local parts = collectParts()
	if #parts == 0 then
		restoreCamera()
		running = false
		return
	end

	local chunks = buildChunks(parts)

	CURRENT_PHASE = 1
	setRendering(false)

	local startTime = tick()
	for i, c in ipairs(chunks) do
		if stopRequested then
			restoreCamera()
			running = false
			return
		end

		local min = c.min - Vector3.new(20,20,20)
		local max = c.max + Vector3.new(20,20,20)

		local points = {
			Vector3.new(min.X, max.Y, min.Z),
			Vector3.new(max.X, max.Y, min.Z),
			Vector3.new(max.X, max.Y, max.Z),
			Vector3.new(min.X, max.Y, max.Z),

			Vector3.new(min.X, min.Y, min.Z),
			Vector3.new(max.X, min.Y, min.Z),
			Vector3.new(max.X, min.Y, max.Z),
			Vector3.new(min.X, min.Y, max.Z),
		}

		for _, p in ipairs(points) do
			if stopRequested then break end
			camera.CFrame = CFrame.new(p + Vector3.new(0, HEIGHT_PAD, 0))
			task.wait(FAST_WAIT)
		end

		setProgress(
			i / #chunks,
			phaseText(i, #chunks, formatETA(startTime, i, #chunks)),
			true
		)
	end

	setRendering(true)

	CURRENT_PHASE = 2
	local start2 = tick()

	for i, c in ipairs(chunks) do
		if stopRequested then
			restoreCamera()
			running = false
			return
		end

		local center = (c.min + c.max) / 2
		tweenTo(center + Vector3.new(0, HEIGHT_PAD, 0))

		setProgress(
			i / #chunks,
			phaseText(i, #chunks, formatETA(start2, i, #chunks)),
			true
		)
	end

	restoreCamera()
	gui:Destroy()
end

gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "MapLoader"
gui.ResetOnSpawn = false

frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 160)
frame.Position = UDim2.new(0.5,-160,0.5,-80)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,32)
title.BackgroundTransparency = 1
title.Text = "MapLoader"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Center

local closeBtn = Instance.new("TextButton", frame)
closeBtn.Size = UDim2.new(0,32,0,32)
closeBtn.Position = UDim2.new(1,-32,0,0)
closeBtn.Text = "X"
closeBtn.BackgroundTransparency = 1
closeBtn.TextColor3 = Color3.new(1,0.3,0.3)
closeBtn.Font = Enum.Font.SourceSansBold

local minimize = Instance.new("TextButton", frame)
minimize.Size = UDim2.new(0,32,0,32)
minimize.Position = UDim2.new(1,-64,0,0)
minimize.Text = "-"
minimize.BackgroundTransparency = 1
minimize.TextColor3 = Color3.new(1,1,1)
minimize.Font = Enum.Font.SourceSansBold

content = Instance.new("Frame", frame)
content.Position = UDim2.new(0,0,0,32)
content.Size = UDim2.new(1,0,1,-32)
content.BackgroundTransparency = 1

barBg = Instance.new("Frame", content)
barBg.Size = UDim2.new(0.9,0,0,18)
barBg.Position = UDim2.new(0.05,0,0,20)
barBg.BackgroundColor3 = Color3.fromRGB(60,60,60)

progressFill = Instance.new("Frame", barBg)
progressFill.Size = UDim2.new(0,0,1,0)
progressFill.BackgroundColor3 = Color3.fromRGB(0,170,0)

progressText = Instance.new("TextLabel", barBg)
progressText.Size = UDim2.new(1,0,1,0)
progressText.BackgroundTransparency = 1
progressText.Text = "Idle"
progressText.Font = Enum.Font.SourceSansBold
progressText.TextSize = 14
progressText.TextColor3 = Color3.new(1,1,1)

startBtn = Instance.new("TextButton", content)
startBtn.Size = UDim2.new(0.8,0,0,32)
startBtn.Position = UDim2.new(0.1,0,0,60)
startBtn.Text = "Start"
startBtn.Font = Enum.Font.SourceSansBold
startBtn.TextSize = 16
startBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
startBtn.TextColor3 = Color3.new(1,1,1)

startBtn.MouseButton1Click:Connect(function()
	if running then
		stopRequested = true
		restoreCamera()
		running = false
		startBtn.Text = "Start"
		startBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
		setProgress(0,"Idle",false)
	else
		task.spawn(runLoader)
	end
end)

closeBtn.MouseButton1Click:Connect(function()
	stopRequested = true
	restoreCamera()
	gui:Destroy()
end)

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		savedFramePos = frame.Position
		content.Visible = false
		frame.Size = UDim2.new(0,220,0,32)
		frame.Position = UDim2.new(0,10,1,-42)
	else
		content.Visible = true
		frame.Size = UDim2.new(0,320,0,160)
		frame.Position = savedFramePos or frame.Position
	end
end)
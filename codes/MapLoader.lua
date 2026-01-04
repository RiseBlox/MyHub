local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local HEIGHT_OFFSET = 220
local CHUNK_SIZE = 700

local FAST_WAIT = 0.06
local SWEEP_TWEEN = 0.64
local SWEEP_WAIT = 0.1

local running = false
local stopRequested = false
local minimized = false

local originalCFrame
local originalCameraType
local savedFramePos

local CURRENT_PHASE = 0
local TOTAL_PHASES = 3

local gui, frame, content
local barBg, progressFill, progressText
local actionBtn

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
		CURRENT_PHASE,
		TOTAL_PHASES,
		done,
		total,
		eta
	)
end

local function setProgress(alpha, text, active)
	progressFill.Size = UDim2.new(math.clamp(alpha, 0, 1), 0, 1, 0)
	progressText.Text = text
	barBg.BackgroundColor3 = active
		and Color3.fromRGB(45,45,45)
		or Color3.fromRGB(60,60,60)
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
	local buckets = {}
	for _, p in ipairs(parts) do
		local cx = math.floor(p.Position.X / CHUNK_SIZE)
		local cy = math.floor(p.Position.Y / CHUNK_SIZE)
		local cz = math.floor(p.Position.Z / CHUNK_SIZE)
		local key = cx..","..cy..","..cz
		if not buckets[key] then
			buckets[key] = { sum = Vector3.zero, count = 0 }
		end
		buckets[key].sum += p.Position
		buckets[key].count += 1
	end

	local centers = {}
	for _, b in pairs(buckets) do
		centers[#centers+1] = b.sum / b.count
	end
	return centers
end

local function buildColumns(centers)
	local minX = math.huge
	for _, c in ipairs(centers) do
		minX = math.min(minX, c.X)
	end

	local columns = {}
	for _, c in ipairs(centers) do
		local col = math.floor((c.X - minX) / CHUNK_SIZE)
		columns[col] = columns[col] or {}
		table.insert(columns[col], c)
	end
	return columns
end

local function tweenTo(pos)
	local tween = TweenService:Create(
		camera,
		TweenInfo.new(SWEEP_TWEEN, Enum.EasingStyle.Linear),
		{ CFrame = CFrame.new(pos) }
	)
	tween:Play()
	tween.Completed:Wait()
	task.wait(SWEEP_WAIT)
end

local function runLoader()
	running = true
	stopRequested = false

	originalCFrame = camera.CFrame
	originalCameraType = camera.CameraType
	camera.CameraType = Enum.CameraType.Scriptable

	actionBtn.Text = "Stop"
	actionBtn.BackgroundColor3 = Color3.fromRGB(170,0,0)

	local parts = collectParts()
	if #parts == 0 then
		restoreCamera()
		running = false
		return
	end

	local centers = buildCenters(parts)
	local columns = buildColumns(centers)

	CURRENT_PHASE = 1
	setRendering(false)

	local p1start = tick()
	local done = 0

	for _, c in ipairs(centers) do
		if stopRequested then
			CURRENT_PHASE = 0
			restoreCamera()
			running = false
			return
		end
		done += 1
		camera.CFrame = CFrame.new(c + Vector3.new(0, HEIGHT_OFFSET, 0))
		task.wait(FAST_WAIT)

		setProgress(
			done / #centers,
			phaseText(done, #centers, formatETA(p1start, done, #centers)),
			true
		)
	end

	setRendering(true)

	CURRENT_PHASE = 2

	local p2total = 0
	for _, col in pairs(columns) do p2total += #col end
	local p2done = 0
	local p2start = tick()

	for col = 0, math.huge do
		local list = columns[col]
		if not list then break end

		table.sort(list, function(a, b)
			return a.Z > b.Z
		end)

		for _, c in ipairs(list) do
			if stopRequested then
				CURRENT_PHASE = 0
				restoreCamera()
				running = false
				return
			end
			p2done += 1
			tweenTo(c + Vector3.new(0, HEIGHT_OFFSET, 0))

			setProgress(
				p2done / p2total,
				phaseText(p2done, p2total, formatETA(p2start, p2done, p2total)),
				true
			)
		end
	end

	CURRENT_PHASE = 3

	local p3done = 0
	local p3start = tick()

	for col = 0, math.huge do
		local list = columns[col]
		if not list then break end

		table.sort(list, function(a, b)
			return a.Y > b.Y
		end)

		for _, c in ipairs(list) do
			if stopRequested then
				CURRENT_PHASE = 0
				restoreCamera()
				running = false
				return
			end
			p3done += 1
			tweenTo(c + Vector3.new(0, HEIGHT_OFFSET, 0))

			setProgress(
				p3done / p2total,
				phaseText(p3done, p2total, formatETA(p3start, p3done, p2total)),
				true
			)
		end
	end

	restoreCamera()
	gui:Destroy()
end

gui = Instance.new("ScreenGui", player.PlayerGui)
gui.Name = "MapLoader"
gui.ResetOnSpawn = false

frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 300, 0, 150)
frame.Position = UDim2.new(0.5, -150, 0.5, -75)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 32)
title.BackgroundTransparency = 1
title.Text = "MapLoader"
title.Font = Enum.Font.SourceSansBold
title.TextSize = 16
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Center

local minimize = Instance.new("TextButton", frame)
minimize.Size = UDim2.new(0, 32, 0, 32)
minimize.Position = UDim2.new(1, -32, 0, 0)
minimize.Text = "-"
minimize.Font = Enum.Font.SourceSansBold
minimize.TextSize = 24
minimize.TextColor3 = Color3.new(1,1,1)
minimize.BackgroundTransparency = 1

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

actionBtn = Instance.new("TextButton", content)
actionBtn.Size = UDim2.new(0.8,0,0,32)
actionBtn.Position = UDim2.new(0.1,0,0,60)
actionBtn.Text = "Start"
actionBtn.Font = Enum.Font.SourceSansBold
actionBtn.TextSize = 16
actionBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
actionBtn.TextColor3 = Color3.new(1,1,1)

actionBtn.MouseButton1Click:Connect(function()
	if running then
		stopRequested = true
		CURRENT_PHASE = 0
		restoreCamera()
		running = false
		actionBtn.Text = "Start"
		actionBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
		setProgress(0, "Idle", false)
	else
		task.spawn(runLoader)
	end
end)

minimize.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		savedFramePos = frame.Position
		content.Visible = false
		frame.Size = UDim2.new(0, 220, 0, 32)
		frame.Position = UDim2.new(0, 10, 1, -42)
	else
		content.Visible = true
		frame.Size = UDim2.new(0, 300, 0, 150)
		frame.Position = savedFramePos or frame.Position
	end
end)
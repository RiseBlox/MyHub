if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local HEIGHT_OFFSET = 220
local FAST_WAIT = 0.02
local SMOOTH_TWEEN = 0.22
local POST_TWEEN_WAIT = 0.03
local CHUNK_SIZE = 700
local PERIMETER_RADIUS = 750

local running = false
local stopRequested = false
local minimized = false
local originalCFrame
local originalCameraType

local gui
local frame
local content
local progressFill
local progressText
local barBg
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
	local remaining = math.max(0, total - done)
	local eta = math.floor(avg * remaining)
	return string.format("%02d:%02d", math.floor(eta / 60), eta % 60)
end

local function setProgress(alpha, text, active)
	progressFill.Size = UDim2.new(math.clamp(alpha, 0, 1), 0, 1, 0)
	progressText.Text = text or ""
	barBg.BackgroundColor3 = active
		and Color3.fromRGB(45,45,45)
		or Color3.fromRGB(55,55,55)
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
	task.wait(POST_TWEEN_WAIT)
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

	-- PHASE 1
	setRendering(false)
	local start1 = tick()

	for i, center in ipairs(centers) do
		if stopRequested then
			restoreCamera()
			running = false
			return
		end

		camera.CFrame = CFrame.new(center + Vector3.new(0, HEIGHT_OFFSET, 0))
		task.wait(FAST_WAIT)

		setProgress(
			i / #centers,
			string.format("%d/%d | ETA %s", i, #centers, formatETA(start1, i, #centers)),
			true
		)
	end

	setRendering(true)

	-- PHASE 2
	local r = PERIMETER_RADIUS
	local offsets = {
		Vector3.zero,
		Vector3.new( r,0,0), Vector3.new(-r,0,0),
		Vector3.new(0,0, r), Vector3.new(0,0,-r),
		Vector3.new( r,0, r), Vector3.new(-r,0, r),
		Vector3.new( r,0,-r), Vector3.new(-r,0,-r)
	}

	local total = #centers * #offsets
	local step = 0
	local start2 = tick()

	for _, center in ipairs(centers) do
		for _, off in ipairs(offsets) do
			if stopRequested then
				restoreCamera()
				running = false
				return
			end

			step += 1
			tweenTo(center + off + Vector3.new(0, HEIGHT_OFFSET, 0))

			setProgress(
				step / total,
				string.format("%d/%d | ETA %s", step, total, formatETA(start2, step, total)),
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
barBg.BackgroundColor3 = Color3.fromRGB(55,55,55)

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
	content.Visible = not minimized

	if minimized then
		frame.Active = false
		frame.Draggable = false
		frame.Size = UDim2.new(0, 220, 0, 32)
		frame.Position = UDim2.new(0, 10, 1, -42)
	else
		frame.Active = true
		frame.Draggable = true
		frame.Size = UDim2.new(0, 300, 0, 150)
		frame.Position = UDim2.new(0.5, -150, 0.5, -75)
	end
end)

game.StarterGui:SetCore("SendNotification", {Text="Successfully loaded!", Title="Map Loader"})
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local humanoid
local speedBtn

local speedEnabled = false

local function ToggleSpeed()
    speedEnabled = not speedEnabled
    local btnColor = speedEnabled and "#993d3d" or "#57993d"

    if humanoid then
        humanoid.WalkSpeed = speedEnabled and 100 or 24
    end

    if speedBtn then
        speedBtn.Text = speedEnabled and "Disable SUPERSPEED [X]" or "Enable SUPERSPEED [X]"
        speedBtn.BackgroundColor3 = Color3.fromHex(btnColor)
    end
end

local function bindCharacter(char)
    humanoid = char:WaitForChild("Humanoid", 5)

    if humanoid then
        humanoid.WalkSpeed = speedEnabled and 100 or 24
    end
end

if player.Character then
    bindCharacter(player.Character)
end
player.CharacterAdded:Connect(bindCharacter)

RunService.Heartbeat:Connect(function()
    if not speedEnabled then
        return
    end

    if not humanoid or not humanoid.Parent then
        return
    end

    humanoid.WalkSpeed = 100
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.X then
        ToggleSpeed()
    end
end)

pcall(function()
    player:WaitForChild("PlayerGui"):FindFirstChild("SUPERSPEED"):Destroy()
end)

local gui = Instance.new("ScreenGui")
gui.Name = "SUPERSPEED"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99999
gui.Parent = player:WaitForChild("PlayerGui")

frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 181, 0, 47)
frame.Position = UDim2.new(0, 20, 0.45, 0)
frame.BackgroundColor3 = Color3.fromHex("#151618")
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true

local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 1
stroke.Color = Color3.new(32, 32, 32)
stroke.Transparency = 0.75

speedBtn = Instance.new("TextButton", frame)
speedBtn.Size = UDim2.fromOffset(165, 32)
speedBtn.Position = UDim2.new(0, 8.5, 0.15, 0)
speedBtn.BackgroundColor3 = Color3.fromHex("#57993d")
speedBtn.Text = "Enable SUPERSPEED [X]"
speedBtn.TextColor3 = Color3.new(1, 1, 1)
speedBtn.Font = Enum.Font.BuilderSansBold
speedBtn.TextSize = 13.5
speedBtn.BorderSizePixel = 0

speedBtn.MouseButton1Click:Connect(ToggleSpeed)

local infJumpDebounce = false
UserInputService.JumpRequest:Connect(function()
    if humanoid and humanoid.Parent and not infJumpDebounce then
        infJumpDebounce = true
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        task.wait()
        infJumpDebounce = false
    end
end)

pcall(function()
    local CircleAction = require(ReplicatedStorage.Module.UI).CircleAction
    for _, spec in pairs(CircleAction.Specs) do
        if spec.Timed ~= nil then
            spec.Timed = false
        end
    end
end)

for _, v in next, getgc(true) do
    if type(v) == "table" then
        if rawget(v, "useEvery") then v.useEvery = 0 end
        if rawget(v, "_budgetPerWindow") then
            v._budgetPerWindow = math.huge
            v._budgetWindowDuration = math.huge
        end
    end
end

for _, v in next, getgc(true) do
    if typeof(v) == "function" then
        local env = getfenv(v)
        if env and tostring(env.script):lower():find("barbedwire") then
            pcall(hookfunction, v, function() return end)
        end
    end
end

for _, v in next, getgc(true) do
    if type(v) == "table" and rawget(v, "Name") and v.Name == "Explosion" then
        v.Name = "DisabledExplosion"
    end
end

require(ReplicatedStorage.Game.Paraglide).IsFlying = function()
    return tostring(getfenv(2).script) == "Falling"
end

ReplicatedStorage:SetAttribute("RollingEnabled",true)
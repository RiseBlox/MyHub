local SPEED = 100
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local humanoid

local function bind(char)
    humanoid = char:WaitForChild("Humanoid", 5)
end

if player.Character then
    bind(player.Character)
end
player.CharacterAdded:Connect(bind)

RunService.RenderStepped:Connect(function()
    if humanoid then
        humanoid.WalkSpeed = SPEED
    end
end)

local Doors = {}
local OpenDoorFunc
local TimeTable

for _, v in pairs(getgc(true)) do
    if typeof(v) == "table" then
        if rawget(v, "Cell") and rawget(v, "Stunned") then
            TimeTable = v
        end
        if rawget(v, "State") and rawget(v, "OpenFun") then
            table.insert(Doors, v)
        end
    elseif typeof(v) == "function" then
        local env = getfenv(v)
        if env and env.script == game:GetService("Players").LocalPlayer.PlayerScripts.LocalScript then
            local c = getconstants(v)
            if table.find(c, "SequenceRequireState") then
                OpenDoorFunc = v
            end
        end
    end
end

if TimeTable then
    TimeTable.Cell = 0
    TimeTable.Stunned = 0
end

task.spawn(function()
    while true do
        if OpenDoorFunc then
            for _, door in ipairs(Doors) do
                pcall(OpenDoorFunc, door)
            end
        end
        task.wait(2)
    end
end)

require(game:GetService("ReplicatedStorage").Game.Paraglide).IsFlying = false
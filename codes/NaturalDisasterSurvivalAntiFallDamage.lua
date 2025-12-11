local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local antiFallEnabled = true
local antiFallConnection = nil
local characterAddedConnection = nil

local function Message(_Title, _Text, Time)
    StarterGui:SetCore("SendNotification", {
        Title = _Title,
        Text = _Text,
        Duration = Time
    })
end

if antiFallEnabled then
    if game.PlaceId ~= 189707 then
        Message("Error", "Wrong game!", 5)
        antiFallEnabled = false
        return
    end

    local lp = Player
    local hb = RunService.Heartbeat
    local rsd = RunService.RenderStepped
    local zero = Vector3.zero

    local function protect(char)
        local root = char:WaitForChild("HumanoidRootPart")
        if root then
            local con
            con = hb:Connect(function()
                if not antiFallEnabled or not root.Parent then
                    con:Disconnect()
                    return
                end
                local vel = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = zero
                rsd:Wait()
                root.AssemblyLinearVelocity = vel
            end)
            antiFallConnection = con
        end
    end

    protect(lp.Character)
    characterAddedConnection = lp.CharacterAdded:Connect(protect)
end

Message("Anti Fall Damage", "Enabled!", 5)
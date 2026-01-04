local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ItemConfig = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ItemConfig")

local function applyGunMods()
    for _, module in ipairs(ItemConfig:GetChildren()) do
        if module:IsA("ModuleScript") then
            local ok, gun = pcall(require, module)
            if ok and typeof(gun) == "table" then

                if rawget(gun, "FireFreq") ~= nil then
                    gun.FireFreq = 10
                end

                if rawget(gun, "FireAuto") ~= nil then
                    gun.FireAuto = true
                end

                if rawget(gun, "CamShakeMagnitude") ~= nil then
                    gun.CamShakeMagnitude = 0
                end

                if rawget(gun, "BulletSpread") ~= nil then
                    gun.BulletSpread = 0
                end

                --[[
                if rawget(gun, "ReloadTime") ~= nil then
                    gun.ReloadTime = 0.5
                end
                --]]
            end
        end
    end
end

applyGunMods()

player.CharacterAdded:Connect(function()
    task.wait(1)
    applyGunMods()
end)
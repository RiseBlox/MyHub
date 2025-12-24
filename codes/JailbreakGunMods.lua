local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemConfig = ReplicatedStorage:WaitForChild("Game"):WaitForChild("ItemConfig")

for _, module in ipairs(ItemConfig:GetChildren()) do
    if module:IsA("ModuleScript") then
        pcall(function()
            local gun = require(module)

            if rawget(gun, "FireFreq") ~= nil then
                gun.FireFreq = math.huge
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

            if rawget(gun, "ReloadTime") ~= nil then
                gun.ReloadTime = 0
            end
        end)
    end
end
task.spawn(function()
    while true do
        for _, v in pairs(getgc(true)) do
            if typeof(v) == "table" then
                -- Infinite Nitro
                if rawget(v, "Nitro") then
                    v.Nitro = math.huge
                end

                -- Anti Tire Pop
                if rawget(v, "TirePopDuration") then
                    v.TirePopDuration = 0
                end
            end
        end
        task.wait(0.5) -- re-apply to survive game-side overwrites
    end
end)

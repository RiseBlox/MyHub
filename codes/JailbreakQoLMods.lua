local Doors = {}
local OpenDoorFunc = nil
local TimeTable = nil

-- Initial GC scan
for _, v in pairs(getgc(true)) do
    if typeof(v) == "table" then
        -- Time table (Cell / Stunned)
        if rawget(v, "Cell") and rawget(v, "Stunned") then
            TimeTable = v
        end

        -- Door tables
        if rawget(v, "State") and rawget(v, "OpenFun") then
            table.insert(Doors, v)
        end
    elseif typeof(v) == "function" then
        local env = getfenv(v)
        if env and env.script == game:GetService("Players").LocalPlayer.PlayerScripts.LocalScript then
            local consts = getconstants(v)
            if table.find(consts, "SequenceRequireState") then
                OpenDoorFunc = v
            end
        end
    end
end

-- Enforcement loop
task.spawn(function()
    while true do
        -- No cell time / no tazer
        if TimeTable then
            TimeTable.Cell = 0
            TimeTable.Stunned = 0
        end

        -- Open all doors
        if OpenDoorFunc then
            for _, door in pairs(Doors) do
                pcall(function()
                    OpenDoorFunc(door)
                end)
            end
        end

        task.wait(1)
    end
end)

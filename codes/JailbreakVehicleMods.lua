local NitroTables = {}
local TireTables = {}

for _, v in pairs(getgc(true)) do
    if typeof(v) == "table" then
        if rawget(v, "Nitro") then
            table.insert(NitroTables, v)
        end
        if rawget(v, "TirePopDuration") then
            table.insert(TireTables, v)
        end
    end
end

for _, v in ipairs(NitroTables) do
    v.Nitro = math.huge
end
for _, v in ipairs(TireTables) do
    v.TirePopDuration = 0
end

task.spawn(function()
    while true do
        for _, v in ipairs(NitroTables) do
            if v.Nitro ~= math.huge then
                v.Nitro = math.huge
            end
        end
        for _, v in ipairs(TireTables) do
            if v.TirePopDuration ~= 0 then
                v.TirePopDuration = 0
            end
        end
        task.wait(0)
    end
end)
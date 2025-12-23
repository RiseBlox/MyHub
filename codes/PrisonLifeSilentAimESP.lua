local plrs = game:GetService("Players")
local me = plrs.LocalPlayer
local rs = game:GetService("RunService")
local uis = game:GetService("UserInputService")
local rep = game:GetService("ReplicatedStorage")
local startergui = game:GetService("StarterGui")
local ts = game:GetService("TweenService")
local coregui = game:GetService("CoreGui")
local guiservice = game:GetService("GuiService")
local teams = game:GetService("Teams")

local cfg = {
    enabled = true,
    teamcheck = true,
    wallcheck = true,
    deathcheck = true,
    ffcheck = true,
    hostilecheck = true,
    trespasscheck = true,
    vehiclecheck = false,
    taserbypasshostile = true,
    taserbypasstrespass = true,
    taseralwayshit = true,
    ifplayerstill = true,
    stillthreshold = 0.5,
    hitchance = 100,
    missspread = 0,
    shotgunnaturalspread = false,
    prioritizeclosest = true,
    targetstickiness = false,
    targetstickinessduration = 0,
    targetstickinessrandom = false,
    targetstickinessmin = 0,
    targetstickinessmax = 0,
    fov = 100,
    showfov = true,
    showtargetline = false,
    aimpart = "Head",
    randomparts = false,
    partslist = {"Torso", "HumanoidRootPart", "LeftArm", "RightArm"},
    esp = true,
    espteamcheck = true,
    espshowteam = false,
    esptargets = {guards = true, inmates = true, criminals = true},
    espmaxdist = 9999,
    espshowdist = true,
    espcolor = Color3.fromRGB(0, 170, 255),
    espguards = Color3.fromRGB(0, 170, 255),
    espinmates = Color3.fromRGB(255, 150, 50),
    espcriminals = Color3.fromRGB(255, 60, 60),
    espteam = Color3.fromRGB(60, 255, 60),
    espuseteamcolors = true
}

local guardsteam = teams:FindFirstChild("Guards")
local inmatesteam = teams:FindFirstChild("Inmates")
local crimsteam = teams:FindFirstChild("Criminals")

local wallparams = RaycastParams.new()
wallparams.FilterType = Enum.RaycastFilterType.Exclude
wallparams.IgnoreWater = true
wallparams.RespectCanCollide = false
wallparams.CollisionGroup = "ClientBullet"

local currentgun = nil
local rng = Random.new()
local lastshottime = 0
local lastshotresult = false
local shotcooldown = 0.15
local currenttarget = nil
local targetswitchtime = 0
local currentstickiness = 0

local fovcircle = Drawing.new("Circle")
fovcircle.Color = Color3.fromRGB(255, 0, 0)
fovcircle.Radius = cfg.fov
fovcircle.Transparency = 0.8
fovcircle.Filled = false
fovcircle.NumSides = 64
fovcircle.Thickness = 1
fovcircle.Visible = cfg.showfov and cfg.enabled

local targetline = Drawing.new("Line")
targetline.Color = Color3.fromRGB(0, 255, 0)
targetline.Thickness = 1
targetline.Transparency = 0.5
targetline.Visible = false

local visuals = {container = nil}
local espcache = {}

local function makevisuals()
    local container
    if gethui then
        container = gethui()
    elseif syn and syn.protect_gui then
        local folder = Instance.new("Folder")
        folder.Name = "SilentAimESP"
        syn.protect_gui(folder)
        folder.Parent = coregui
        container = folder
    else
        container = coregui
    end

    visuals.container = container
end

local function makeesp(plr)
    if espcache[plr] then return espcache[plr] end

    local esp = Instance.new("BillboardGui")
    esp.Name = "ESP_" .. plr.Name
    esp.AlwaysOnTop = true
    esp.Size = UDim2.new(0, 20, 0, 20)
    esp.StudsOffset = Vector3.new(0, 3, 0)
    esp.LightInfluence = 0

    local diamond = Instance.new("Frame")
    diamond.Name = "Diamond"
    diamond.BackgroundColor3 = cfg.espcolor
    diamond.BorderSizePixel = 0
    diamond.Size = UDim2.new(0, 5, 0, 5)
    diamond.Position = UDim2.new(0.5, -5, 0.5, -5)
    diamond.Rotation = 45
    diamond.Parent = esp

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.new(0, 0, 0)
    stroke.Thickness = 1
    stroke.Transparency = 0
    stroke.Parent = diamond

    local dist = Instance.new("TextLabel")
    dist.Name = "DistanceLabel"
    dist.BackgroundTransparency = 1
    dist.Size = UDim2.new(0, 60, 0, 16)
    dist.Position = UDim2.new(0.5, -30, 1, 2)
    dist.Font = Enum.Font.GothamBold
    dist.TextSize = 11
    dist.TextColor3 = Color3.new(1, 1, 1)
    dist.TextStrokeTransparency = 0.5
    dist.TextStrokeColor3 = Color3.new(0, 0, 0)
    dist.Text = ""
    dist.Parent = esp

    local namelbl = Instance.new("TextLabel")
    namelbl.Name = "NameLabel"
    namelbl.BackgroundTransparency = 1
    namelbl.Size = UDim2.new(0, 100, 0, 14)
    namelbl.Position = UDim2.new(0.5, -50, 0, -16)
    namelbl.Font = Enum.Font.GothamBold
    namelbl.TextSize = 10
    namelbl.TextColor3 = Color3.new(1, 1, 1)
    namelbl.TextStrokeTransparency = 0.5
    namelbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    namelbl.Text = plr.Name
    namelbl.Parent = esp

    espcache[plr] = esp
    return esp
end

local function removeesp(plr)
    local e = espcache[plr]
    if e then e:Destroy() espcache[plr] = nil end
end

local function shouldshowesp(plr)
    if not plr or plr == me or not plr.Character then return false end

    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local mychar = me.Character
    if not mychar then return false end
    local myhrp = mychar:FindFirstChild("HumanoidRootPart")
    if not myhrp then return false end

    local dist = (hrp.Position - myhrp.Position).Magnitude
    if dist > cfg.espmaxdist then return false end

    local myteam = me.Team
    local theirteam = plr.Team

    if theirteam == myteam then
        if not cfg.espshowteam then return false end
        return true
    end

    if cfg.espteamcheck then
        local imcrimorinmate = (myteam == crimsteam or myteam == inmatesteam)
        local theycrimorinmate = (theirteam == crimsteam or theirteam == inmatesteam)
        if imcrimorinmate and theycrimorinmate then return false end
    end

    if theirteam == guardsteam then return cfg.esptargets.guards
    elseif theirteam == inmatesteam then return cfg.esptargets.inmates
    elseif theirteam == crimsteam then return cfg.esptargets.criminals end

    return false
end

local function updateesp()
    if not cfg.esp or not visuals.container then
        for _, e in pairs(espcache) do e.Parent = nil end
        return
    end

    local mychar = me.Character
    local myhrp = mychar and mychar:FindFirstChild("HumanoidRootPart")

    for _, plr in ipairs(plrs:GetPlayers()) do
        local show = shouldshowesp(plr)

        if show then
            local char = plr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")

            if hrp and head then
                local esp = makeesp(plr)
                esp.Adornee = head
                esp.Parent = visuals.container

                local d = esp:FindFirstChild("Diamond")
                if d and cfg.espuseteamcolors then
                    local t = plr.Team
                    if t == me.Team then d.BackgroundColor3 = cfg.espteam
                    elseif t == guardsteam then d.BackgroundColor3 = cfg.espguards
                    elseif t == inmatesteam then d.BackgroundColor3 = cfg.espinmates
                    elseif t == crimsteam then d.BackgroundColor3 = cfg.espcriminals
                    else d.BackgroundColor3 = cfg.espcolor end
                end

                if cfg.espshowdist and myhrp then
                    local distlbl = esp:FindFirstChild("DistanceLabel")
                    if distlbl then
                        distlbl.Text = math.floor((hrp.Position - myhrp.Position).Magnitude) .. "m"
                        distlbl.Visible = true
                    end
                end
            end
        else
            local e = espcache[plr]
            if e then e.Parent = nil end
        end
    end
end

makevisuals()

local partmap = {
    ["Torso"] = {"Torso", "UpperTorso", "LowerTorso"},
    ["LeftArm"] = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    ["RightArm"] = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    ["LeftLeg"] = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    ["RightLeg"] = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
}

local function getpart(char, name)
    if not char then return nil end

    local p = char:FindFirstChild(name)
    if p then return p end

    local maps = partmap[name]
    if maps then
        for _, n in ipairs(maps) do
            local part = char:FindFirstChild(n)
            if part then return part end
        end
    end

    return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
end

local function gettargetpart(char)
    if not char then return nil end

    local partname
    if cfg.randomparts then
        local list = cfg.partslist
        partname = (list and #list > 0) and list[rng:NextInteger(1, #list)] or "Head"
    else
        partname = cfg.aimpart
    end

    return getpart(char, partname)
end

local function isdead(plr)
    if not plr or not plr.Character then return true end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    return not hum or hum.Health <= 0
end

local function isstanding(plr)
    if not plr or not plr.Character then return false end
    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local vel = hrp.AssemblyLinearVelocity
    return Vector2.new(vel.X, vel.Z).Magnitude <= cfg.stillthreshold
end

local function hasff(plr)
    if not plr or not plr.Character then return false end
    return plr.Character:FindFirstChildOfClass("ForceField") ~= nil
end

local function isinvehicle(plr)
    if not plr or not plr.Character then return false end
    local hum = plr.Character:FindFirstChildOfClass("Humanoid")
    if not hum then return false end
    local seat = hum.SeatPart
    return seat ~= nil
end

local function wallbetween(startpos, endpos, targetchar)
    local mychar = me.Character
    if not mychar then return true end

    local filter = {mychar}
    if targetchar then table.insert(filter, targetchar) end
    wallparams.FilterDescendantsInstances = filter

    local dir = endpos - startpos
    local dist = dir.Magnitude
    local unit = dir.Unit

    local curstart = startpos
    local remaining = dist

    for _ = 1, 10 do
        local result = workspace:Raycast(curstart, unit * remaining, wallparams)
        if not result then return false end

        local hit = result.Instance
        if hit.Transparency < 0.8 and hit.CanCollide then return true end

        local hitdist = (result.Position - curstart).Magnitude
        remaining = remaining - hitdist - 0.01
        if remaining <= 0 then return false end

        curstart = result.Position + unit * 0.01
    end

    return false
end

local function quickcheck(plr)
    if not plr or plr == me or not plr.Character then return false end
    if not gettargetpart(plr.Character) then return false end
    if cfg.deathcheck and isdead(plr) then return false end
    if cfg.ffcheck and hasff(plr) then return false end
    if cfg.vehiclecheck and isinvehicle(plr) then return false end
    if cfg.teamcheck and plr.Team == me.Team then return false end

    if cfg.hostilecheck or cfg.trespasscheck then
        local istaser = currentgun and currentgun:GetAttribute("Projectile") == "Taser"
        local bypasshostile = cfg.taserbypasshostile and istaser
        local bypasstrespass = cfg.taserbypasstrespass and istaser
        local tchar = plr.Character

        if me.Team == guardsteam and plr.Team == inmatesteam then
            local hostile = tchar:GetAttribute("Hostile")
            local trespass = tchar:GetAttribute("Trespassing")

            if cfg.hostilecheck and cfg.trespasscheck then
                if not bypasshostile and not bypasstrespass then
                    if not hostile and not trespass then return false end
                end
            elseif cfg.hostilecheck and not bypasshostile then
                if not hostile then return false end
            elseif cfg.trespasscheck and not bypasstrespass then
                if not trespass then return false end
            end
        end
    end

    return true
end

local function fullcheck(plr)
    if not quickcheck(plr) then return false end

    if cfg.wallcheck then
        local mychar = me.Character
        local myhead = mychar and mychar:FindFirstChild("Head")
        local targetpart = gettargetpart(plr.Character)
        if myhead and targetpart then
            if wallbetween(myhead.Position, targetpart.Position, plr.Character) then
                return false
            end
        end
    end

    return true
end

local function rollhit()
    local now = os.clock()
    if now - lastshottime > shotcooldown then
        lastshottime = now
        local c = cfg.hitchance
        if c >= 100 then
            lastshotresult = true
        elseif c <= 0 then
            lastshotresult = false
        else
            lastshotresult = rng:NextInteger(1, 100) <= c
        end
    end
    return lastshotresult
end

local function getmisspos(targetpos)
    local spread = cfg.missspread
    local angle = rng:NextNumber() * math.pi * 2
    local d = rng:NextNumber() * spread
    local yoff = (rng:NextNumber() - 0.5) * spread
    return targetpos + Vector3.new(math.cos(angle) * d, yoff, math.sin(angle) * d)
end

local function getclosest(fovrad)
    fovrad = fovrad or cfg.fov
    local cam = workspace.CurrentCamera
    if not cam then return nil, nil end

    local lastinput = uis:GetLastInputType()
    local locked = (lastinput == Enum.UserInputType.Touch) or (uis.MouseBehavior == Enum.MouseBehavior.LockCenter)

    local aimpos
    if locked then
        local vs = cam.ViewportSize
        aimpos = Vector2.new(vs.X / 2, vs.Y / 2)
    else
        aimpos = uis:GetMouseLocation()
    end

    local now = os.clock()

    if cfg.targetstickiness and currenttarget and (now - targetswitchtime) < currentstickiness then
        if fullcheck(currenttarget) then
            local part = gettargetpart(currenttarget.Character)
            if part then
                local sp, onscreen = cam:WorldToViewportPoint(part.Position)
                if onscreen and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - aimpos).Magnitude
                    if d < fovrad then
                        return currenttarget, part.Position
                    end
                end
            end
        end
    end

    local candidates = {}

    for _, plr in ipairs(plrs:GetPlayers()) do
        if quickcheck(plr) then
            local part = gettargetpart(plr.Character)
            if part then
                local sp, onscreen = cam:WorldToViewportPoint(part.Position)
                if onscreen and sp.Z > 0 then
                    local d = (Vector2.new(sp.X, sp.Y) - aimpos).Magnitude
                    if d < fovrad then
                        table.insert(candidates, {plr = plr, dist = d, part = part})
                    end
                end
            end
        end
    end

    if cfg.prioritizeclosest then
        table.sort(candidates, function(a, b) return a.dist < b.dist end)
    else
        for i = #candidates, 2, -1 do
            local j = rng:NextInteger(1, i)
            candidates[i], candidates[j] = candidates[j], candidates[i]
        end
    end

    for _, c in ipairs(candidates) do
        if fullcheck(c.plr) then
            if c.plr ~= currenttarget then
                currenttarget = c.plr
                targetswitchtime = now
                if cfg.targetstickinessrandom then
                    currentstickiness = rng:NextNumber(cfg.targetstickinessmin, cfg.targetstickinessmax)
                else
                    currentstickiness = cfg.targetstickinessduration
                end
            end
            return c.plr, c.part.Position
        end
    end

    currenttarget = nil
    return nil, nil
end

local function getgun()
    local char = me.Character
    if not char then return nil end

    for _, tool in ipairs(char:GetChildren()) do
        if tool:IsA("Tool") and tool:GetAttribute("ToolType") == "Gun" then
            return tool
        end
    end
    return nil
end

rs.Heartbeat:Connect(function()
    currentgun = getgun()
end)

rs.PreRender:Connect(function()
    local aimpos = uis:GetMouseLocation()
    local cam = workspace.CurrentCamera

    if cam then
        local lastinput = uis:GetLastInputType()
        local locked = (lastinput == Enum.UserInputType.Touch) or (uis.MouseBehavior == Enum.MouseBehavior.LockCenter)
        if locked then
            local vs = cam.ViewportSize
            aimpos = Vector2.new(vs.X / 2, vs.Y / 2)
        end
    end

    fovcircle.Position = aimpos
    fovcircle.Radius = cfg.fov
    fovcircle.Visible = cfg.showfov and cfg.enabled

    if cfg.showtargetline and cfg.enabled then
        local target, tpos = getclosest()
        if target and tpos and cam then
            local sp, onscreen = cam:WorldToViewportPoint(tpos)
            if onscreen then
                targetline.From = aimpos
                targetline.To = Vector2.new(sp.X, sp.Y)
                targetline.Visible = true
            else
                targetline.Visible = false
            end
        else
            targetline.Visible = false
        end
    else
        targetline.Visible = false
    end

    updateesp()
end)

uis.InputBegan:Connect(function(input, gpe)
    if gpe then return end
end)

plrs.PlayerRemoving:Connect(removeesp)

local function clearesp()
    for plr, e in pairs(espcache) do
        if e then e:Destroy() end
        espcache[plr] = nil
    end
end

me:GetPropertyChangedSignal("Team"):Connect(function()
    clearesp()
end)

local function noupvals(fn)
    return function(...) return fn(...) end
end

local origcastray
local hooked = false

local function setuphook()
    local castrayf = filtergc("function", {Name = "castRay"}, true)
    if not castrayf then return false end

    origcastray = hookfunction(castrayf, noupvals(function(startPos, targetPos, ...)
    if not cfg.enabled then return origcastray(startPos, targetPos, ...) end

    local closest, cpos = getclosest(cfg.fov)

    if closest and closest.Character then
        local istaser = currentgun and currentgun:GetAttribute("Projectile") == "Taser"
        local isshotgun = currentgun and currentgun:GetAttribute("IsShotgun")
        local shouldhit = false

        if cfg.taseralwayshit and istaser then
            shouldhit = true
        elseif cfg.ifplayerstill and isstanding(closest) then
            shouldhit = true
        else
            shouldhit = rollhit()
        end

        if shouldhit then
            local tpart = gettargetpart(closest.Character)
            if tpart then
                if isshotgun and cfg.shotgunnaturalspread then
                    local spreadamt = 2
                    local offset = Vector3.new(
                        (rng:NextNumber() - 0.5) * spreadamt,
                        (rng:NextNumber() - 0.5) * spreadamt,
                        (rng:NextNumber() - 0.5) * spreadamt
                    )
                    return tpart, tpart.Position + offset
                end
                return tpart, tpart.Position
            end
        else
            if cfg.missspread > 0 then
                local tpart = gettargetpart(closest.Character)
                if tpart then
                    local misspos = getmisspos(tpart.Position)
                    return nil, misspos
                end
            end
            return origcastray(startPos, targetPos, ...)
        end
    end

    return origcastray(startPos, targetPos, ...)
end))
    return true
end

if not setuphook() then
    task.spawn(function()
        while not hooked do
            task.wait(0.5)
            if setuphook() then
                hooked = true
            end
        end
    end)
else
    hooked = true
end
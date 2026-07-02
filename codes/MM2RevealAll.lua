local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local CHAM_TAG = "__MM2RevealAll_System"
local GUI_NAME = "MM2RevealAll_ControlGUI"

-- Cleanup old session
local prev = RunService:FindFirstChild(CHAM_TAG)
if prev then prev:Fire()
    prev:Destroy()
    task.wait(0.1)
end

for _, p in ipairs(Players:GetPlayers()) do
    if p.Character then
        for _, c in ipairs(p.Character:GetChildren()) do
            if c:IsA("Highlight") then c:Destroy() end
        end
    end
end
for _, d in ipairs(workspace:GetDescendants()) do
    if d:IsA("Highlight") and (d.Name == "CoinHighlight" or d.Name == "GunHighlight" or d.Name == "MM2Highlight") then d:Destroy() end
end

if CoreGui:FindFirstChild(GUI_NAME) then CoreGui:FindFirstChild(GUI_NAME):Destroy() end

local killSignal = Instance.new("BindableEvent")
killSignal.Name = CHAM_TAG
killSignal.Parent = RunService

local connections = {}
local playerStates = {}
local collectedCoins = {}
local coinEspEnabled = false

local function safeConnect(signal, callback)
    local conn = signal:Connect(callback)
    table.insert(connections, conn)
    return conn
end

-- Refresh player highlight
local function updateESP(player)
    if player == LocalPlayer or not player.Character then return end
    local state = playerStates[player] or { role = "Innocent", isDead = false }
    local color = state.isDead and Color3.fromRGB(0, 255, 0) or 
                 (state.role == "Murderer" and Color3.fromRGB(255, 0, 0)) or
                 (state.role == "Sheriff" and Color3.fromRGB(0, 0, 255)) or
                 (state.role == "Hero" and Color3.fromRGB(255, 128, 0)) or
                 Color3.fromRGB(0, 255, 0)
    
    local highlight = player.Character:FindFirstChild("MM2Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "MM2Highlight"
        highlight.FillTransparency = 0.75
        highlight.OutlineTransparency = 0
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = player.Character
    end
    highlight.FillColor = color
    highlight.OutlineColor = color
end

-- Setup player listeners
local function setupPlayer(player)
    if player == LocalPlayer then return end
    safeConnect(player.CharacterAdded, function(char)
        char:WaitForChild("HumanoidRootPart", 10)
        updateESP(player)
    end)
    if player.Character then updateESP(player) end
end

-- Highlight Gun Drop
local function processGunDrop(obj)
    if obj.Name == "GunDrop" and obj:IsA("BasePart") then
        task.wait(0.1)
        if not obj:IsDescendantOf(workspace) then return end
        local hl = obj:FindFirstChild("GunHighlight") or Instance.new("Highlight")
        hl.Name = "GunHighlight"
        hl.FillColor = Color3.fromRGB(255, 128, 0)
        hl.OutlineColor = Color3.fromRGB(255, 128, 0)
        hl.FillTransparency = 0.75
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = obj
    end
end

-- Highlight Coins
local function processCoin(obj)
    if not coinEspEnabled or collectedCoins[obj] then return end
    if obj.Name == "MainCoin" and obj:IsA("BasePart") then
        task.wait(0.1)
        if not obj:IsDescendantOf(workspace) or collectedCoins[obj] then return end
        if obj.Transparency ~= 0 then
            collectedCoins[obj] = true
            return
        end
        
        local hl = obj:FindFirstChild("CoinHighlight") or Instance.new("Highlight")
        hl.Name = "CoinHighlight"
        hl.FillColor = Color3.fromRGB(255, 215, 0)
        hl.OutlineColor = Color3.fromRGB(255, 215, 0)
        hl.FillTransparency = 0.75
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = obj

        local conn
        conn = safeConnect(obj:GetPropertyChangedSignal("Transparency"), function()
            if obj.Transparency ~= 0 then
                collectedCoins[obj] = true
                local h = obj:FindFirstChild("CoinHighlight")
                if h then h:Destroy() end
                conn:Disconnect()
            end
        end)
    end
end

-- Remote Listeners
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
local gameplay = remotes and remotes:FindFirstChild("Gameplay")

local function applyData(data)
    if typeof(data) ~= "table" then return end
    local activePlayers = {}
    for name, pInfo in pairs(data) do
        local p = Players:FindFirstChild(name)
        if p then
            activePlayers[p] = true
            playerStates[p] = { role = pInfo.Role or "Innocent", isDead = pInfo.Dead or false }
            updateESP(p)
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and not activePlayers[p] then
            playerStates[p] = { role = "Innocent", isDead = false }
            updateESP(p)
        end
    end
end

if gameplay then
    local pdc = gameplay:FindFirstChild("PlayerDataChanged")
    if pdc then safeConnect(pdc.OnClientEvent, applyData) end

    local roundEnd = gameplay:FindFirstChild("RoundEnd") or gameplay:FindFirstChild("RoundEndFade") or gameplay:FindFirstChild("GameOver")
    if roundEnd then
        safeConnect(roundEnd.OnClientEvent, function()
            playerStates = {}
            collectedCoins = {}
            for _, p in ipairs(Players:GetPlayers()) do updateESP(p) end
        end)
    end

    -- Initial load check for ongoing round
    local getCurData = gameplay:FindFirstChild("GetCurrentPlayerData")
    if getCurData and getCurData:IsA("RemoteFunction") then
        task.spawn(function()
            local ok, res = pcall(function() return getCurData:InvokeServer() end)
            if ok then applyData(res) end
        end)
    end
end

-- Initial scans & triggers
for _, obj in ipairs(workspace:GetDescendants()) do
    processGunDrop(obj)
    processCoin(obj)
end
safeConnect(workspace.DescendantAdded, function(obj)
    processGunDrop(obj)
    processCoin(obj)
end)

for _, p in ipairs(Players:GetPlayers()) do setupPlayer(p) end

safeConnect(Players.PlayerAdded, setupPlayer)
safeConnect(Players.PlayerRemoving, function(p) playerStates[p] = nil end)

-- Update ticker
safeConnect(RunService.Heartbeat, function()
    for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then updateESP(p) end end
end)

-- UI Setup
local sg = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
sg.Name = GUI_NAME
sg.ResetOnSpawn = false
sg.DisplayOrder = 99999
sg.ZIndexBehavior = Enum.ZIndexBehavior.Global
sg.IgnoreGuiInset = true

local f = Instance.new("Frame", sg)
f.Size = UDim2.new(0, 150, 0, 83)
f.Position = UDim2.new(0.02, 0, 0.5, 0)
f.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
f.Active = true
f.BorderSizePixel = 0
f.Draggable = true

local stroke = Instance.new("UIStroke", f)
stroke.Thickness = 1
stroke.Color = Color3.new(32, 32, 32)
stroke.Transparency = 0.75

local function createBtn(text, pos, color, cb)
    local btn = Instance.new("TextButton", f)
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = pos
    btn.BackgroundColor3 = color
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.MouseButton1Click:Connect(cb)
    return btn
end

coinBtn = createBtn(
    "Coin ESP: OFF",
    UDim2.new(0.05, 0, 0.075, 0),
    Color3.fromHex("#993d3d"),
    function()
        coinEspEnabled = not coinEspEnabled
        local btnColor = coinEspEnabled and "#57993d" or "#993d3d"
        coinBtn.BackgroundColor3 = Color3.fromHex(btnColor)
        coinBtn.Text = "Coin ESP: " .. (coinEspEnabled and "ON" or "OFF")
        if coinEspEnabled then
            for _, obj in ipairs(workspace:GetDescendants()) do processCoin(obj) end
        else
            for _, desc in ipairs(workspace:GetDescendants()) do
                if desc:IsA("Highlight") and desc.Name == "CoinHighlight" then
                    desc:Destroy()
                end
            end
        end
    end
)

local isTp = false
tpBtn = createBtn(
    "TP to Gun Drop",
    UDim2.new(0.05, 0, 0.55, 0),
    Color3.fromHex("#23456d"),
    function()
        if isTp then return end
        local gd
        for _, desc in ipairs(workspace:GetDescendants()) do
            if desc.Name == "GunDrop" and desc:IsA("BasePart") then
                gd = desc
                break
            end
        end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if gd and hrp then
            isTp = true
            local prevCF = hrp.CFrame
            hrp.CFrame = gd.CFrame + Vector3.new(0, 2, 0)
            task.wait(0.01)
            hrp.CFrame = prevCF
            isTp = false
        end
    end
)

safeConnect(killSignal.Event, function()
    for _, conn in ipairs(connections) do
        if conn.Connected then conn:Disconnect() end
    end
    sg:Destroy()
    connections = {}
    playerStates = {}
    collectedCoins = {}
end)
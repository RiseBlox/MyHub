if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local UserInputService = game:GetService("UserInputService")

local RemoteFunctions = ReplicatedStorage:WaitForChild("RemoteFunctions")
local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local GetOpponentType = RemoteFunctions:WaitForChild("GetOpponentTypeFunction")
local MakeGuessEvent = RemoteEvents:WaitForChild("MakeGuessEvent")

pcall(function()
    CoreGui:FindFirstChild("GuessPanel"):Destroy()
end)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GuessPanel"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui
ScreenGui.DisplayOrder = 99999
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 320, 0, 160)
Main.Position = UDim2.new(0.5, -160, 0.5, -80)
Main.BackgroundColor3 = Color3.fromRGB(21, 22, 24)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local stroke = Instance.new("UIStroke", Main)
stroke.Thickness = 1
stroke.Color = Color3.new(32, 32, 32)
stroke.Transparency = 0.75

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 32)
TitleBar.BackgroundColor3 = Color3.fromRGB(41, 74, 122)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -64, 1, 0)
Title.Position = UDim2.new(0, 32, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Reveal Other"
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 16
Title.TextColor3 = Color3.fromRGB(255,255,255)
Title.Parent = TitleBar

local Close = Instance.new("TextButton")
Close.Size = UDim2.new(0, 32, 1, 0)
Close.Position = UDim2.new(1, -32, 0, 0)
Close.BackgroundTransparency = 1
Close.Text = "×"
Close.Font = Enum.Font.SourceSansBold
Close.TextSize = 18
Close.TextColor3 = Color3.fromRGB(255,255,255)
Close.Parent = TitleBar


local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, 0, 1, -32)
Content.Position = UDim2.new(0, 0, 0, 32)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 10)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.VerticalAlignment = Enum.VerticalAlignment.Top
Layout.Parent = Content

local Padding = Instance.new("UIPadding")
Padding.PaddingTop = UDim.new(0, 14)
Padding.Parent = Content

local function createButton(text)
    local Button = Instance.new("TextButton")
    Button.Size = UDim2.new(0.8, 0, 0, 32)
    Button.BackgroundColor3 = Color3.fromRGB(35, 69, 109)
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = false
    Button.Text = text
    Button.Font = Enum.Font.SourceSansBold
    Button.TextSize = 16
    Button.TextColor3 = Color3.fromRGB(255,255,255)

    Button.MouseEnter:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(66, 150, 250)
        }):Play()
    end)

    Button.MouseLeave:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.1), {
            BackgroundColor3 = Color3.fromRGB(35, 69, 109)
        }):Play()
    end)

    Button.MouseButton1Down:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.05), {
            BackgroundColor3 = Color3.fromRGB(27, 135, 250)
        }):Play()
    end)

    Button.MouseButton1Up:Connect(function()
        TweenService:Create(Button, TweenInfo.new(0.05), {
            BackgroundColor3 = Color3.fromRGB(66, 150, 250)
        }):Play()
    end)

    Button.Parent = Content
    return Button
end

local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(0.9, 0, 0, 18)
StatusBar.BackgroundColor3 = Color3.fromRGB(29, 47, 73)
StatusBar.BorderSizePixel = 0
StatusBar.Parent = Content

local Fill = Instance.new("Frame")
Fill.Size = UDim2.new(0, 0, 1, 0)
Fill.BackgroundColor3 = Color3.fromRGB(230, 179, 47)
Fill.BorderSizePixel = 0
Fill.Parent = StatusBar

local StatusText = Instance.new("TextLabel")
StatusText.Size = UDim2.new(1, 0, 1, 0)
StatusText.BackgroundTransparency = 1
StatusText.Text = "Awaiting Action"
StatusText.Font = Enum.Font.SourceSansBold
StatusText.TextSize = 14
StatusText.TextColor3 = Color3.fromRGB(255,255,255)
StatusText.Parent = StatusBar

local function setStatus(text, percent)
    StatusText.Text = text

    TweenService:Create(
        Fill,
        TweenInfo.new(0.15),
        {
            Size = UDim2.new(percent, 0, 1, 0)
        }
    ):Play()
end

local function determineOpponent()
    local success, result = pcall(function()
        return GetOpponentType:InvokeServer()
    end)

    if success then
        return result
    end

    return nil
end

local RevealButton = createButton("Reveal Opponent")
local GuessButton = createButton("Correctly Guess")

RevealButton.MouseButton1Click:Connect(function()
    setStatus("Detecting...", 0.35)

    local result = determineOpponent()

    if result == "AI" then
        setStatus("Opponent: AI Bot", 1)
    elseif result == "Player" then
        setStatus("Opponent: Real Player", 1)
    else
        setStatus("Detection Failed", 0)
    end
end)

GuessButton.MouseButton1Click:Connect(function()
    setStatus("Guessing...", 0.5)

    local result = determineOpponent()

    if result == "AI" then
        MakeGuessEvent:FireServer("AI")
        setStatus("Guessed: AI", 1)
    elseif result == "Player" then
        MakeGuessEvent:FireServer("Player")
        setStatus("Guessed: Player", 1)
    else
        setStatus("Guess Failed", 0)
    end
end)

Close.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

local dragging = false
local dragInput
local dragStart
local startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

TitleBar.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart

        Main.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

setStatus("System Ready", 0.15)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local THIRD_DISTANCE = 10
local THIRD_HEIGHT = 2

local SECOND_DISTANCE = 8
local SECOND_HEIGHT = 2

--[[
    1 = First Person
    2 = Third Person
    3 = Second Person
]]

local Mode = 1

local Character
local Head
local Humanoid
local RootPart

local W, A, S, D = false, false, false, false

local function SetupCharacter(char)

    Character = char

    Head = char:WaitForChild("Head")
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
end

if Player.Character then
    SetupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(SetupCharacter)

local function SetVisibility(visible)

    for _, v in ipairs(Character:GetDescendants()) do

        if v:IsA("BasePart") then

            if visible then

                v.LocalTransparencyModifier = 0

            else

                if v.Name == "Head"
                or v.Parent:IsA("Accessory") then

                    v.LocalTransparencyModifier = 1
                end
            end
        end
    end
end

UIS.InputBegan:Connect(function(input, gp)

    if gp then
        return
    end

    if input.KeyCode == Enum.KeyCode.P then

        Mode += 1

        if Mode > 3 then
            Mode = 1
        end
    end

    if input.KeyCode == Enum.KeyCode.W then
        W = true

    elseif input.KeyCode == Enum.KeyCode.A then
        A = true

    elseif input.KeyCode == Enum.KeyCode.S then
        S = true

    elseif input.KeyCode == Enum.KeyCode.D then
        D = true
    end
end)

UIS.InputEnded:Connect(function(input)

    if input.KeyCode == Enum.KeyCode.W then
        W = false

    elseif input.KeyCode == Enum.KeyCode.A then
        A = false

    elseif input.KeyCode == Enum.KeyCode.S then
        S = false

    elseif input.KeyCode == Enum.KeyCode.D then
        D = false
    end
end)

RunService.RenderStepped:Connect(function()

    if Mode ~= 3
    or not Humanoid then
        return
    end

    local move = Vector3.zero

    if W then
        move += Vector3.new(0, 0, 1)
    end

    if S then
        move += Vector3.new(0, 0, -1)
    end

    if A then
        move += Vector3.new(-1, 0, 0)
    end

    if D then
        move += Vector3.new(1, 0, 0)
    end

    Humanoid:Move(move, true)
end)

RunService:BindToRenderStep(
    "CustomCamera",
    Enum.RenderPriority.Camera.Value + 1,
    function()

        if not Character
        or not Head
        or not RootPart then
            return
        end

        Camera.CameraType =
            Enum.CameraType.Scriptable

        if Mode == 1 then

            SetVisibility(false)

            Camera.CFrame =
                Head.CFrame

        elseif Mode == 2 then

            SetVisibility(true)

            local look =
                Camera.CFrame.LookVector

            local move =
                Humanoid.MoveDirection.Magnitude

            local t = tick()

            local swayX =
                math.sin(t * 5) * 0.75 * move

            local swayY =
                math.cos(t * 9) * 0.325 * move

            local camPos =
                Head.Position
                - (look * THIRD_DISTANCE)
                + Vector3.new(
                    swayX,
                    THIRD_HEIGHT + swayY,
                    0
                )

            local ray = RaycastParams.new()

            ray.FilterType =
                Enum.RaycastFilterType.Blacklist

            ray.FilterDescendantsInstances =
                {Character}

            local hit =
                workspace:Raycast(
                    Head.Position,
                    camPos - Head.Position,
                    ray
                )

            if hit then

                camPos =
                    hit.Position
                    + hit.Normal * 0.35
            end

            Camera.CFrame =
                CFrame.new(
                    camPos,
                    Head.Position
                )

        elseif Mode == 3 then

            SetVisibility(true)

            local forward =
                RootPart.CFrame.LookVector

            local move =
                Humanoid.MoveDirection.Magnitude

            local t = tick()

            local swayX =
                math.sin(t * 5) * 0.75 * move

            local swayY =
                math.cos(t * 9) * 0.325 * move

            local camPos =
                Head.Position
                + (forward * SECOND_DISTANCE)
                + Vector3.new(
                    swayX,
                    SECOND_HEIGHT + swayY,
                    0
                )

            local ray = RaycastParams.new()

            ray.FilterType =
                Enum.RaycastFilterType.Blacklist

            ray.FilterDescendantsInstances =
                {Character}

            local hit =
                workspace:Raycast(
                    Head.Position,
                    camPos - Head.Position,
                    ray
                )

            if hit then

                camPos =
                    hit.Position
                    - hit.Normal * 0.35
            end

            Camera.CFrame =
                CFrame.new(
                    camPos,
                    Head.Position
                )
        end
    end
)
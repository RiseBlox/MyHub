pcall(function()
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local GuiService = game:GetService("GuiService")
    local VirtualUser = game:GetService("VirtualUser")

    local function initializeProtections()
        -- Wait for game and LocalPlayer
        if not game:IsLoaded() then
            game.Loaded:Wait()
        end
        local LocalPlayer = Players.LocalPlayer
        while not LocalPlayer do
            task.wait()
            LocalPlayer = Players.LocalPlayer
        end

        -- 🛡️ AntiKick: block localscript kicks
        local oldIndex
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if self == LocalPlayer and key:lower() == "kick" then
                return function() error("Expected ':' not '.' calling member function Kick", 2) end
            end
            return oldIndex(self, key)
        end)

        local oldNamecall
        oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            if self == LocalPlayer and getnamecallmethod():lower() == "kick" then
                return
            end
            return oldNamecall(self, ...)
        end)

        -- 💤 AntiAFK: Prevent idle kick
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)

        -- 🔁 AutoRejoin with teleport detection
        GuiService.ErrorMessageChanged:Connect(function()
            pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
        end)
    end

    -- Detect when teleport finishes and reinitialize protections
    Players.LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.InProgress then
            -- Hook into arrival
            Players.LocalPlayer.OnTeleport:Connect(function(s2)
                if s2 == Enum.TeleportState.Completed then
                    initializeProtections()
                end
            end)
        end
    end)

    -- First run
    initializeProtections()
    print("🔁 ReJoin activated!")
end)
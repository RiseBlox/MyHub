pcall(function()
    local Players = game:GetService("Players")
    local TeleportService = game:GetService("TeleportService")
    local GuiService = game:GetService("GuiService")
    local VirtualUser = game:GetService("VirtualUser")
    local LocalPlayer = Players.LocalPlayer
    ---
    local function initializeProtections()
        if not game:IsLoaded() then
            game.Loaded:Wait()
        end
        while not Players.LocalPlayer do
            task.wait()
        end
        LocalPlayer = Players.LocalPlayer
        ---
        if not hookmetamethod then
            warn("Incompatible IDE (missing hookmetamethod)")
            return
        end

        local oldKickFunc
        if hookfunction then
            oldKickFunc = hookfunction(LocalPlayer.Kick, function() end)
        end

        local oldIndex
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if self == LocalPlayer and key:lower() == "kick" then
                return error("Expected ':' not '.' calling member function Kick", 2)
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
        ---
        local GC = getconnections or get_signal_cons
        local success = false
        if GC then
            local connections = GC(LocalPlayer.Idled)
            if connections then
                for _, v in pairs(connections) do
                    if v.Disable then
                        v:Disable()
                        success = true
                    elseif v.Disconnect then
                        v:Disconnect()
                        success = true
                    end
                end
            end
        end
        if not success then
            LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end
        --
        GuiService.ErrorMessageChanged:Connect(function()
            task.wait(1)
            local PlaceId = game.PlaceId
            local JobId = game.JobId
            local allPlayers = Players:GetPlayers()

            if #allPlayers <= 1 then
                LocalPlayer:Kick("\nRejoining...")
                task.wait()
                TeleportService:Teleport(PlaceId, LocalPlayer)
            else
                TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
            end
        end)
    end

    Players.LocalPlayer.OnTeleport:Connect(function(state)
        if state == Enum.TeleportState.InProgress then
            Players.LocalPlayer.OnTeleport:Connect(function(s2)
                if s2 == Enum.TeleportState.Completed then
                    initializeProtections()
                end
            end)
        end
    end)

    initializeProtections()

end)
--[[

                           _
  /\/\  _   _  /\  /\_   _| |__
 /    \| | | |/ /_/ / | | | '_ \
/ /\/\ \ |_| / __  /| |_| | |_) |
\/    \/\__, \/ /_/  \__,_|_.__/  v3.0
        |___/


--]]

local UserInputService = game:GetService("UserInputService")

local pcVersion = "https://raw.githubusercontent.com/RiseBlox/MyHub/main/MyHub.luau"
local mobileVersion = "https://raw.githubusercontent.com/RiseBlox/MyHub/main/MobileHub.luau"

local function sendNotification(text, duration, title)
	if game.PlaceId == 606849621 then
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = text,
			Duration = duration
		})
	else
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = title,
			Text = text
		})
	end
end

local function loadMyHub(url)
    loadstring(game:HttpGet(url, true))()
end

local function detectAndload()
    local preferredInput = UserInputService.PreferredInput

    if preferredInput == Enum.PreferredInput.Touch then
        sendNotification("Successfully loaded!", 2, "MyHub V3 - Mobile")
        loadMyHub(mobileVersion)

    elseif preferredInput == Enum.PreferredInput.KeyboardAndMouse then
        sendNotification("Successfully loaded!", 2, "MyHub V3")
        loadMyHub(pcVersion)

    elseif preferredInput == Enum.PreferredInput.Gamepad then
        sendNotification("Successfully loaded!", 2, "MyHub V3")
        loadMyHub(pcVersion)

    else
	    sendNotification("Successfully loaded!", 2, "MyHub V3 - Mobile")
        loadMyHub(mobileVersion)
    end
end

detectAndload()
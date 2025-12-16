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

local function loadMyHub(url)
    loadstring(game:HttpGet(url, true))()
end

local function detectAndLoad()
    local preferredInput = UserInputService.PreferredInput

    if preferredInput == Enum.PreferredInput.Touch then
        game.StarterGui:SetCore("SendNotification", {Text="Successfully loaded!", Title="MyHub V3 - Mobile"})
        loadMyHub(mobileVersion)

    elseif preferredInput == Enum.PreferredInput.KeyboardAndMouse then
        game.StarterGui:SetCore("SendNotification", {Text="Successfully loaded!", Title="MyHub V3"})
        loadMyHub(pcVersion)

    elseif preferredInput == Enum.PreferredInput.Gamepad then
	game.StarterGui:SetCore("SendNotification", {Text="Successfully loaded!", Title="MyHub V3"})
        loadMyHub(pcVersion)

    else
	game.StarterGui:SetCore("SendNotification", {Text="Successfully loaded!", Title="MyHub V3 - Mobile"})
        loadMyHub(mobileVersion)
    end
end

detectAndLoad()
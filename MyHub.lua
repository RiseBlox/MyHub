local UserInputService = game:GetService("UserInputService")
---
local pcVersion = "https://raw.githubusercontent.com/RiseBlox/MyHub/main/MyHub.luau"
local mobileVersion = "https://raw.githubusercontent.com/RiseBlox/MyHub/main/MobileHub.luau"
---
local function loadMyHub(url)
    loadstring(game:HttpGet(url, true))()
end
---
local function detectAndLoad()
    local preferredInput = UserInputService.PreferredInput
    if preferredInput == Enum.PreferredInput.Touch then
        print("[MyHub] Detected mobile (touch-based input)")
        loadMyHub(mobileVersion)
    elseif preferredInput == Enum.PreferredInput.KeyboardAndMouse then
        print("[MyHub] Detected PC (keyboard/mouse)")
        loadMyHub(pcVersion)
    elseif preferredInput == Enum.PreferredInput.Gamepad then
        print("[MyHub] Detected gamepad device — defaulting to PC version")
        loadMyHub(pcVersion)
    else
        warn("[MyHub] Unknown input type — defaulting to mobile version")
        loadMyHub(mobileVersion)
    end
end
---
detectAndLoad()

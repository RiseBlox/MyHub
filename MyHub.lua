--[[

                           _
  /\/\  _   _  /\  /\_   _| |__
 /    \| | | |/ /_/ / | | | '_ \
/ /\/\ \ |_| / __  /| |_| | |_) |
\/    \/\__, \/ /_/  \__,_|_.__/  v4.enhanced
        |___/

]]

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
sendNotification("Successfully loaded!", 2, "MyHub V4 [ENHANCED]")

loadstring(game:HttpGet("https://raw.githubusercontent.com/MyOrganizationStudio/MyHub/main/MyHub.luau", true))()

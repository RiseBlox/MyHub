--[[

                           _
  /\/\  _   _  /\  /\_   _| |__
 /    \| | | |/ /_/ / | | | '_ \
/ /\/\ \ |_| / __  /| |_| | |_) |
\/    \/\__, \/ /_/  \__,_|_.__/
        |___/

「 Free. Powerful. Lightweight. 」

]]

if game.PlaceId == 606849621 then
	require(game:GetService("ReplicatedStorage").Game.Notification).new({
		Text = "Successfully loaded!",
		Duration = 2
	})
else
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "MyHub",
		Text = "Successfully loaded!"
	})
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/MyHub.luau", true))()
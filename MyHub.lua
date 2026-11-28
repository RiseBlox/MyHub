--[[

                           _
  /\/\  _   _  /\  /\_   _| |__
 /    \| | | |/ /_/ / | | | '_ \
/ /\/\ \ |_| / __  /| |_| | |_) |
\/    \/\__, \/ /_/  \__,_|_.__/
        |___/

「 Free. Powerful. Lightweight. 」

]]

if game.GameId == 245662005 then
	require(game:GetService("ReplicatedStorage").Game.Notification).new({
		Text = "Successfully loaded!",
		Duration = 2,
	})
elseif game.GameId == 2440500124 then
	if game.PlaceId == 6516141723 then
		require(game:GetService("Players").LocalPlayer.PlayerGui.MainUI.Initiator.Main_Lobby).caption(
			"Successfully loaded!",
			true
		)
	else
		require(game:GetService("Players").LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game).caption(
			"Successfully loaded!",
			true
		)
	end
else
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "MyHub",
		Text = "Successfully loaded!",
	})
end

loadstring(game:HttpGet("https://raw.githubusercontent.com/RiseBlox/MyHub/main/MyHub.luau", true))()
--[[
	https://github.com/awesomeusername69420/miscellaneous-gmod-stuff

	Over-commenting as per request of StormyStyx
]]

local Cache = {
	Length = 16, -- Change these numbers to modify the crosshair
	Thickness = 4,

	X = ScrW() / 2, -- No point in storing the actual values if we just divide them by 2 anyways
	Y = ScrH() / 2,

	Colors = {
		Black = Color(0, 0, 0, 255),
		Red = Color(255, 0, 0, 255)
	}
}

hook.Add("HUDPaint", "ch", function()
	local X = Cache.X -- Avoid multiple table lookups
	local Y = Cache.Y
	local W = Cache.Length
	local H = Cache.Thickness

	local hW = W / 2 -- Avoid having to divide several times; These are used to center the crosshair
	local hH = H / 2

	-- Outline

	surface.SetDrawColor(Cache.Colors.Black)
	surface.DrawRect(X - hW, Y - hH, W, H) -- Horizontal line; Subtracting the half width from the X position centers it horizontally, so that when you draw at full width it's aligned properly. Same goes for height.
	surface.DrawRect(X - hH, Y - hW, H, W) -- Vertical line

	-- Fill

	surface.SetDrawColor(Cache.Colors.Red)
	surface.DrawRect(X - hW + 1, Y - hH + 1, W - 2, H - 2) -- Horizontal line; The sizes of these lines are inset by 2 pixels and their positions are shifted by 1 to give a 1 pixel outline on each side
	surface.DrawRect(X - hH + 1, Y - hW + 1, H - 2, W - 2) -- Vertical line
end)

hook.Add("OnScreenSizeChanged", "ch", function() -- Update center screen
	Cache.X = ScrW() / 2
	Cache.Y = ScrH() / 2
end)

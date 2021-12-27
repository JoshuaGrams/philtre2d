
-- Rect for allocation spaces.
local function Rect(x, y, w, h, scale)
	local self = {
		x = x or 0,
		y = y or 0,
		w = w,
		h = h,
		designW = w,
		designH = h,
		scale = scale or 1,
	}
	return self
end

return Rect

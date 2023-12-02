
local function pack(self, x, y, w, h, scale)
	self.x, self.y, self.w, self.h, self.scale = x, y, w, h, scale
end

local function unpack(self)
	return self.x, self.y, self.w, self.h, self.scale
end

local function equals(self, x, y, w, h, scale)
	return x == self.x and y == self.y and w == self.w and h == self.h and scale == self.scale
end

local function Allocation(x, y, w, h, scale)
	local self = {
		y = y,
		x = x,
		w = w,
		h = h,
		scale = scale or 1,
		pack = pack,
		unpack = unpack,
		equals = equals
	}
	return self
end

return Allocation


local function pack(self, x, y, w, h, designW, designH, scale)
	self.x, self.y, self.w, self.h = x, y, w, h
	self.designW, self.designH, self.scale = designW, designH, scale
end

local function unpack(self)
	return self.x, self.y, self.w, self.h, self.designW, self.designH, self.scale
end

local function Allocation(x, y, w, h, scale)
	local self = {
		y = y,
		x = x,
		w = w,
		h = h,
		designW = w,
		designH = h,
		scale = scale or 1,
		pack = pack,
		unpack = unpack
	}
	return self
end

return Allocation

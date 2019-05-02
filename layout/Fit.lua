local base = (...):gsub('[^%.]+.[^%.]+$', '')
local Object = require(base .. 'Object')
local Fit = Object:extend()
Fit.className = 'Layout.Fit'

local min, max = math.min, math.max

local function allocateChild(self, w, h, cw, ch)
	local x, y = 0, 0 -- Top right corner of space inside padding.
	if self.pad then
		x, y = self.pad.left, self.pad.top
	end
	local cx, cy = x, y -- Top right corner for child placement.

	-- Clip if necessary.
	cw, ch = min(cw, w), min(ch, h)
	local extraWidth, extraHeight = w - cw, h - ch
	-- Calculate x placement.
	if self.left and not self.right then cx = x + extraWidth
	elseif self.right and not self.left then cx = x + 0
	else cx, extraWidth = x + 0.5 * extraWidth, 0.5 * extraWidth end
	-- Calculate y placement.
	if self.top and not self.bottom then cy = y + extraHeight
	elseif self.bottom and not self.top then cy = y + 0
	else cy, extraHeight = y + 0.5 * extraHeight, 0.5 * extraHeight end
	-- Allocate child.
	self.child:allocate(cx, cy, cw, ch)
	-- Allocate sides.
	if type(self.left) == 'table' and self.left.allocate then
		self.left:allocate(x, y, extraWidth, h)
	end
	if type(self.right) == 'table' and self.right.allocate then
		self.right:allocate(cx + cw, y, extraWidth, h)
	end
	-- Allocate top/bottom.
	if type(self.top) == 'table' and self.top.allocate then
		self.top:allocate(cx, y, cw, extraHeight)
	end
	if type(self.bottom) == 'table' and self.bottom.allocate then
		self.bottom:allocate(cx, cy + ch, cw, extraHeight)
	end
end

local function fitSize(self, w, h)
	allocateChild(self, w, h, self._req.w, self._req.h)
end

local function fitWidth(self, w, h)
	local cw, ch = w, self._req.h * w / self._req.w
	allocateChild(self, w, h, cw, ch)
end

local function fitHeight(self, w, h)
	local cw, ch = self._req.w * h / self._req.h, h
	allocateChild(self, w, h, cw, ch)
end

local function fitAspect(self, w, h)
	local cw, ch
	local req = self._req
	if req.w * h > req.h * w then
		cw, ch = w, w * req.h / req.w
	else
		cw, ch = h * req.w / req.h, h
	end
	allocateChild(self, w, h, cw, ch)
end

local allocate = {
	size = fitSize,
	width = fitWidth,
	height = fitHeight,
	aspect = fitAspect
}

function Fit.allocate(self, x, y, w, h)
	self.pos.x, self.pos.y = x, y
	self.width, self.height = w, h
	if self.pad then
		-- Subtract padding -before- calculating final w, h based on the fit mode.
		w = w - self.pad.left - self.pad.right
		h = h - self.pad.top - self.pad.bottom
	end
	allocate[self.mode](self, w, h)
end

function Fit.request(self)
	self._req = self.child:request()
	return self._req
end

function Fit.set(self, mode, child, space, padding)
	Object.set(self)
	if not allocate[mode] then
		error('unknown Fit mode ' .. mode)
	end
	space = space or {}
	self._req = child:request()
	self.mode = mode
	self.child = child
	self.left, self.right = space.left, space.right
	self.top, self.bottom = space.top, space.bottom
	if type(padding) == 'number' then
		local p = padding
		padding = {}
		padding.left, padding.right = p, p
		padding.top, padding.bottom = p, p
	elseif type(padding) == 'table' then
		if padding.x then
			padding.left, padding.right = padding.x, padding.x
		end
		if padding.y then
			padding.top, padding.bottom = padding.y, padding.y
		end
		padding.left = padding.left or 0
		padding.right = padding.right or 0
		padding.top = padding.top or 0
		padding.bottom = padding.bottom or 0
	end
	self.pad = padding
end

return Fit

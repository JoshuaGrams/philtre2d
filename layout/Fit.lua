local base = (...):gsub('[^%.]+.[^%.]+$', '')
local Object = require(base .. 'Object')
local Fit = Object:extend()
Fit.className = 'Layout.Fit'

local min, max = math.min, math.max

local function allocateChild(self, w, h, cw, ch)
	-- Clip if necessary.
	cw, ch = min(cw, w), min(ch, h)
	local extraWidth, extraHeight = w - cw, h - ch
	local x, y
	-- Calculate x placement.
	if self.left and not self.right then x = extraWidth
	elseif self.right and not self.left then x = 0
	else x, extraWidth = 0.5 * extraWidth, 0.5 * extraWidth end
	-- Calculate y placement.
	if self.top and not self.bottom then y = extraHeight
	elseif self.bottom and not self.top then y = 0
	else y, extraHeight = 0.5 * extraHeight, 0.5 * extraHeight end
	-- Allocate child.
	self.child:allocate(x, y, cw, ch)
	-- Allocate sides.
	if self.left then
		self.left:allocate(0, 0, extraWidth, h)
	end
	if self.right then
		self.right:allocate(x + cw, 0, extraWidth, h)
	end
	-- Allocate top/bottom.
	if self.top then
		self.top:allocate(x, 0, cw, extraHeight)
	end
	if self.bottom then
		self.bottom:allocate(x, y + ch, cw, extraHeight)
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
	allocate[self.mode](self, w, h)
end

function Fit.request(self)
	self._req = self.child:request()
	return self._req
end

function Fit.set(self, mode, child, space)
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
end

return Fit

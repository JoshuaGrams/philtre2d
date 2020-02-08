local base = (...):gsub('[^%.]+$', '')
local Node = require(base .. 'Node')

local SliceNode = Node:extend()
SliceNode.className = 'SliceNode'

local scaleFuncs = Node._scaleFuncs

function SliceNode.draw(self)
	love.graphics.setBlendMode(self.blendMode)
	love.graphics.setColor(self.color)

	local w2, h2 = self.w/2, self.h/2
	local m = self.margins
	local s = self.scale

	love.graphics.draw(self.image, self.quadTl, -w2, -h2, 0, s, s) -- Top Left
	love.graphics.draw(self.image, self.quadTr, w2-m.rt, -h2, 0, s, s) -- Top Right
	love.graphics.draw(self.image, self.quadBl, -w2, h2-m.bot, 0, s, s) -- Bottom Left
	love.graphics.draw(self.image, self.quadBr, w2-m.rt, h2-m.bot, 0, s, s) -- Bottom Right

	love.graphics.draw(self.image, self.quadTop, -w2+m.lt, -h2, 0, self.innerSX, s) -- Top
	love.graphics.draw(self.image, self.quadBot, -w2+m.lt, h2-m.bot, 0, self.innerSX, s) -- Bottom
	love.graphics.draw(self.image, self.quadLt, -w2, -h2+m.top, 0, s, self.innerSY) -- Left
	love.graphics.draw(self.image, self.quadRt, w2-m.rt, -h2+m.top, 0, s, self.innerSY) -- Right

	love.graphics.draw(self.image, self.quadC, -w2+m.lt, -h2+m.top, 0, self.innerSX, self.innerSY) -- Center
end

local function debugDraw(self)
	love.graphics.setColor(self.debugColor)
	local pivotPosx, pivotPosy = self.w*self.px/2, self.h*self.py/2
	local s = self.scale
	love.graphics.rectangle('line', -5*s+pivotPosx, -5*s+pivotPosy, 10*s, 10*s)
	love.graphics.circle('fill', pivotPosx, pivotPosy, 4.5*s, 4)
	love.graphics.line(-8*s, 0, 8*s, 0)
	love.graphics.line(0, -8*s, 0, 8*s)
	love.graphics.rectangle('line', -self.w*0.5, -self.h*0.5, self.w, self.h)

	local w2, h2 = self.w/2, self.h/2
	local m = self.margins

	love.graphics.line(-w2+m.lt, -h2, -w2+m.lt, h2)
	love.graphics.line(w2-m.rt, -h2, w2-m.rt, h2)
	love.graphics.line(-w2, -h2+m.top, w2, -h2+m.top)
	love.graphics.line(-w2, h2-m.bot, w2, h2-m.bot)
end

function SliceNode.debugDraw(self, layer)
	if self.tree then
		self.tree.draw_order:addFunction(layer, self._to_world, debugDraw, self)
	end
end

function SliceNode._onRescale(self, relScale)
	for k,v in pairs(self.margins) do
		self.margins[k] = v * relScale
	end
	if self.resizeModeX == 'none' then  self.w = self.w * relScale  end
	if self.resizeModeY == 'none' then  self.h = self.h * relScale  end
end

function SliceNode._updateInnerSize(self)
	local m = self.margins
	m.lt2, m.rt2, m.top2, m.bot2 = m.lt/2, m.rt/2, m.top/2, m.bot/2
	self.innerW = self.w - self.margins.lt - self.margins.rt
	self.innerH = self.h - self.margins.top - self.margins.bot
	self.innerSX = self.innerW/self.innerQuadW
	self.innerSY = self.innerH/self.innerQuadH
end

function SliceNode.set(self, image, quad, margins, x, y, angle, w, h, ax, ay, px, py, resizeMode)
	local mCount = #margins
	local m
	if mCount == 1 then -- One value, all are equal.
		m = { lt=margins[1], rt=margins[1], top=margins[1], bot=margins[1] }
	elseif mCount == 2 then -- Two values, both sides equal along either axis.
		m = { lt=margins[1], rt = margins[1], top=margins[2], bot=margins[2] }
	else -- Four values, all are different.
		m = { lt=margins[1], rt=margins[2], top=margins[3], bot=margins[4] }
	end
	self.margins = m
	SliceNode.super.set(self, x, y, angle, w, h, ax, ay, px, py, resizeMode, (m.lt + m.rt)/2, (m.top + m.bot)/2)
	self.blendMode = 'alpha'
	self.color = {1, 1, 1, 1}

	if type(image) == 'string' then
		image = new.image(image)
	elseif image.type and image:type() == 'Image' then
		image = image
	end
	self.image = image
	local lt, top, qw, qh = 0, 0, 0, 0
	local imgW, imgH

	local quadType = type(quad)
	if quadType == 'userdata' and quad.typeOf and quad:typeOf('Quad') then
		lt, top, qw, qh = quad:getViewport()
	elseif quadType == 'table' then
		lt, top, qw, qh = unpack(quad)
		imgW, imgH = self.image:getDimensions()
	else
		qw, qh = self.image:getDimensions()
		imgW, imgH = qw, qh
	end

	local rt, bot = lt + qw, top + qh
	local innerLt, innerRt = lt + m.lt, rt - m.rt
	local innerTop, innerBot = top + m.top, bot - m.bot
	local innerW, innerH = qw - m.lt - m.rt, qh - m.top - m.bot
	self.innerQuadW, self.innerQuadH = innerW, innerH
	-- self.innerW, self.innerH = innerW, innerH
	-- self.origInnerW, self.origInnerH = innerW, innerH

	-- Make 4 corner quads.
	self.quadTl = love.graphics.newQuad(lt, top, m.lt, m.top, imgW, imgH)
	self.quadTr = love.graphics.newQuad(innerRt, top, m.rt, m.top, imgW, imgH)
	self.quadBl = love.graphics.newQuad(lt, innerBot, m.lt, m.bot, imgW, imgH)
	self.quadBr = love.graphics.newQuad(innerRt, innerBot, m.rt, m.bot, imgW, imgH)
	-- Make 4 edge quads.
	self.quadTop = love.graphics.newQuad(innerLt, top, innerW, m.top, imgW, imgH)
	self.quadBot = love.graphics.newQuad(innerLt, innerBot, innerW, m.bot, imgW, imgH)
	self.quadLt = love.graphics.newQuad(lt, innerTop, m.lt, innerH, imgW, imgH)
	self.quadRt = love.graphics.newQuad(innerRt, innerTop, m.rt, innerH, imgW, imgH)
	-- Make center quad.
	self.quadC = love.graphics.newQuad(innerLt, innerTop, innerW, innerH, imgW, imgH)
end

return SliceNode

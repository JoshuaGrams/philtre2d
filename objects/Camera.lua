local base = (...):gsub('objects%.Camera$', '')
local Object = require(base .. 'objects.Object')

local Camera = Object:extend()

Camera.className = 'Camera'

local cameras = {}
local fallbackCam

-- Global default settings
Camera.current = nil -- set to fallbackCam at end of module
Camera.shakeFalloff = "linear"
Camera.recoilFalloff = "quadratic"
Camera.shakeRotMult = 0.001
Camera.shakeFreq = 8
Camera.followLerpSpeed = 0.85
Camera.viewportAlign = { x = 0.5, y = 0.5 }
Camera.pivot = { x = 0.5, y = 0.5 }
Camera.doCropViewport = true

-- localize stuff
local min = math.min
local max = math.max
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local rand = love.math.random
local TWO_PI = math.pi*2

--##############################  Private Functions  ##############################

local function vec2(x, y)
	return { x = x or 0, y = y or 0 }
end

local function rotate(x, y, a) -- vector rotate with x, y
	local ax, ay = cos(a), sin(a)
	return ax*x - ay*y, ay*x + ax*y
end

local function shallowCopyDict(t)
	local t2 = {}
	for k, v in pairs(t) do t2[k] = v end
	return t2
end

local falloffFuncs = {
	linear = function(x) return x end,
	quadratic = function(x) return x*x end
}

local function lerpdt(ax, ay, bx, by, rate, dt) -- vector lerp with x, y over dt
	local k = (1 - rate)^dt
	return (ax - bx)*k + bx, (ay - by)*k + by
end

local function isVec(v)
	local t = type(v)
	if t == "table" or t == "userdata" or t == "cdata" then
		if v.x and v.y then
			return v.x, v.y
		elseif v.w and v.h then
			return v.w, v.h
		elseif v[1] and v[2] then
			return v[1], v[2]
		end
	end
end

local function setViewport(camera, x, y, w, h)
	local vp = camera.vp
	local aspect = camera.aspectRatio
	local align = camera.viewportAlign
	local pivot = camera.pivot
	if aspect then  -- letterbox
		vp.w = math.min(w, h * aspect)
		vp.h = vp.w / aspect
		vp.x = x + (w - vp.w) * align.x
		vp.y = y + (h - vp.h) * align.y
	else
		vp.x, vp.y, vp.w, vp.h = x, y, w, h
	end
	vp.pivot = {
		x = vp.x + vp.w * pivot.x,
		y = vp.y + vp.h * pivot.y
	}
	return vp
end

local function decipherZoomOrArea(zoomOrArea)
	local t = type(zoomOrArea)
	if t == "nil" then
		return 1 -- default value
	elseif t == "number" then
		return zoomOrArea -- if number
	else
		local x, y = isVec(zoomOrArea)
		if x and y then
			return x, y -- if vec
		end
	end
	return -- invalid value, returns nil
end

Camera.scaleModes = {
	["expand view"] = function(z, oldW, oldH, newW, newH)
		return z
	end,
	["fixed area"] = function(z, oldW, oldH, newW, newH)
		local newA = newW * newH
		local oldA = oldW * oldH
		return z * sqrt(newA / oldA) -- zoom is the scale on both axes, hence the square root
	end,
	["fixed width"] = function(z, oldW, oldH, newW, newH)
		return z * newW / oldW
	end,
	["fixed height"] = function(z, oldW, oldH, newW, newH)
		return z * newH / oldH
	end,
}

local function updateZoomAfterResize(z, scaleMode, oldW, oldH, newW, newH)
	local scaleFn = Camera.scaleModes[scaleMode]
	assert(scaleFn, "Camera - updateZoomAfterResize() - invalid scale mode: " .. tostring(scaleMode))
	return scaleFn(z, oldW, oldH, newW, newH)
end

local function getOffsetFromDeadzone(self, obj, deadzone)
	-- get target pos in screen coordinates
	local tx, ty = obj.pos.x, obj.pos.y
	tx, ty = self:worldToScreen(tx, ty)

	-- convert deadzone screen percent values to screen pixel values
	--		and from  x, y, w, y  to  lt, rt, top, bot
	--		use viewport, not full screen
	local dz = deadzone
	local lt, rt = dz.x*self.vp.w + self.vp.x, (dz.x+dz.w)*self.vp.w + self.vp.x
	local top, bot = dz.y*self.vp.h + self.vp.y, (dz.y+dz.h)*self.vp.h + self.vp.y
	-- get target offset outside of deadzone
	local x = tx < lt and (tx-lt) or tx > rt and (tx-rt) or 0
	local y = ty < top and (ty-top) or ty > bot and (ty-bot) or 0

	-- if target is outside of deadzone, convert the offset back to world coordinates
	if x ~= 0 or y ~= 0 then
		return self:screenToWorld(x, y, true)
	end
	return x, y
end

--##############################  Public Functions ##############################

Camera.debugDraw = false  -- Override Object's debug draw function.

function Camera.setAllViewports(x, y, w, h)
	for i,cam in ipairs(cameras) do
		cam:setViewport(x, y, w, h)
	end
end

function Camera.setViewport(self, x, y, w, h)
	local vpw, vph = self.vp.w, self.vp.h -- save last values
	-- Must enforce fixed aspect ratio before figuring zoom.
	setViewport(self, x, y, w, h)
	self.zoom = updateZoomAfterResize(self.zoom, self.scaleMode, vpw, vph, self.vp.w, self.vp.h)
end

function Camera.update(self, dt)

	self:updateFollows(dt)

	self:enforceBounds()

	-- update shakes & recoils
	self.shakeX, self.shakeY, self.shakeA = 0, 0, 0
	for i=#self.shakes,1,-1 do -- iterate backwards because I may remove elements
		local s = self.shakes[i]
		local k = s.falloff(s.t/s.dur) -- falloff multiplier based on percent finished
		local x, y, a = 0, 0, 0
		if s.freq then -- is a perlin shake
			x = (love.math.noise(s.seed, s.t*s.freq) - 0.5)*2
			y = (love.math.noise(s.seed+1, s.t*s.freq) - 0.5)*2
			a = (love.math.noise(s.seed+2, s.t*s.freq) - 0.5)*2
			local d = s.dist * k
			x = x * d;  y = y * d
			a = a * d * self.shakeRotMult
		elseif s.dist then -- is a shake
			local d = rand() * s.dist * k
			local angle = rand() * TWO_PI
			x = sin(angle) * d;  y = cos(angle) * d
			a = (rand()-0.5)*2 * s.dist * k * self.shakeRotMult
		elseif s.vec then -- is a recoil
			x = s.vec.x * k;  y = s.vec.y * k
		end
		self.shakeX = self.shakeX + x
		self.shakeY = self.shakeY + y
		self.shakeA = self.shakeA + a
		s.t = s.t - dt
		if s.t <= 0 then  table.remove(self.shakes, i)  end
	end
end

function Camera.apply(self)
	love.graphics.push()
	love.graphics.origin()

	local wAngle = matrix.parameters(self._toWorld)
	local wx, wy = self._toWorld.x, self._toWorld.y

	love.graphics.translate(self.vp.pivot.x, self.vp.pivot.y)
	love.graphics.rotate(-wAngle - self.shakeA)
	love.graphics.scale(self.zoom, self.zoom)
	love.graphics.translate(-wx - self.shakeX, -wy - self.shakeY)

	local vp = self.vp
	local w, h = love.graphics.getDimensions()
	if self.doCropViewport and (vp.x ~= 0 or vp.y ~= 0 or vp.w ~= w or vp.h ~= h) then
		self.oldScissor = {love.graphics.getScissor()}
		love.graphics.setScissor(vp.x, vp.y, vp.w, vp.h)
	end
end

function Camera.reset(self)
	love.graphics.pop()
	if self.oldScissor then
		love.graphics.setScissor(unpack(self.oldScissor))
		self.oldScissor = nil
	end
end

function Camera.screenToWorld(self, x, y, isDelta)
	-- screen center offset
	if not isDelta then  x = x - self.vp.pivot.x;  y = y - self.vp.pivot.y  end
	x, y = x/self.zoom, y/self.zoom -- scale
	x, y = rotate(x, y, self.angle) -- rotate
	-- translate
	if not isDelta then  x = x + self.pos.x;  y = y + self.pos.y  end
	return x, y
end

function Camera.worldToScreen(self, x, y, isDelta)
	if not isDelta then  x = x - self.pos.x;  y = y - self.pos.y  end
	x, y = rotate(x, y, -self.angle)
	x, y = x*self.zoom, y*self.zoom
	if not isDelta then  x = x + self.vp.pivot.x;  y = y + self.vp.pivot.y  end
	return x, y
end

function Camera.activate(self)
	self.active = true
	Camera.current = self
end

function Camera.final(self)
	for i, v in ipairs(cameras) do
		if v == self then  table.remove(cameras, i)  end
	end
	if Camera.current == self then
		if #cameras > 0 then  Camera.current = cameras[1]
		else  Camera.current = fallbackCam
		end
	end
end

-- zoom in or out by a percentage
function Camera.zoomIn(self, z, xScreen, yScreen)
	local xWorld, yWorld
	if xScreen and yScreen then
		xWorld, yWorld = self:screenToWorld(xScreen, yScreen)
	end
	self.zoom = self.zoom * (1 + z)
	if xScreen and yScreen then
		local xScreen2, yScreen2 = self:worldToScreen(xWorld, yWorld)
		local dx, dy = xScreen2 - xScreen, yScreen2 - yScreen
		dx, dy = self:screenToWorld(dx, dy, true)
		self.pos.x, self.pos.y = self.pos.x + dx, self.pos.y + dy
	end
end

function Camera.shake(self, dist, dur, falloff)
	falloff = falloffFuncs[falloff or self.shakeFalloff]
	table.insert(self.shakes, {dist=dist, t=dur, dur=dur, falloff=falloff})
end

function Camera.perlinShake(self, dist, dur, freq, falloff)
	falloff = falloffFuncs[falloff or self.shakeFalloff]
	freq = freq or self.shakeFreq
	local seed = rand()*1000
	table.insert(self.shakes, {dist=dist, t=dur, dur=dur, freq=freq, seed=seed, falloff=falloff})
end

function Camera.recoil(self, vec, dur, falloff)
	falloff = falloff or self.recoilFalloff
	table.insert(self.shakes, {vec=vec, t=dur, dur=dur, falloff=falloffFuncs[falloff]})
end

function Camera.stopShaking(self) -- clears all shakes and recoils
	for i,v in ipairs(self.shakes) do self.shakes[i] = nil end
end

function Camera.follow(self, obj, allowMultiFollow, weight, deadzone)
	weight = weight or 1
	-- using object table as key
	if self.follows[obj] then -- already following, update weight & deadzone
		self.follows[obj].weight = weight
		if deadzone and type(deadzone) == "table" then
			if self.follows[obj].deadzone then -- update existing deadzone
				for k,v in pairs(deadzone) do self.follows[obj][k] = v end
			else -- no existing deadzone, add deadzone table
				self.follows[obj].deadzone = shallowCopyDict(deadzone)
			end
		end
	else
		self.follows[obj] = { weight=weight }
		if deadzone and type(deadzone) == "table" then
			self.follows[obj].deadzone = shallowCopyDict(deadzone)
		end
		self.followCount = self.followCount + 1
	end
	if not allowMultiFollow and self.followCount > 1 then
		for k,v in pairs(self.follows) do
			if k ~= obj then
				-- maintain deadzone if passed `true`
				if deadzone == true and v.deadzone and self.followCount == 2 then
					self.follows[obj].deadzone = v.deadzone
				end
				self.follows[k] = nil
			end
		end
		self.followCount = 1
	end
end

function Camera.unfollow(self, obj)
	if obj then -- remove specified object from list
		if self.follows[obj] then -- separate condition so it doesn't clear all if obj is not found
			self.follows[obj] = nil
			self.followCount = self.followCount - 1
		end
	else -- no object specified, clear follows
		for k,v in pairs(self.follows) do self.follows[k] = nil end
		self.followCount = 0
	end
end

function Camera.followLerpFn(self, targetX, targetY, dt)
	return lerpdt(self.pos.x, self.pos.y, targetX, targetY, self.followLerpSpeed, dt)
end

function Camera.updateFollows(self, dt)
	if self.followCount > 0 then
		-- average position of all follows
		local totalWeight = 0 -- total weight
		local fx, fy = 0, 0
		for obj,data in pairs(self.follows) do
			if data.deadzone then
				local ox, oy = getOffsetFromDeadzone(self, obj, data.deadzone)
				fx = fx + self.pos.x + ox*data.weight
				fy = fy + self.pos.y + oy*data.weight
			else
				fx = fx + obj.pos.x*data.weight;  fy = fy + obj.pos.y*data.weight
			end
			totalWeight = totalWeight + data.weight
		end
		fx = fx / totalWeight;  fy = fy / totalWeight
		fx, fy = self:followLerpFn(fx, fy, dt)
		self.pos.x, self.pos.y = fx, fy
	end
end

function Camera.setBounds(self, lt, rt, top, bot)
	if lt and rt and top and bot then
		local b = {
			lt=lt, rt=rt, top=top, bot=bot,
			width=rt-lt, height=bot-top
		}
		b.centerX = lt + b.width/2
		b.centerY = top + b.height/2
		self.bounds = b
	else
		self.bounds = nil
	end
end

local _tempCorners = { tl=vec2(), tr=vec2(), bl=vec2(), br=vec2() } -- save the GC some work

function Camera.getViewportBounds(self)
	local vp = self.vp
	local c = _tempCorners -- corners
	-- get viewport corner positions in world space
	c.tl.x, c.tl.y = self:screenToWorld(vp.x, vp.y) -- top left
	c.tr.x, c.tr.y = self:screenToWorld(vp.x + vp.w, vp.y) -- top right
	c.bl.x, c.bl.y = self:screenToWorld(vp.x, vp.y + vp.h) -- bottom left
	c.br.x, c.br.y = self:screenToWorld(vp.x + vp.w, vp.y + vp.h) -- bottom right
	-- get world-aligned viewport bounding box
	local w_lt = min(c.tl.x, c.tr.x, c.bl.x, c.br.x) -- world left
	local w_rt = max(c.tl.x, c.tr.x, c.bl.x, c.br.x) -- world right
	local w_top = min(c.tl.y, c.tr.y, c.bl.y, c.br.y) -- world top
	local w_bot = max(c.tl.y, c.tr.y, c.bl.y, c.br.y) -- world botom
	local w_w, w_h = w_rt - w_lt, w_bot - w_top -- world width, height
	return {
		lt = w_lt, top = w_top,
		rt = w_rt, bot = w_bot,
		w = w_w, h = w_h
	}
end

function Camera.enforceBounds(self)
	if self.bounds then
		local b = self.bounds
		local vp = self.vp
		local c = _tempCorners -- corners
		-- get viewport corner positions in world space
		c.tl.x, c.tl.y = self:screenToWorld(vp.x, vp.y) -- top left
		c.tr.x, c.tr.y = self:screenToWorld(vp.x + vp.w, vp.y) -- top right
		c.bl.x, c.bl.y = self:screenToWorld(vp.x, vp.y + vp.h) -- bottom left
		c.br.x, c.br.y = self:screenToWorld(vp.x + vp.w, vp.y + vp.h) -- bottom right
		-- get world-aligned viewport bounding box
		local w_lt = min(c.tl.x, c.tr.x, c.bl.x, c.br.x) -- world left
		local w_rt = max(c.tl.x, c.tr.x, c.bl.x, c.br.x) -- world right
		local w_top = min(c.tl.y, c.tr.y, c.bl.y, c.br.y) -- world top
		local w_bot = max(c.tl.y, c.tr.y, c.bl.y, c.br.y) -- world botom
		local w_w, w_h = w_rt - w_lt, w_bot - w_top -- world width, height

		local x, y -- final x, y pos
		if w_w > b.width then
			x = b.centerX
		else
			x = w_lt < b.lt and (w_lt-b.lt) or w_rt > b.rt and (w_rt-b.rt) or 0
			x = self.pos.x - x
		end
		if w_h > b.height then
			y = b.centerY
		else
			y = w_top < b.top and (w_top-b.top) or w_bot > b.bot and (w_bot-b.bot) or 0
			y = self.pos.y - y
		end
		self.pos.x = x;  self.pos.y = y
	end
end

function Camera.set(self, x, y, angle, zoomOrArea, scaleMode, fixedAspectRatio, inactive)
	Camera.super.set(self, x, y, angle)
	self.scaleMode = scaleMode or 'fixed area'
	self.aspectRatio = fixedAspectRatio
	self.active = not inactive

	self.zoom = 1
	self.shakes = {}
	self.shakeX, self.shakeY, self.shakeA = 0, 0, 0
	self.follows = {}
	self.followCount = 0
	self.vp = {}
	setViewport(self, 0, 0, love.graphics.getDimensions())

	-- Figure zoom
	local vx, vy = decipherZoomOrArea(zoomOrArea)
	if not vx then
		error("Camera.set - invalid zoom or area: " .. tostring(zoomOrArea))
	elseif vx and not vy then -- user supplied a zoom value, keep this zoom no matter what
		self.zoom = vx
	else -- user supplied a view area - use this with scaleMode and viewport to find zoom
		-- Want initial zoom to respect user settings. Even if "expand view" mode is used,
		-- we want to zoom so the specified area fits the window. Use "fixed area" mode
		-- instead to get a nice fit regardless of proportion differences.
		local sm = self.scaleMode == "expand view" and "fixed area" or self.scaleMode
		self.zoom = updateZoomAfterResize(1, sm, vx, vy, self.vp.w, self.vp.h)
	end

	if self.active then  Camera.current = self  end
	table.insert(cameras, self)
end

do
	local x, y = love.graphics.getDimensions()
	fallbackCam = Camera(x/2, y/2)
	table.remove(cameras, 1)
end
Camera.current = fallbackCam

return Camera

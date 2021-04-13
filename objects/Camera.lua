local base = (...):gsub('objects%.Camera$', '')
local Object = require(base .. 'objects.Object')

local Camera = Object:extend()

Camera.className = 'Camera'

local cameras = {}
local fallback_cam

-- Global default settings
Camera.current = nil -- set to fallback_cam at end of module
Camera.shake_falloff = "linear"
Camera.recoil_falloff = "quadratic"
Camera.shake_rot_mult = 0.001
Camera.shake_freq = 8
Camera.follow_lerp_speed = 3
Camera.viewport_align = { x = 0.5, y = 0.5 }
Camera.pivot = { x = 0.5, y = 0.5 }

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

local function shallow_copy_dict(t)
	local t2 = {}
	for k, v in pairs(t) do t2[k] = v end
	return t2
end

local falloff_funcs = {
	linear = function(x) return x end,
	quadratic = function(x) return x*x end
}

local function lerpdt(ax, ay, bx, by, s, dt) -- vector lerp with x, y over dt
	local k = 1 - 0.5^(dt*s)
	return ax + (bx - ax)*k, ay + (by - ay)*k
end

local function is_vec(v)
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

function set_viewport(camera, x, y, w, h)
	local vp = camera.vp
	local aspect = camera.aspect_ratio
	local align = camera.viewport_align
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

local function decipher_zoom_or_area(zoom_or_area)
	local t = type(zoom_or_area)
	if t == "nil" then
		return 1 -- default value
	elseif t == "number" then
		return zoom_or_area -- if number
	else
		local x, y = is_vec(zoom_or_area)
		if x and y then
			return x, y -- if vec
		end
	end
	return -- invalid value, returns nil
end

Camera.scaleModes = {
	["expand view"] = function(z, old_w, old_h, new_w, new_h)
		return z
	end,
	["fixed area"] = function(z, old_w, old_h, new_w, new_h)
		local new_a = new_w * new_h
		local old_a = old_w * old_h
		return z * sqrt(new_a / old_a) -- zoom is the scale on both axes, hence the square root
	end,
	["fixed width"] = function(z, old_w, old_h, new_w, new_h)
		return z * new_w / old_w
	end,
	["fixed height"] = function(z, old_w, old_h, new_w, new_h)
		return z * new_h / old_h
	end,
}

local function update_zoom_after_resize(z, scale_mode, old_w, old_h, new_w, new_h)
	local scaleFn = Camera.scaleModes[scale_mode]
	assert(scaleFn, "Camera - update_zoom_after_resize() - invalid scale mode: " .. tostring(scale_mode))
	return scaleFn(z, old_w, old_h, new_w, new_h)
end

local function get_offset_from_deadzone(self, obj, deadzone)
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
	local vp_w, vp_h = self.vp.w, self.vp.h -- save last values
	-- Must enforce fixed aspect ratio before figuring zoom.
	set_viewport(self, x, y, w, h)
	self.zoom = update_zoom_after_resize(self.zoom, self.scale_mode, vp_w, vp_h, self.vp.w, self.vp.h)
end

function Camera.update(self, dt)

	self:updateFollows(dt)

	self:enforceBounds()

	-- update shakes & recoils
	self.shake_x, self.shake_y, self.shake_a = 0, 0, 0
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
			a = a * d * self.shake_rot_mult
		elseif s.dist then -- is a shake
			local d = rand() * s.dist * k
			local angle = rand() * TWO_PI
			x = sin(angle) * d;  y = cos(angle) * d
			a = (rand()-0.5)*2 * s.dist * k * self.shake_rot_mult
		elseif s.vec then -- is a recoil
			x = s.vec.x * k;  y = s.vec.y * k
		end
		self.shake_x = self.shake_x + x
		self.shake_y = self.shake_y + y
		self.shake_a = self.shake_a + a
		s.t = s.t - dt
		if s.t <= 0 then table.remove(self.shakes, i) end
	end
end

function Camera.applyTransform(self)
	love.graphics.push()
	-- start at viewport pivot point
	love.graphics.origin()
	love.graphics.translate(self.vp.pivot.x, self.vp.pivot.y)
	-- view rot and translate are negative because we're really transforming the world
	love.graphics.rotate(-self.angle - self.shake_a)
	love.graphics.scale(self.zoom, self.zoom)
	love.graphics.translate(-self.pos.x - self.shake_x, -self.pos.y - self.shake_y)

	local vp = self.vp
	local w, h = love.graphics.getDimensions()
	if vp.x ~= 0 or vp.y ~= 0 or vp.w ~= w or vp.h ~= h then
		self.oldScissor = {love.graphics.getScissor()}
		love.graphics.setScissor(vp.x, vp.y, vp.w, vp.h)
	end
end

function Camera.resetTransform(self)
	love.graphics.pop()
	if self.oldScissor then
		love.graphics.setScissor(unpack(self.oldScissor))
		self.oldScissor = nil
	end
end

function Camera.screenToWorld(self, x, y, is_delta)
	-- screen center offset
	if not is_delta then x = x - self.vp.pivot.x;  y = y - self.vp.pivot.y end
	x, y = x/self.zoom, y/self.zoom -- scale
	x, y = rotate(x, y, self.angle) -- rotate
	-- translate
	if not is_delta then x = x + self.pos.x;  y = y + self.pos.y end
	return x, y
end

function Camera.worldToScreen(self, x, y, is_delta)
	if not is_delta then x = x - self.pos.x;  y = y - self.pos.y end
	x, y = rotate(x, y, -self.angle)
	x, y = x*self.zoom, y*self.zoom
	if not is_delta then x = x + self.vp.pivot.x;  y = y + self.vp.pivot.y end
	return x, y
end

function Camera.activate(self)
	self.active = true
	Camera.current = self
end

function Camera.final(self)
	for i, v in ipairs(cameras) do
		if v == self then table.remove(cameras, i) end
	end
	if Camera.current == self then
		if #cameras > 0 then Camera.current = cameras[1]
		else Camera.current = fallback_cam
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
	falloff = falloff_funcs[falloff or self.shake_falloff]
	table.insert(self.shakes, {dist=dist, t=dur, dur=dur, falloff=falloff})
end

function Camera.perlinShake(self, dist, dur, freq, falloff)
	falloff = falloff_funcs[falloff or self.shake_falloff]
	freq = freq or self.shake_freq
	local seed = rand()*1000
	table.insert(self.shakes, {dist=dist, t=dur, dur=dur, freq=freq, seed=seed, falloff=falloff})
end

function Camera.recoil(self, vec, dur, falloff)
	falloff = falloff or self.recoil_falloff
	table.insert(self.shakes, {vec=vec, t=dur, dur=dur, falloff=falloff_funcs[falloff]})
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
				self.follows[obj].deadzone = shallow_copy_dict(deadzone)
			end
		end
	else
		self.follows[obj] = { weight=weight }
		if deadzone and type(deadzone) == "table" then
			self.follows[obj].deadzone = shallow_copy_dict(deadzone)
		end
		self.follow_count = self.follow_count + 1
	end
	if not allowMultiFollow and self.follow_count > 1 then
		for k,v in pairs(self.follows) do
			if k ~= obj then
				-- maintain deadzone if passed `true`
				if deadzone == true and v.deadzone and self.follow_count == 2 then
					self.follows[obj].deadzone = v.deadzone
				end
				self.follows[k] = nil
			end
		end
		self.follow_count = 1
	end
end

function Camera.unfollow(self, obj)
	if obj then -- remove specified object from list
		if self.follows[obj] then -- separate condition so it doesn't clear all if obj is not found
			self.follows[obj] = nil
			self.follow_count = self.follow_count - 1
		end
	else -- no object specified, clear follows
		for k,v in pairs(self.follows) do self.follows[k] = nil end
		self.follow_count = 0
	end
end

function Camera.updateFollows(self, dt)
	if self.follow_count > 0 then
		-- average position of all follows
		local total_weight = 0 -- total weight
		local fx, fy = 0, 0
		for obj,data in pairs(self.follows) do
			if data.deadzone then
				local ox, oy = get_offset_from_deadzone(self, obj, data.deadzone)
				fx = fx + self.pos.x + ox*data.weight
				fy = fy + self.pos.y + oy*data.weight
			else
				fx = fx + obj.pos.x*data.weight;  fy = fy + obj.pos.y*data.weight
			end
			total_weight = total_weight + data.weight
		end
		fx = fx / total_weight;  fy = fy / total_weight
		fx, fy = lerpdt(self.pos.x, self.pos.y, fx, fy, self.follow_lerp_speed, dt)
		self.pos.x, self.pos.y = fx, fy
	end
end

function Camera.setBounds(self, lt, rt, top, bot)
	if lt and rt and top and bot then
		local b = {
			lt=lt, rt=rt, top=top, bot=bot,
			width=rt-lt, height=bot-top
		}
		b.center_x = lt + b.width/2
		b.center_y = top + b.height/2
		self.bounds = b
	else
		self.bounds = nil
	end
end

local tmp_corners = { tl=vec2(), tr=vec2(), bl=vec2(), br=vec2() } -- save the GC some work

function Camera.getViewportBounds(self)
	local vp = self.vp
	local c = tmp_corners -- corners
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
		local c = tmp_corners -- corners
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
			x = b.center_x
		else
			x = w_lt < b.lt and (w_lt-b.lt) or w_rt > b.rt and (w_rt-b.rt) or 0
			x = self.pos.x - x
		end
		if w_h > b.height then
			y = b.center_y
		else
			y = w_top < b.top and (w_top-b.top) or w_bot > b.bot and (w_bot-b.bot) or 0
			y = self.pos.y - y
		end
		self.pos.x = x;  self.pos.y = y
	end
end

function Camera.set(self, x, y, angle, zoom_or_area, scale_mode, fixed_aspect_ratio, inactive)
	Camera.super.set(self, x, y, angle)
	self.scale_mode = scale_mode or 'fixed area'
	self.aspect_ratio = fixed_aspect_ratio
	self.active = not inactive

	self.zoom = 1
	self.shakes = {}
	self.shake_x, self.shake_y, self.shake_a = 0, 0, 0
	self.follows = {}
	self.follow_count = 0
	self.vp = {}
	set_viewport(self, 0, 0, love.graphics.getDimensions())

	-- Figure zoom
	local vx, vy = decipher_zoom_or_area(zoom_or_area)
	if not vx then
		error("Camera.set - invalid zoom or area: " .. tostring(zoom_or_area))
	elseif vx and not vy then -- user supplied a zoom value, keep this zoom no matter what
		self.zoom = vx
	else -- user supplied a view area - use this with scale_mode and viewport to find zoom
		-- Want initial zoom to respect user settings. Even if "expand view" mode is used,
		-- we want to zoom so the specified area fits the window. Use "fixed area" mode
		-- instead to get a nice fit regardless of proportion differences.
		local sm = self.scale_mode == "expand view" and "fixed area" or self.scale_mode
		self.zoom = update_zoom_after_resize(1, sm, vx, vy, self.vp.w, self.vp.h)
	end

	if self.active then Camera.current = self end
	table.insert(cameras, self)
end

do
	local x, y = love.graphics.getDimensions()
	fallback_cam = Camera(x/2, y/2)
	table.remove(cameras, 1)
end
Camera.current = fallback_cam

return Camera

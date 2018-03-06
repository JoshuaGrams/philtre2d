
local M = {}

-- Try to load a 'vec2' module in the current directory
local module_dir = string.gsub(..., "%.[^%.]+$", "") .. "."
local vec2_loaded, vec2 = pcall(require, module_dir .. "vec2")
if not vec2_loaded then
	-- No vec2 module found, create a minimal table with the functions we need
	local vec2_mt = {}
	vec2 = {
		new = function(x, y) return setmetatable({x=x, y=y}, vec2_mt) end,
	}
	function vec2_mt.__call(_, x, y) return vec2.new(x, y) end
	function vec2_mt.__div(x, y) if type(y) == "number" then return vec2.new(x.x/y, x.y/y) end end
	function vec2_mt.__tostring(a) return string.format("(%+0.3f,%+0.3f)", a.x, a.y) end
	setmetatable(vec2, vec2_mt)
end

M.cur_cam = nil -- set to fallback_cam at end of module
local cameras = {}
M.default_shake_falloff = "linear"
M.default_recoil_falloff = "quadratic"

-- localize stuff
local min = math.min
local max = math.max
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local rand = love.math.random
local TWO_PI = math.pi*2

--##############################  Private Functions  ##############################

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

local function is_vec(v) -- check if `v` is a vector or a table with two values
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

local function get_aspect_rect_in_win(aspect_ratio, win_x, win_y)
	local s = math.min(win_x/aspect_ratio, win_y)
	local w, h = s*aspect_ratio, s
	local x, y = (win_x - w)/2, (win_y - h)/2
	return x, y, w, h
end

local function get_zoom_or_area(zoom_area)
	local t = type(zoom_area)
	if t == "nil" then
		return 1 -- default value
	elseif t == "number" then
		return zoom_area -- if number
	else
		x, y = is_vec(zoom_area)
		if x and y then
			return x, y -- if vec
		end
	end
	return -- invalid value, returns nil
end

local function get_zoom_for_new_window(z, scale_mode, old_x, old_y, new_x, new_y)
	if scale_mode == "expand view" then
		return z
	elseif scale_mode == "fixed area" then
		local new_a = new_x * new_y
		local old_a = old_x * old_y
		return z * sqrt(new_a / old_a) -- zoom is the scale on both axes, hence the square root
	elseif scale_mode == "fixed width" then
		return z * new_x / old_x
	elseif scale_mode == "fixed height" then
		return z * new_y / old_y
	else
		error("Lovercam - get_zoom_for_new_window() - invalid scale mode: " .. tostring(scale_mode))
	end
end

local function get_offset_from_deadzone(self, obj, deadzone)
	-- get target pos in screen coordinates
	local tx, ty = obj.pos.x, obj.pos.y
	tx, ty = self:world_to_screen(tx, ty)

	-- convert deadzone screen percent values to screen pixel values
	--		and x, y, w, y to lt, rt, top, bot
	--		use viewport, not full screen
	local dz = deadzone
	local lt, rt = dz.x*self.vp.w + self.vp.x, (dz.x+dz.w)*self.vp.w + self.vp.x
	local top, bot = dz.y*self.vp.h + self.vp.y, (dz.y+dz.h)*self.vp.h + self.vp.y
	-- get target offset outside of deadzone
	local x = tx < lt and (tx-lt) or tx > rt and (tx-rt) or 0
	local y = ty < top and (ty-top) or ty > bot and (ty-bot) or 0

	-- if target is outside of deadzone, convert the offset back to world coordinates
	if x ~= 0 or y ~= 0 then
		return self:screen_to_world(x, y, true)
	end
	return x, y
end

--##############################  Module Functions ##############################

function M.window_resized(w, h) -- call once on module and it updates all cameras
	for i, self in ipairs(cameras) do
		self.zoom = get_zoom_for_new_window(self.zoom, self.scale_mode, self.win.x, self.win.y, w, h)
		self.win.x = w;  self.win.y = h
		self.half_win.x = self.win.x / 2;  self.half_win.y = self.win.y / 2
		if self.aspect_ratio then
			self.vp.x, self.vp.y, self.vp.w, self.vp.h = get_aspect_rect_in_win(self.aspect_ratio, w, h)
		else
			self.vp.x, self.vp.y, self.vp.w, self.vp.h = 0, 0, w, h
		end
	end
end

function M.update(dt) -- updates all cameras
	for k, cam in pairs(cameras) do cam:update(dt) end
end

function M.update_current(dt)
	M.cur_cam:update(dt)
end

-- convert these names into functions applied to the current camera
local F = {	"apply_transform", "reset_transform", "pan", "screen_to_world",
	"world_to_screen", "zoom_in", "shake", "recoil", "stop_shaking", "follow", "unfollow", "set_bounds" }

for i, func in ipairs(F) do -- calling functions on the module passes the call to the current camera
	M[func] = function(...) return M.cur_cam[func](M.cur_cam, ...) end
end

--##############################  Camera Object Functions  ##############################

local function update(self, dt)
	-- update follows
	if self.follow_count > 0 then
		-- average position of all follows
		local total_weight = 0 -- total weight
		local fx, fy = 0, 0
		for obj, data in pairs(self.follows) do
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

	self:enforce_bounds()

	-- update shakes & recoils
	self.shake_x, self.shake_y = 0, 0
	for i=#self.shakes,1,-1 do -- iterate backwards because I may remove elements
		local s = self.shakes[i]
		local k = s.falloff(s.t/s.dur) -- falloff multiplier based on percent finished
		if s.dist then -- is a shake
			local d = rand() * s.dist * k
			local angle = rand() * TWO_PI
			self.shake_x = self.shake_x + sin(angle) * d
			self.shake_y = self.shake_y + cos(angle) * d
		elseif s.vec then -- is a recoil
			self.shake_x = self.shake_x + vec.x * k
			self.shake_y = self.shake_y + vec.y * k
		end
		s.t = s.t - dt
		if s.t <= 0 then table.remove(self.shakes, i) end
	end
end

local function apply_transform(self)
	-- save previous transform
	love.graphics.push()
	-- center view on camera - offset by half window res
	love.graphics.translate(self.half_win.x, self.half_win.y)
	-- view rot and translate are negative because we're really transforming the world
	love.graphics.rotate(-self.angle)
	love.graphics.scale(self.zoom, self.zoom)
	love.graphics.translate(-self.pos.x - self.shake_x, -self.pos.y - self.shake_y)

	if self.aspect_ratio then
		love.graphics.setScissor(self.vp.x, self.vp.y, self.vp.w, self.vp.h)
	end
end

local function reset_transform(self)
	love.graphics.pop()
	if self.aspect_ratio then love.graphics.setScissor() end
end

local function screen_to_world(self, x, y, delta)
	-- screen center offset
	if not delta then x = x - self.half_win.x;  y = y - self.half_win.y end
	x, y = x/self.zoom, y/self.zoom -- scale
	x, y = rotate(x, y, self.angle) -- rotate
	-- translate
	if not delta then x = x + self.pos.x;  y = y + self.pos.y end
	return x, y
end

local function world_to_screen(self, x, y, delta)
	if not delta then x = x - self.pos.x;  y = y - self.pos.y end
	x, y = rotate(x, y, -self.angle)
	x, y = x*self.zoom, y*self.zoom
	if not delta then x = x + self.half_win.x;  y = y + self.half_win.y end
	return x, y
end

local function activate(self)
	self.active = true
	self.cur_cam = self
end

-- convenience function for moving camera
--		mostly useful to call on the module to apply to the current camera
local function pan(self, dx, dy)
	self.pos.x = self.pos.x + dx
	self.pos.y = self.pos.y + dy
end

-- zoom in or out by a percentage
--		mostly useful to call on the module to apply to the current camera
local function zoom_in(self, z)
	self.zoom = self.zoom * (1 + z)
end

local function shake(self, intensity, dur, falloff)
	falloff = falloff or M.default_shake_falloff
	table.insert(self.shakes, {dist=intensity, t=dur, dur=dur, falloff=falloff_funcs[falloff]})
end

local function recoil(self, vec, dur, falloff)
	falloff = falloff or M.default_recoil_falloff
	table.insert(self.shakes, {vec=vec, t=dur, dur=dur, falloff=falloff_funcs[falloff]})
end

local function stop_shaking(self) -- clears all shakes and recoils
	for i, v in ipairs(self.shakes) do self.shakes[i] = nil end
end

-- following requires 'obj' to have a property 'pos' with 'x' and 'y' properties
local function follow(self, obj, allowMultiFollow, weight, deadzone)
	weight = weight or 1
	-- using object table as key
	if self.follows[obj] then -- already following, update weight & deadzone
		self.follows[obj].weight = weight
		if deadzone and type(deadzone) == "table" then
			if self.follows[obj].deadzone then -- update existing deadzone
				for k, v in pairs(deadzone) do self.follows[obj][k] = v end
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
		for k, v in pairs(self.follows) do
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

local function unfollow(self, obj)
	if obj and self.follows[obj] then -- remove specified object from list
		self.follows[obj] = nil
		self.follow_count = self.follow_count - 1
	else -- no object specified, clear follows
		for k, v in pairs(self.follows) do self.follows[k] = nil end
		self.follow_count = 0
	end
end

local function set_bounds(self, lt, rt, top, bot)
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

local bounds_vec_table = { tl=vec2(), tr=vec2(), bl=vec2(), br=vec2() } -- save the GC some work

local function enforce_bounds(self)
	if self.bounds then
		local b = self.bounds
		local vp = self.vp
		local c = bounds_vec_table -- corners
		-- get viewport corner positions in world space
		c.tl.x, c.tl.y = self:screen_to_world(vp.x, vp.y) -- top left
		c.tr.x, c.tr.y = self:screen_to_world(vp.x + vp.w, vp.y) -- top right
		c.bl.x, c.bl.y = self:screen_to_world(vp.x, vp.y + vp.h) -- bottom left
		c.br.x, c.br.y = self:screen_to_world(vp.x + vp.w, vp.y + vp.h) -- bottom right
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

function M.new(pos, angle, zoom_or_area, scale_mode, fixed_aspect_ratio, inactive)
	local win_x, win_y = love.graphics.getDimensions()
	scale_mode = scale_mode or "fixed area"

	local n = {
		-- User Settings:
		active = not inactive,
		pos = pos and vec2(pos.x, pos.y) or vec2(0, 0),
		sx = 1, sy = 1, kx = 0, ky = 0,
		angle = angle or 0,
		zoom = 1,
		scale_mode = scale_mode,
		aspect_ratio = fixed_aspect_ratio,

		-- functions, state properties, etc.
		apply_transform = apply_transform,
		reset_transform = reset_transform,
		win = vec2(win_x, win_y),
		half_win = vec2(win_x/2, win_y/2),
		win_resized = win_resized,
		screen_to_world = screen_to_world,
		world_to_screen = world_to_screen,
		activate = activate,
		pan = pan,
		zoom_in = zoom_in,
		update = update,
		shake = shake,
		shakes = {},
		recoil = recoil,
		stop_shaking = stop_shaking,
		shake_x = 0,
		shake_y = 0,
		follow = follow,
		follows = {},
		follow_count = 0,
		unfollow = unfollow,
		follow_lerp_speed = 3,
		set_bounds = set_bounds,
		enforce_bounds = enforce_bounds
	}
	-- Fixed aspect ratio - get viewport/scissor
	local vp = {}
	if fixed_aspect_ratio then
		vp.x, vp.y, vp.w, vp.h = get_aspect_rect_in_win(n.aspect_ratio, win_x, win_y)
	else
		vp.x, vp.y, vp.w, vp.h = 0, 0, win_x, win_y
	end
	n.vp = vp

	-- Zoom
	local vx, vy = get_zoom_or_area(zoom_or_area)
	if not vx then
		error("Lovercam - M.new() - invalid zoom or area: " .. tostring(zoom_or_area))
	elseif vx and not vy then -- user supplied a zoom value, keep this zoom no matter what
		n.zoom = vx
	else -- user supplied a view area - use this with scale_mode and viewport to find zoom
		-- Want initial zoom to respect user settings. Even if "expand view" mode is used,
		-- we want to zoom so the specified area fits the window. Use "fixed area" mode
		-- instead to get a nice fit regardless of proportion differences.
		local sm = scale_mode == "expand view" and "fixed area" or scale_mode
		n.zoom = get_zoom_for_new_window(1, sm, vx, vy, n.vp.w, n.vp.h)
	end

	if n.active then M.cur_cam = n end
	table.insert(cameras, n)
	return n
end

local fallback_cam = M.new(vec2(love.graphics.getDimensions())/2)
M.cur_cam = fallback_cam

return M

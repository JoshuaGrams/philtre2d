local base = (...):gsub('[^%.]+$', '')
local Column = require(base .. 'Column')

local Row = Column:extend()
Row.className = "Row"

function Row._getChildDesire(self, child)
	-- Row allocates based on child desire, but child desire can change based on
	-- the alloc that it hasn't gotten yet (like scale). Desire is only set in
	-- .updateSize(), so call that with our full alloc (an imperfect workaround).
	if child.modeSetsDesire[child.modeX] then child:call('updateSize', self.lastAlloc:unpack()) end
	local desiredW, _ = child:request()
	return desiredW
end

function Row._getMainDistances(self, x, y, w, h, scale)
	return x + (self.isReversed and w or 0), w
end

function Row._getCrossDistances(self, x, y, w, h, scale)
	return y, h
end

function Row._alloc(child, mainDist, mainLen, crossDist, crossLen, scale)
	-- Row cross axis is Y, main axis is X.
	child:call('allocate', mainDist, crossDist, mainLen, crossLen, scale)
end

return Row

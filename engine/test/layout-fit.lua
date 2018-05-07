local T = require 'lib.simple-test'

local Layout = require 'engine.layout'

local fitSize = {
	"Fit Size",
	setup = function()
		local child = Layout.Box(4, 3)
		return {
			child = child,
			fit = Layout.Fit('size', child)
		}
	end,
	function(obj)
		obj.fit:allocate(22, 11, 4, 3)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 4, height = 3
		}, "fits exactly", 'child')
	end,
	function(obj)
		obj.fit:allocate(22, 11, 3, 3)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 3, height = 3
		}, "truncate width", 'child')
	end,
	function(obj)
		obj.fit:allocate(22, 11, 4, 2)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 4, height = 2
		}, "truncate height", 'child')
	end,
	function(obj)
		obj.fit:allocate(22, 11, 3, 2)
		T.has(obj.child, {
			pos = { x = 0, y = 0, }, width = 3, height = 2
		}, "truncate both dimensions", 'child')
	end,
	function(obj)
		obj.fit:allocate(22, 11, 8, 2)
		T.has(obj.child, {
			pos = { x = 2, y = 0 }, width = 4, height = 2
		}, "pad width, truncate height", 'child')
	end,
	function(obj)
		obj.fit:allocate(22, 11, 8, 6)
		T.has(obj.child, {
			pos = { x = 2, y = 1.5 }, width = 4, height = 3
		}, "pad both dimensions", 'child')
	end
}

local fitSizeLeftBottom = {
	"Fit Size (space on left and bottom)",
	setup = function()
		local child = Layout.Box(4, 3)
		local left = Layout.Box(6, 6)
		local bottom = Layout.Box(9, 9)
		return {
			child = child,
			left = left, bottom = bottom,
			fit = Layout.Fit('size', child, {
				left = left, bottom = bottom
			})
		}
	end,
	function(obj)
		obj.fit:allocate(7, 8, 4, 3)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 4, height = 3
		}, "fits exactly", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 0, height = 3
		}, "no space on left", 'left')
		T.has(obj.bottom, {
			pos = { x = 0, y = 3 }, width = 4, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(7, 8, 3, 3)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 3, height = 3
		}, "truncates width", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 0, height = 3
		}, "no space on left", 'left')
		T.has(obj.bottom, {
			pos = { x = 0, y = 3 }, width = 3, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(7, 8, 4, 2)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 4, height = 2
		}, "truncates width", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 0, height = 2
		}, "no space on left", 'left')
		T.has(obj.bottom, {
			pos = { x = 0, y = 2 }, width = 4, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(7, 8, 8, 7)
		T.has(obj.child, {
			pos = { x = 4, y = 0 }, width = 4, height = 3
		}, "space on left and bottom", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 4, height = 7
		}, "space on left", 'left')
		T.has(obj.bottom, {
			pos = { x = 4, y = 3 }, width = 4, height = 4
		}, "space on bottom", 'bottom')
	end
}

local fitSizeBoth = {
	"Fit Size (space at all four edges)",
	setup = function()
		local child = Layout.Box(4, 3)
		local left = Layout.Box(6, 6)
		local right = Layout.Box(7, 7)
		local top = Layout.Box(8, 8)
		local bottom = Layout.Box(9, 9)
		return {
			child = child,
			left = left, right = right,
			top = top, bottom = bottom,
			fit = Layout.Fit('size', child, {
				left = left, right = right,
				top = top, bottom = bottom
			})
		}
	end,
	function(obj)
		obj.fit:allocate(7, 8, 4, 3)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 4, height = 3
		}, "fits exactly", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 0, height = 3
		}, "no space on left", 'left')
		T.has(obj.right, {
			pos = { x = 4, y = 0 }, width = 0, height = 3
		}, "no space on right", 'right')
		T.has(obj.top, {
			pos = { x = 0, y = 0 }, width = 4, height = 0
		}, "no space on top", 'top')
		T.has(obj.bottom, {
			pos = { x = 0, y = 3 }, width = 4, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(7, 8, 3, 3)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 3, height = 3
		}, "truncates width", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 0, height = 3
		}, "no space on left", 'left')
		T.has(obj.right, {
			pos = { x = 3, y = 0 }, width = 0, height = 3
		}, "no space on right", 'right')
		T.has(obj.top, {
			pos = { x = 0, y = 0 }, width = 3, height = 0
		}, "no space on top", 'top')
		T.has(obj.bottom, {
			pos = { x = 0, y = 3 }, width = 3, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(7, 8, 4, 2)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 4, height = 2
		}, "truncates width", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 0, height = 2
		}, "no space on left", 'left')
		T.has(obj.right, {
			pos = { x = 4, y = 0 }, width = 0, height = 2
		}, "no space on right", 'right')
		T.has(obj.top, {
			pos = { x = 0, y = 0 }, width = 4, height = 0
		}, "no space on top", 'top')
		T.has(obj.bottom, {
			pos = { x = 0, y = 2 }, width = 4, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(7, 8, 8, 7)
		T.has(obj.child, {
			pos = { x = 2, y = 2 }, width = 4, height = 3
		}, "space all 'round", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 2, height = 7
		}, "space on left", 'left')
		T.has(obj.right, {
			pos = { x = 6, y = 0 }, width = 2, height = 7
		}, "space on right", 'right')
		T.has(obj.top, {
			pos = { x = 2, y = 0 }, width = 4, height = 2
		}, "space on top", 'top')
		T.has(obj.bottom, {
			pos = { x = 2, y = 5 }, width = 4, height = 2
		}, "space on bottom", 'bottom')
	end
}

local fitWidth = {
	"Fit Width",
	setup = function()
		local child = Layout.Box(4, 3)
		return {
			child = child,
			fit = Layout.Fit('width', child)
		}
	end,
	function(obj)
		obj.fit:allocate(7, 9, 8, 6)
		local expect = {
			pos = {x = 0, y = 0 },
			width = 8, height = 6
		}
		T.has(obj.child, expect, "fits exactly", 'child')
	end,
	function(obj)
		obj.fit:allocate(7, 9, 10, 6)
		local expect = {
			pos = {x = 0, y = 0 },
			width = 10, height = 6
		}
		T.has(obj.child, expect, "truncates height", 'child')
	end,
	function(obj)
		obj.fit:allocate(7, 9, 6, 6)
		local expect = {
			pos = { x = 0, y = 0.75 },
			width = 6, height = 4.5
		}
		T.has(obj.child, expect, "pads height", 'child')
	end
}

local fitWidthBefore = {
	"Fit Width to Bottom",
	setup = function()
		local child = Layout.Box(4, 3)
		local before = Layout.Box(0, 0)
		return {
			child = child, before = before,
			fit = Layout.Fit('width', child, { top = before })
		}
	end,
	function(obj)
		obj.fit:allocate(7, 9, 8, 6)
		T.has(obj.child, {
			pos = {x = 0, y = 0 },
			width = 8, height = 6
		}, "fits exactly", 'child')
		T.has(obj.before, {
			pos = {x = 0, y = 0 }, width = 8, height = 0
		}, "empty", 'before')
	end,
	function(obj)
		obj.fit:allocate(7, 9, 10, 6)
		T.has(obj.child, {
			pos = {x = 0, y = 0 },
			width = 10, height = 6
		}, "truncates height", 'child')
		T.has(obj.before, {
			pos = {x = 0, y = 0 }, width = 10, height = 0
		}, "empty", 'before')
	end,
	function(obj)
		obj.fit:allocate(7, 9, 6, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 1.5 },
			width = 6, height = 4.5
		}, "pads height", 'child')
		T.has(obj.before, {
			pos = {x = 0, y = 0 }, width = 6, height = 1.5
		}, "empty", 'before')
	end
}

local fitWidthAfter = {
	"Fit Width to Top",
	setup = function()
		local child = Layout.Box(4, 3)
		local before = Layout.Box(0, 0)
		return {
			child = child, before = before,
			fit = Layout.Fit('width', child, { bottom = before })
		}
	end,
	function(obj)
		obj.fit:allocate(7, 9, 8, 6)
		T.has(obj.child, {
			pos = {x = 0, y = 0 },
			width = 8, height = 6
		}, "fits exactly", 'child')
		T.has(obj.before, {
			pos = {x = 0, y = 6 }, width = 8, height = 0
		}, "empty", 'before')
	end,
	function(obj)
		obj.fit:allocate(7, 9, 10, 6)
		T.has(obj.child, {
			pos = {x = 0, y = 0 },
			width = 10, height = 6
		}, "truncates height", 'child')
		T.has(obj.before, {
			pos = {x = 0, y = 6 }, width = 10, height = 0
		}, "empty", 'before')
	end,
	function(obj)
		obj.fit:allocate(7, 9, 6, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 },
			width = 6, height = 4.5
		}, "pads height", 'child')
		T.has(obj.before, {
			pos = {x = 0, y = 4.5 }, width = 6, height = 1.5
		}, "empty", 'before')
	end
}

local fitWidthBoth = {
	"Fit Width (space on top and bottom)",
	setup = function()
		local child = Layout.Box(4, 3)
		local before = Layout.Box(7, 7)
		local after = Layout.Box(3, 5)
		return {
			child = child, before = before, after = after,
			fit = Layout.Fit('width', child, {
				top = before, bottom = after
			})
		}
	end,
	function(obj)
		obj.fit:allocate(7, 9, 8, 6)
		T.has(obj.child, {
			pos = {x = 0, y = 0 },
			width = 8, height = 6
		}, "fits exactly", 'child')
		T.has(obj.before, {
			pos = { x = 0, y = 0 }, width = 8, height = 0
		}, "no space on top", 'top')
		T.has(obj.after, {
			pos = { x = 0, y = 6 }, width = 8, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(7, 9, 10, 6)
		T.has(obj.child, {
			pos = {x = 0, y = 0 },
			width = 10, height = 6
		}, "truncates height", 'child')
		T.has(obj.before, {
			pos = { x = 0, y = 0 }, width = 10, height = 0
		}, "no space on top", 'top')
		T.has(obj.after, {
			pos = { x = 0, y = 6 }, width = 10, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(7, 9, 8, 8)
		T.has(obj.child, {
			pos = { x = 0, y = 1 }, width = 8, height = 6
		}, "pads height", 'child')
		T.has(obj.before, {
			pos = { x = 0, y = 0 }, width = 8, height = 1
		}, "space on top", 'top')
		T.has(obj.after, {
			pos = { x = 0, y = 7 }, width = 8, height = 1
		}, "space on bottom", 'bottom')
	end
}

local fitHeight = {
	"Fit Height",
	setup = function()
		local child = Layout.Box(4, 3)
		return {
			child = child,
			fit = Layout.Fit('height', child)
		}
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 8, height = 6
		}, "fits exactly", 'child')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 6, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 6, height = 6
		}, "truncates width", 'child')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 10, 6)
		T.has(obj.child, {
			pos = { x = 1, y = 0 }, width = 8, height = 6
		}, "pads width", 'child')
	end
}

local fitHeightBefore = {
	"Fit Height to Right",
	setup = function()
		local child = Layout.Box(4, 3)
		local before = Layout.Box(10, 10)
		return {
			child = child, before = before,
			fit = Layout.Fit('height', child, { left = before })
		}
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 8, height = 6
		}, "fits exactly", 'child')
		T.has(obj.before, {
			pos = { x = 0, y = 0 }, width = 0, height = 6
		}, "spacer is empty", 'left')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 6, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 6, height = 6
		}, "truncates width", 'child')
		T.has(obj.before, {
			pos = { x = 0, y = 0 }, width = 0, height = 6
		}, "spacer is empty", 'left')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 10, 6)
		T.has(obj.child, {
			pos = { x = 2, y = 0 }, width = 8, height = 6
		}, "pads width", 'child')
		T.has(obj.before, {
			pos = { x = 0, y = 0 }, width = 2, height = 6
		}, "extra space is on left", 'left')
	end
}

local fitHeightAfter = {
	"Fit Height to Left",
	setup = function()
		local child = Layout.Box(4, 3)
		local after = Layout.Box(10, 10)
		return {
			child = child, after = after,
			fit = Layout.Fit('height', child, { right = after })
		}
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 8, height = 6
		}, "fits exactly", 'child')
		T.has(obj.after, {
			pos = { x = 8, y = 0 }, width = 0, height = 6
		}, "spacer is empty", 'right')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 6, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 6, height = 6
		}, "truncates width", 'child')
		T.has(obj.after, {
			pos = { x = 6, y = 0 }, width = 0, height = 6
		}, "spacer is empty", 'right')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 10, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 8, height = 6
		}, "pads width", 'child')
		T.has(obj.after, {
			pos = { x = 8, y = 0 }, width = 2, height = 6
		}, "extra space is on right", 'right')
	end
}

local fitHeightBoth = {
	"Fit Height (space on both sides)",
	setup = function()
		local child = Layout.Box(4, 3)
		local before = Layout.Box(10, 10)
		local after = Layout.Box(8, 20)
		return {
			child = child, before = before, after = after,
			fit = Layout.Fit('height', child, {
				left = before, right = after
			})
		}
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 8, height = 6
		}, "fits exactly", 'child')
		T.has(obj.before, {
			pos = { x = 0, y = 0 }, width = 0, height = 6
		}, "no space on left", 'left')
		T.has(obj.after, {
			pos = { x = 8, y = 0 }, width = 0, height = 6
		}, "no space on right", 'right')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 6, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 6, height = 6
		}, "truncates width", 'child')
		T.has(obj.before, {
			pos = { x = 0, y = 0 }, width = 0, height = 6
		}, "no space on left", 'left')
		T.has(obj.after, {
			pos = { x = 6, y = 0 }, width = 0, height = 6
		}, "no space on right", 'right')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 10, 6)
		T.has(obj.child, {
			pos = { x = 1, y = 0 }, width = 8, height = 6
		}, "pads width", 'child')
		T.has(obj.before, {
			pos = { x = 0, y = 0 }, width = 1, height = 6
		}, "no space on left", 'left')
		T.has(obj.after, {
			pos = { x = 9, y = 0 }, width = 1, height = 6
		}, "no space on right", 'right')
	end
}

local fitAspect = {
	"Fit Aspect Ratio",
	setup = function()
		local child = Layout.Box(4, 3)
		return {
			child = child,
			fit = Layout.Fit('aspect', child)
		}
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 8, height = 6
		}, "fits exactly", 'child')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 10, 6)
		T.has(obj.child, {
			pos = { x = 1, y = 0 }, width = 8, height = 6
		}, "space on left/right", 'child')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 8)
		T.has(obj.child, {
			pos = { x = 0, y = 1 }, width = 8, height = 6
		}, "space on top/bottom", 'child')
	end
}

local fitAspectLeftBottom = {
	"Fit Aspect Ratio (space on left or bottom)",
	setup = function()
		local child = Layout.Box(4, 3)
		local left = Layout.Box(6, 6)
		local bottom = Layout.Box(9, 9)
		return {
			child = child,
			left = left, bottom = bottom,
			fit = Layout.Fit('aspect', child, {
				left = left, bottom = bottom
			})
		}
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 8, height = 6
		}, "fits exactly", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 0, height = 6
		}, "no space on left", 'left')
		T.has(obj.bottom, {
			pos = { x = 0, y = 6 }, width = 8, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 10, 6)
		T.has(obj.child, {
			pos = { x = 2, y = 0 }, width = 8, height = 6
		}, "space on left", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 2, height = 6
		}, "space on left", 'left')
		T.has(obj.bottom, {
			pos = { x = 2, y = 6 }, width = 8, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 8)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 8, height = 6
		}, "space on bottom", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 0, height = 8
		}, "no space on left", 'left')
		T.has(obj.bottom, {
			pos = { x = 0, y = 6 }, width = 8, height = 2
		}, "space on bottom", 'bottom')
	end
}

local fitAspectRightTop = {
	"Fit Aspect Ratio (space on right or top)",
	setup = function()
		local child = Layout.Box(4, 3)
		local right = Layout.Box(6, 6)
		local top = Layout.Box(9, 9)
		return {
			child = child,
			right = right, top = top,
			fit = Layout.Fit('aspect', child, {
				right = right, top = top
			})
		}
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 8, height = 6
		}, "fits exactly", 'child')
		T.has(obj.right, {
			pos = { x = 8, y = 0 }, width = 0, height = 6
		}, "no space on right", 'right')
		T.has(obj.top, {
			pos = { x = 0, y = 0 }, width = 8, height = 0
		}, "no space on top", 'top')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 10, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 8, height = 6
		}, "space on right", 'child')
		T.has(obj.right, {
			pos = { x = 8, y = 0 }, width = 2, height = 6
		}, "space on right", 'right')
		T.has(obj.top, {
			pos = { x = 0, y = 0 }, width = 8, height = 0
		}, "no space on top", 'top')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 8)
		T.has(obj.child, {
			pos = { x = 0, y = 2 }, width = 8, height = 6
		}, "space on top", 'child')
		T.has(obj.right, {
			pos = { x = 8, y = 0 }, width = 0, height = 8
		}, "no space on right", 'right')
		T.has(obj.top, {
			pos = { x = 0, y = 0 }, width = 8, height = 2
		}, "space on top", 'top')
	end
}

local fitAspectBoth = {
	"Fit Aspect Ratio (space on both ends)",
	setup = function()
		local child = Layout.Box(4, 3)
		local left = Layout.Box(6, 6)
		local right = Layout.Box(7, 7)
		local top = Layout.Box(8, 8)
		local bottom = Layout.Box(9, 9)
		return {
			child = child,
			left = left, right = right,
			top = top, bottom = bottom,
			fit = Layout.Fit('aspect', child, {
				left = left, right = right,
				top = top, bottom = bottom
			})
		}
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 6)
		T.has(obj.child, {
			pos = { x = 0, y = 0 }, width = 8, height = 6
		}, "fits exactly", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 0, height = 6
		}, "no space on left", 'left')
		T.has(obj.right, {
			pos = { x = 8, y = 0 }, width = 0, height = 6
		}, "no space on right", 'right')
		T.has(obj.top, {
			pos = { x = 0, y = 0 }, width = 8, height = 0
		}, "no space on top", 'top')
		T.has(obj.bottom, {
			pos = { x = 0, y = 6 }, width = 8, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 10, 6)
		T.has(obj.child, {
			pos = { x = 1, y = 0 }, width = 8, height = 6
		}, "space on left/right", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 1, height = 6
		}, "space on left", 'left')
		T.has(obj.right, {
			pos = { x = 9, y = 0 }, width = 1, height = 6
		}, "space on right", 'right')
		T.has(obj.top, {
			pos = { x = 1, y = 0 }, width = 8, height = 0
		}, "no space on top", 'top')
		T.has(obj.bottom, {
			pos = { x = 1, y = 6 }, width = 8, height = 0
		}, "no space on bottom", 'bottom')
	end,
	function(obj)
		obj.fit:allocate(3, 5, 8, 8)
		T.has(obj.child, {
			pos = { x = 0, y = 1 }, width = 8, height = 6
		}, "space on top/bottom", 'child')
		T.has(obj.left, {
			pos = { x = 0, y = 0 }, width = 0, height = 8
		}, "no space on left", 'left')
		T.has(obj.right, {
			pos = { x = 8, y = 0 }, width = 0, height = 8
		}, "no space on right", 'right')
		T.has(obj.top, {
			pos = { x = 0, y = 0 }, width = 8, height = 1
		}, "space on top", 'top')
		T.has(obj.bottom, {
			pos = { x = 0, y = 7 }, width = 8, height = 1
		}, "space on bottom", 'bottom')
	end
}

return {
	"Layout: Box Fitting",
	fitSize, fitSizeLeftBottom, fitSizeBoth,
	fitWidth, fitWidthBefore, fitWidthAfter, fitWidthBoth,
	fitHeight, fitHeightBefore, fitHeightAfter, fitHeightBoth,
	fitAspect, fitAspectLeftBottom, fitAspectRightTop, fitAspectBoth
}

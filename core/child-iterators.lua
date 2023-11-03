
-- Iterators for scene-tree child lists.

local function _stateless_child_iter(children, i)
	local child
	local len = children.maxn
	repeat
		i = i + 1
		child = children[i]
	until child or i >= len
	if i <= len then  return i, child  end
end

-- Ipairs-style iterator: `for i,child in everychild(children) do`
local function everychild(children)
	if not children.maxn then  children.maxn = #children  end
	return _stateless_child_iter, children, 0
end

-- Loop that calls a function for each child.
local function forchildin(children, fn)
	for i=1,children.maxn or #children do
		local child = children[i]
		if child then
			fn(i, child)
		end
	end
end

-- Make global
_G.everychild = everychild
_G.forchildin = forchildin

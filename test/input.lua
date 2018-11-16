local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require 'lib.simple-test'

local input = require(base .. 'input')

local ltClickBinding = { 'left click', 'button', 'mouse', 1 }

local cb = function(self, name, val, change)
   self.lastInput = { name = name, value = val, change = change }
end
local obj = {
   call = function(self, funcName, ...)  self[funcName](self, ...)  end,
   input = cb,
   lastInput = nil
}

return {
   "Input",
   function()
      input.init()
      input.bind({ ltClickBinding })
      local inputGet = input.get('left click')
      T.ok(type(inputGet) == 'table', 'input.get() result is a table.')
      T.has(inputGet, { name='left click', value=0, change=0 }, 'input.get() result has correct key and value.')

      local b, msg = pcall(input.unbind)
      T.ok(b==false and type(msg)=='string' and string.find(msg, 'Input.unbind -'), 'Wrong arg (nil) to input.unbind() gives custom error message.')
      local b, msg = pcall(input.unbind, {'left click'})
      T.ok(b==false and type(msg)=='string' and string.find(msg, 'Input.unbind -'), 'Wrong arg (single table) to input.unbind() gives custom error message.')

      input.unbind({{'left click'}})
      T.ok(input.get('left click') == nil, 'After unbinding input. New input.get() is nil.')

      input.enable(obj)
      love.mousepressed(0, 0, 1) -- x, y, button
      T.is(obj.lastInput, nil, 'Object did not get callback for unbound input.')

      input.bind({ {'action1', 'button', 'mouse', 1} })
      love.mousepressed(0, 0, 1)
      T.has(obj.lastInput, { name='action1', value=1, change=1 }, 'Rebound same physical input to different name. Obj gets correct input.')

      obj.lastInput = nil
      input.unbind({ {'action1'} })
      T.ok(input.get('action1') == nil, 'After unbinding input. New input.get() is nil.')
      love.mousepressed(0, 0, 1)
      T.is(obj.lastInput, nil, 'Object did not get callback for unbound input.')

      T.ok(pcall(input.unbind, {{'arglefraster'}}), 'Unbind bogus action name "arglefraster" without errors.')

      input.bind({ ltClickBinding, {'action1', 'button', 'mouse', 1} })
      input.unbind_all()
      T.ok(input.get('action1')==nil and input.get('left click')==nil, 'After unbind_all(), both input.get()s return nil.')
      love.mousepressed(0, 0, 1)
      T.is(obj.lastInput, nil, 'After unbind_all(), object did not get callback for any input.')
   end
}

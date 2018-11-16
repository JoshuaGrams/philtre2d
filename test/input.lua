local base = (...):gsub('[^%.]+.[^%.]+$', '')
local T = require 'lib.simple-test'

local input = require(base .. 'input')

local ltClickBinding = { 'left click', 'button', 'mouse', 1 }
local binding1 = { 'action1', 'button', 'key', 'a' }
local binding2 = { 'action2', 'button', 'key', 'o' }
local binding3 = { 'action3', 'button', 'key', 'e' }

local cb = function(self, name, val, change)
   self.inputCount = self.inputCount + 1
   self.lastInput = { name = name, value = val, change = change }
end
local obj = {
   call = function(self, funcName, ...)  self[funcName](self, ...)  end,
   input = cb,
   lastInput = nil,
   inputCount = 0
}

return {
   "Input",
   function()
      input.init()
      input.bind({ ltClickBinding })
      local inputGet = input.get('left click')
      T.ok(type(inputGet) == 'table', 'input.get() result is a table.')
      T.has(inputGet, { name='left click', value=0, change=0 }, 'input.get() result has correct key and value.')

      local isErr, msg = pcall(input.unbind)
      T.ok(isErr==false and type(msg)=='string' and string.find(msg, 'Input.unbind -'), 'Wrong arg (nil) to input.unbind() fails with custom error message.')
      isErr, msg = pcall(input.unbind, { 'text', 3.5 })
      T.ok(isErr==false and type(msg)=='string' and string.find(msg, 'Input._unbind -'), 'Non-string name to input._unbind() fails with custom error message.')

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
      T.is(obj.lastInput, nil, 'Object did not get callback for unbound input (different logical, same physical).')

      T.ok(pcall(input.unbind, {{'arglefraster'}}), 'Unbind bogus action name "arglefraster" without errors.')

      input.bind({ ltClickBinding, {'action1', 'button', 'mouse', 1} })
      input.unbind_all()
      T.ok(input.get('action1')==nil and input.get('left click')==nil, 'After unbind_all(), both input.get()s return nil.')
      love.mousepressed(0, 0, 1)
      T.is(obj.lastInput, nil, 'After unbind_all(), object did not get callback for any input.')

      input.bind({ {'action1', 'button', 'mouse', 1} })
      input.bind({ {'action1', 'button', 'key', 'up'} }, true) -- replace old
      obj.inputCount = 0
      love.mousepressed(0, 0, 1)
      T.is(obj.inputCount, 0, 'Object did\'t respond to original input after it was overwritten with replace_old=true.')
      obj.inputCount = 0
      love.keypressed('up')
      T.is(obj.inputCount, 1, 'Object got new input that replaced old.')
      input.unbind_all()

      isErr, msg = pcall(input.bind, { binding1, binding1 })
      T.ok(isErr==false and type(msg)=='string' and string.find(msg, 'Input.bind -'), 'Using duplicate action name with replace_old=true fails with custom error message.')
      input.unbind_all()

      local b = { binding1, binding2, binding3 }
      input.bind(b)
      input.unbind(b)
      obj.inputCount = 0
      love.keypressed('a');  love.keypressed('o');  love.keypressed('e')
      T.ok(obj.inputCount==0, 'Unbinding with table of tables works.')

      input.bind(b)
      input.unbind({ 'action1', 'action2', 'action3' })
      obj.inputCount = 0
      love.keypressed('a');  love.keypressed('o');  love.keypressed('e')
      T.ok(obj.inputCount==0, 'Unbinding with table of names works.')

      input.bind(b)
      input.unbind('action1');  input.unbind('action2');  input.unbind('action3')
      obj.inputCount = 0
      love.keypressed('a');  love.keypressed('o');  love.keypressed('e')
      T.ok(obj.inputCount==0, 'Unbinding individual names works.')
   end
}

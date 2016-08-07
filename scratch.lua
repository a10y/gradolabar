util = require 'util'
local trueSource = [[
   local f = function(a)
      if a > 3 then
         return a + 1
      else
         return a - 1
      end
   end
]]
ast = util.sourceToAst(trueSource)
util.astprint(ast)

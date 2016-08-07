util = require 'util'
trueSource = [[
local function f(a)
   return a
end
]]
src = util.astToSource(util.sourceToAst(trueSource))
print(src)
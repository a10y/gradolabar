util = require 'util'
trueSource = [[
function f(a)
   return a
end
]]
ast = util.sourceToAst(trueSource)
util.astprint(ast)

local serializer = require 'serializer'
local debug = require 'debug'
local parser = require "lua-parser.parser"
local pp = require "lua-parser.pp"

local function getfnsource(f)
   fn_info = debug.getinfo(f)
   lines = {}
   iline = 0
   src = ""
   for line in io.lines(fn_info.short_src) do
      iline = iline + 1
      if (fn_info.linedefined <= iline) and (iline <= fn_info.lastlinedefined) then
         src = src .. line .. "\n"
      end
   end
   return src
end

return {
   functionToSource = getfnsource,
   sourceToAst = parser.parse,
   astToSource = serializer.ast_to_code,
   astprint = function(src) print(pp.tostring(src)) end
}
-- print(lineExtents)

-- print("======================================")
-- print(src)
-- print("======================================")
-- print(pp.tostring(ast))
-- print("======================================")
-- print(serializer.ast_to_code(ast))
-- print("======================================")

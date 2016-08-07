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

local function checkAst(ast, checkFn)
   -- Check we've hit an AST node
   if type(ast) ~= "table" or not ast.tag then
      return false
   end

   -- If the check function evaluates true, we're good
   if checkFn(ast) then
      return true

   -- Otherwise, walk the node
   else
      for i=1,#ast do
         if checkAst(ast[i], checkFn) then
            return true
         end
      end
      return false
   end
end

local function sourceToAst(src)
   local ast = parser.parse(src)

   -- TODO
   -- Check that we don't have two function definitions on the same line
   -- (the `debug` module in lua only provides line numbers, not text columns,
   -- so we can't determine which function's source we want if they're in the same line)
   return ast
end

local function checkForControlFlow(ast)

end

return {
   functionToSource = getfnsource,
   sourceToAst = parser.parse,
   checkAst = checkAst,
   astToSource = serializer.ast_to_code,
   astprint = function(src) print(pp.tostring(src)) end
}
local serializer = require 'serializer'
local debug = require 'debug'
local parser = require "lua-parser.parser"
local pp = require "lua-parser.pp"

local function getvarvalue (name)
   -- TODO: NOT WORKY
   -- -- From: https://www.lua.org/pil/23.1.2.html
   -- local value, found

   -- -- try local variables
   -- local i = 1
   -- while true do
   --    local n, v = debug.getlocal(2, i)
   --    if not n then break end
   --    if n == name then
   --       value = v
   --       found = true
   --    end
   --    i = i + 1
   -- end
   -- if found then return value end

   -- -- try upvalues
   -- local func = debug.getinfo(2).func
   -- i = 1
   -- while true do
   --    local n, v = debug.getupvalue(func, i)
   --    if not n then break end
   --    if n == name then return v end
   --    i = i + 1
   -- end

   -- not found; get global
   return _G[name]
end

local function getfnsource(f)
   -- TODO: at first occurence of keyword "function", check for a 2nd occurrence on same line
   local fn_info = debug.getinfo(f)
   local lines = {}
   local iline = 0
   local src = ""
   for line in io.lines(fn_info.short_src) do
      iline = iline + 1
      local seenFnDef = false
      if (fn_info.linedefined <= iline) and (iline <= fn_info.lastlinedefined) then
         if not seenFnDef then
            local _, count = string.gsub(line, "function", "")
            if count == 1 then
               seenFnDef = true
            elseif count > 1 then
               local errstring = "The use of the keyword 'function' is only allowable once per line in this utility"
               errstring = errstring .. "\n" .. " (limitations of Lua's function introspection capabilities)"
               error(errstring)
            end
         end
         src = src .. line .. "\n"
      end
   end
   return src
end

local function isAstNode(node)
   if type(node) == "table" and type(node.tag) == "string" then
      return true
   else
      return false
   end
end

local function checkAst(ast, checkFn)
   -- Check we've hit an AST node
   if isAstNode(ast) == false then
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

-- TODO:
-- Issue here is we can mutate a node in place in mutateFn and it
-- it will still be placed in. Maybe that's not a problem? Feature not a bug?
local function mutateAst(ast, mutateFn)
   if isAstNode(ast) then
      ast = mutateFn(ast) or ast -- if it returns nil, use the original node
   else
      return ast
   end
   for i=1,#ast do
      ast[i] = mutateAst(ast[i], mutateFn)
   end
   return ast
end

local function checkForControlFlow(ast)

end

return {
   functionToSource = getfnsource,
   getVarByName = getvarvalue,
   sourceToAst = parser.parse,
   checkAst = checkAst,
   mutateAst = mutateAst,
   astToSource = serializer.ast_to_code,
   astprint = function(src) print(pp.tostring(src)) end
}
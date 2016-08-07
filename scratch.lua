local function trim(s)
  -- from PiL2 20.4
  return s:gsub("^%s*(.-)%s*$", "%1"):gsub("%s+", " ")
end

util = require 'util'
local src = [[
a = 3
b = 4
c = 5
]]

local incrSrc = [[
a = 4
b = 5
c = 6
]]

local reversedSrc = [[
c = 5
b = 4
a = 3
]]


-- Identity function
local ast = util.sourceToAst(src)
util.astprint(ast)
local ast = util.mutateAst(ast, function(node) return node end)
local ast = util.mutateAst(ast, function(node) return nil end)
util.astprint(ast)

-- A simple transform
local ast = util.sourceToAst(src)
local incrNumber = function(node)
   if node.tag == "Number" then
      node[1] = node[1] + 1
   end
   return node
end
local ast = util.mutateAst(ast, incrNumber)
local newSrc = util.astToSource(ast)
print(trim(newSrc) == trim(incrSrc))
util.astprint(ast)

-- Reversing a block
local ast = util.sourceToAst(src)
local reverseBlock = function(node)
   if node.tag == "Block" then
      newOrder = {}
      for i=#node,1,-1 do
         newOrder[#newOrder+1] = node[i]
      end
      for i=1,#node do
         node[i] = newOrder[i]
      end
   end
end
local ast = util.mutateAst(ast, reverseBlock)
local newSrc = util.astToSource(ast)
print(trim(newSrc) == trim(reversedSrc))

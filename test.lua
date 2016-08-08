local torch = require 'torch'
local util = require 'util'
local tester = torch.Tester()

local function trim(s)
  -- from PiL2 20.4
  return s:gsub("^%s*(.-)%s*$", "%1"):gsub("%s+", " ")
end

-- List of tests:
local tests = {

   GetFunctionSource = function()

      local function f(a,b,c)
         return a*b+c
      end

      local trueSource = [[
      local function f(a,b,c)
         return a*b+c
      end
]]

      tester:assert(trueSource == util.functionToSource(f), "Incorrect function source")

      local f = function(a,b,c)
         return a*b+c
      end

      local trueSource = [[
      local f = function(a,b,c)
         return a*b+c
      end
]]
      tester:assert(trueSource == util.functionToSource(f), "Incorrect function source")

      local function g(fn)
         return util.functionToSource(fn)
      end
      tester:assert(trueSource == g(f), "Incorrect function source")

      -- TODO
      -- We're just cutting out the function at the line number
      -- We should also cut it out at the column it was defined.

   end,

   GetAST = function()
      local trueSource = [[
      local function f(a)
         return a
      end
]]
      local ast = util.sourceToAst(trueSource)
      ast = ast[1]
      tester:assert(ast[1][1].tag == "Id", "Incorrect node type")
      tester:assert(ast[1][1][1] == "f", "Incorrect parsed function name")
      local fnAst = ast[2][1]
      tester:assert(fnAst[1][1][1] == "a", "Incorrect argument name")
      tester:assert(fnAst[1][1].tag == "Id", "Incorrect parsed function argument type")
      tester:assert(fnAst[1].tag == "NameList", "Incorrect parsed node type")
      tester:assert(fnAst[2].tag == "Block", "Incorrect parsed node type")
      tester:assert(fnAst[2][1][1].tag == "Id", "Incorrect parsed node type")
      tester:assert(fnAst[2][1].tag == "Return", "Incorrect parsed node type")
      tester:assert(fnAst[2][1][1][1] == "a", "Incorrect return variable content")

   end,

   SerializeAST = function()
      local trueSource = [[
      local f = function(a)
         return a
      end
]]

      local src = util.astToSource(util.sourceToAst(trueSource))
      tester:assert(trim(src)==trim(trueSource), "Didn't transform correctly)")

      local trueSource = [[
      local function f(a)
         return a
      end
]]
      local src = util.astToSource(util.sourceToAst(trueSource))
      tester:assert(trim(src)==trim(trueSource), "Didn't transform correctly)")

   end,

   CheckForControlFlow = function()
      local src1 = [[
      local f = function(a)
         if a > 3 then
            return a + 1
         else
            return a - 1
         end
      end
   ]]
      local src2 = [[
      local f = function(a)
         return a + 1
      end
   ]]
      local src3 = [[
      local f = function(a)
         for i=1,3 do
            a = a + i
         end
         return a
      end
   ]]
      local ast1 = util.sourceToAst(src1)
      local ast2 = util.sourceToAst(src2)
      local ast3 = util.sourceToAst(src3)

      local function checkFn(node, nodeType)
         if node.tag == nodeType then
            return true
         else
            return false
         end
      end

      local function buildCallback(nodeType)
         return function(node)
            return checkFn(node, nodeType)
         end
      end

      tester:assert(util.checkAst(ast1,buildCallback("If"))==true, "No If statement detected")
      tester:assert(util.checkAst(ast2,buildCallback("If"))==false, "If statement detected")
      tester:assert(util.checkAst(ast3,buildCallback("Fornum"))==true, "No Fornum statement detected")
      tester:assert(util.checkAst(ast2,buildCallback("Fornum"))==false, "Fornum statement detected")
   end,

   ForceOneFunctionPerLine = function()
      local fn1 = function() return function(b) return b + 1 end end
      local fn2 = function()
         return function(b) return b + 1 end
      end
      local ok,res = pcall(util.functionToSource, fn1)
      tester:assert(ok==false, "Should not have been able to get function source (two defs in one line")
      local ok,res = pcall(util.functionToSource, fn2)
      tester:assert(ok==true, "Should be able to get function source, they're defined on separate lines")
   end,

   ReverseCallOrder = function()
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
      local ast = util.mutateAst(ast, function(node) return node end)
      tester:assert(trim(util.astToSource(ast))==trim(src), "Incorrect source transform")
      local ast = util.mutateAst(ast, function(node) return nil end)
      tester:assert(trim(util.astToSource(ast))==trim(src), "Incorrect source transform")

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
      tester:assert(trim(newSrc) == trim(incrSrc), "Incorrect source transform (incrementing number values)")

      -- Reversing a block
      local ast = util.sourceToAst(src)
      local reverseBlock = function(node)
         if node.tag == "Block" then
            local newOrder = {}
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
      tester:assert(trim(newSrc) == trim(reversedSrc), "Incorrect source transform (expression order reversal)")
   end,

   FunctionReplacement = function()
      eye = torch.eye
      sum = torch.sum
      max = torch.max
      local src = [[
         local a = eye(3)
         local b = sum(a)
         return b
      ]]
      local modifiedsrc = [[
         local a = zeros(3)
         local b = max(a)
         return b
      ]]

      local fns = {}
      fns[sum] = "max"
      fns[eye] = "zeros"

      local ast = util.sourceToAst(src)
      local replaceFns = function(node)
         if node.tag == "Call" then
            local functionNode = node[1]
            print(util.astToSource(functionNode))
            local fnHandle = util.getVarByName(node[1][1])
            local newFnName = fns[fnHandle]
            if newFnName then
               functionNode[1] = newFnName
               node[1] = functionNode
            end
         end
         return node
      end
      local ast = util.mutateAst(ast, replaceFns)
      local newSrc = util.astToSource(ast)
      print("")
      print(trim(newSrc))
      print(trim(modifiedsrc))
      tester:assert(trim(newSrc) == trim(modifiedsrc), "Incorrect modification of source")
      eye = nil
      sum = nil
      max = nil
   end,

   ANormalForm = function()
      -- TODO: lift all implicit temporary values to have explicit variable names
   end,
}

-- Run tests:
tester:add(tests)
tester:run()




-- neuralNet = function(params, x, y)
--    local h1 = torch.tanh(x * params.W[1] + params.b[1])
--    local h2 = torch.tanh(h1 * params.W[2] + params.b[2])
--    local yHat = h2 - torch.log(torch.sum(torch.exp(h2)))
--    local loss = - torch.sum(torch.cmul(yHat, y))
--    if torch.sum(x) > 0 then
--       return loss * 3.0
--    else
--       return loss
--    end
-- end

-- src = getfnsource(neuralNet)
-- ast = parser.parse(src)

-- lineExtents = {}
-- counter = 1
-- for line in src:gmatch("[^\r\n]+") do
--    lineExtents[#lineExtents+1] = {counter,counter+#line}
--    counter = counter + #line + 1
--    print(src:sub(lineExtents[#lineExtents][1],lineExtents[#lineExtents][2]))
-- end
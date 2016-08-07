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

   -- TODO: This fails ("local function f(a)" signature)
      -- local trueSource = [[
      -- local function f(a)
         -- return a
      -- end
-- ]]
      -- local src = util.astToSource(util.sourceToAst(trueSource))
      -- tester:assert(src, "Didn't transform correctly)")

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
      print(ok==false)
      tester:assert(ok==false, "Should not have been able to get function source (two defs in one line")
      local ok,res = pcall(util.functionToSource, fn2)
      print(ok)
      print(ok==true)
      tester:assert(ok==true, "Should be able to get function source, they're defined on separate lines")
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
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
      -- print(ast)
      -- print(ast[1])
      -- os.exit()
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
--- Phase 4 Tests: Full Integration / API Compatibility
--- Run with: hs.loadSpoon("hs_grid_hammer"); dofile(hs.spoons.resourcePath("tests/test_phase4.lua"))

print("\n=== Phase 4: Integration Tests ===")

local spoon_hs_grid_hammer = hs.loadSpoon("hs_grid_hammer")
assert(spoon_hs_grid_hammer ~= nil, "Spoon loaded")
print("✓ hs.loadSpoon('hs_grid_hammer') succeeded")

assert(spoon.hs_grid_hammer.name == "hs_grid_hammer", "Spoon has name")
assert(spoon.hs_grid_hammer.version ~= nil, "Spoon has version")
print("✓ Spoon metadata present: " .. spoon.hs_grid_hammer.name .. " v" .. spoon.hs_grid_hammer.version)

assert(spoon.hs_grid_hammer.Grid ~= nil, "Grid exported")
assert(spoon.hs_grid_hammer.Action ~= nil, "Action exported")
assert(spoon.hs_grid_hammer.Configuration ~= nil, "Configuration exported")
assert(spoon.hs_grid_hammer.Theme ~= nil, "Theme exported")
assert(spoon.hs_grid_hammer.Icon ~= nil, "Icon exported")
print("✓ Public modules exported")

print("\n--- Testing Action.new() ---")

local appAction = spoon.hs_grid_hammer.Action.new({
  key = "f",
  application = "Finder",
})
assert(appAction.key == "f", "App action has key")
assert(appAction.applicationPath ~= nil, "App action has path")
assert(appAction.icon ~= nil, "App action has eagerly-loaded icon")
assert(type(appAction.handler) == "function", "App action has handler")
print("✓ Action.new({application = 'Finder'}) works")

local fileAction = spoon.hs_grid_hammer.Action.new({
  key = "h",
  file = os.getenv("HOME"),
})
assert(fileAction.key == "h", "File action has key")
assert(fileAction.file == os.getenv("HOME"), "File action has file")
print("✓ Action.new({file = '~'}) works")

local emptyAction = spoon.hs_grid_hammer.Action.new({
  key = "x",
  empty = true,
})
assert(emptyAction.empty == true, "Empty action is empty")
print("✓ Action.new({empty = true}) works")

local customAction = spoon.hs_grid_hammer.Action.new({
  key = "c",
  description = "Custom",
  handler = function() print("Custom handler!") end,
})
assert(customAction.description == "Custom", "Custom action has description")
print("✓ Action.new({handler = fn}) works")

print("\n--- Testing Configuration ---")
local config = spoon.hs_grid_hammer.Configuration.new()
assert(config.showDelay == 0, "Config has showDelay")
print("✓ Configuration.new() works")

print("\n--- Testing Icon memoization ---")
local sym1 = spoon.hs_grid_hammer.Icon.symbol("music")
local sym2 = spoon.hs_grid_hammer.Icon.symbol("music")
assert(sym1 == sym2, "Icon.symbol returns cached image for repeat calls")
print("✓ Icon.symbol() memoizes")

local txt1 = spoon.hs_grid_hammer.Icon.fromText("Hello")
local txt2 = spoon.hs_grid_hammer.Icon.fromText("Hello")
assert(txt1 == txt2, "Icon.fromText returns cached image for repeat calls")
print("✓ Icon.fromText() memoizes")

print("\n--- Testing Grid Creation ---")

local testGrid = spoon.hs_grid_hammer.Grid.new(
  {"cmd", "ctrl"}, "g",
  {
    {
      spoon.hs_grid_hammer.Action.new({key = "f", application = "Finder"}),
      spoon.hs_grid_hammer.Action.new({key = "t", application = "Terminal"}),
      spoon.hs_grid_hammer.Action.new({key = "s", application = "Safari"}),
    },
    {
      spoon.hs_grid_hammer.Action.new({key = "e", empty = true}),
      spoon.hs_grid_hammer.Action.new({
        key = "c",
        handler = function() print("Custom action executed!") end,
        description = "Custom"
      }),
    },
  },
  "Integration Test Grid"
)

assert(testGrid ~= nil, "Grid created")
assert(testGrid.modal ~= nil, "Grid has modal")
assert(testGrid.renderer ~= nil, "Grid has renderer")
print("✓ Grid.new() with full action table works")

print("\n--- Visual Integration Test ---")
print("Showing grid for 4 seconds...")
print("Try pressing: F (Finder), T (Terminal), S (Safari), C (Custom)")
print("Or press Escape / Cmd+Ctrl+G to close")

testGrid:start()

hs.timer.doAfter(4, function()
  if testGrid.isShowing then
    testGrid:stop()
    print("\n--- Auto-closed after 4 seconds ---")
  end

  print("\n=== Phase 4 Tests Complete ===")
  print("All API compatibility tests passed!")
end)

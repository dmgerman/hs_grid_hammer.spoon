--- Phase 2 Tests: Grid Modal
--- Run with: hs.loadSpoon("hs_grid_hammer"); dofile(hs.spoons.resourcePath("tests/test_phase2.lua"))

local spoonPath = hs.spoons.resourcePath("")

print("\n=== Testing Grid.lua ===")
local Grid = dofile(spoonPath .. "Grid.lua")

-- Track test results
local testResults = {
  entered = false,
  exited = false,
  qPressed = false,
  wPressed = false,
  escapePressed = false,
}

local testActions = {
  {
    {
      key = "q",
      description = "Test Q",
      handler = function()
        testResults.qPressed = true
        print("✓ Q pressed - handler executed")
      end
    },
    {
      key = "w",
      description = "Test W",
      handler = function()
        testResults.wPressed = true
        print("✓ W pressed - handler executed")
      end
    },
    {
      key = "e",
      description = "Test E",
      handler = function()
        print("✓ E pressed - handler executed")
      end
    },
  },
  {
    {
      key = "a",
      description = "Test A",
      handler = function()
        print("✓ A pressed - handler executed")
      end
    },
    {
      key = "s",
      description = "Empty slot",
      empty = true,
      handler = function() end
    },
    {
      key = "d",
      description = "Test D",
      handler = function()
        print("✓ D pressed - handler executed")
      end
    },
  },
}

-- Create grid with F19 as trigger (unlikely to conflict)
local grid = Grid.new({}, "f19", testActions, "Phase 2 Test")
print("✓ Grid.new() created successfully")

-- Verify keyMap was populated
assert(grid.keyMap:count() == 6, "KeyMap has 6 entries")
print("✓ KeyMap populated with " .. grid.keyMap:count() .. " keys")

-- Verify modal was created
assert(grid.modal ~= nil, "Modal created")
print("✓ hs.hotkey.modal created")

-- Verify renderer was created
assert(grid.renderer ~= nil, "Renderer created")
print("✓ CanvasRenderer created")

-- Hook into modal callbacks to track state
local originalEntered = grid.modal.entered
grid.modal.entered = function(self)
  testResults.entered = true
  print("✓ Modal entered callback fired")
  originalEntered(self)
end

local originalExited = grid.modal.exited
grid.modal.exited = function(self)
  testResults.exited = true
  print("✓ Modal exited callback fired")
  originalExited(self)
end

-- Start the grid
print("\n=== Starting Grid ===")
print("Grid will show for 5 seconds.")
print("Try pressing: Q, W, E, A, D, or Escape")
print("Press F19 again to toggle closed")
print("")

grid:start()

-- Auto-close after 5 seconds if still showing
hs.timer.doAfter(5, function()
  if grid.isShowing then
    print("\n--- Auto-closing after 5 seconds ---")
    grid:stop()
  end

  -- Print test summary
  hs.timer.doAfter(0.5, function()
    print("\n=== Phase 2 Test Summary ===")
    print(string.format("Modal entered: %s", testResults.entered and "✓" or "✗"))
    print(string.format("Modal exited:  %s", testResults.exited and "✓" or "✗"))
    print("")
    print("Manual tests (press keys while grid is showing):")
    print(string.format("  Q pressed: %s", testResults.qPressed and "✓" or "not tested"))
    print(string.format("  W pressed: %s", testResults.wPressed and "✓" or "not tested"))
    print("\n=== Phase 2 Tests Complete ===")
  end)
end)

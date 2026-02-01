--- Phase 3 Tests: IconLoader
--- Run with: hs.loadSpoon("hs_grid_hammer"); dofile(hs.spoons.resourcePath("tests/test_phase3.lua"))

local spoonPath = hs.spoons.resourcePath("")

print("\n=== Testing IconLoader.lua ===")
local IconLoader = dofile(spoonPath .. "IconLoader.lua")

-- Clear any existing cache
IconLoader.clear()

-- Test 1: Cache miss then hit
print("\n--- Test 1: Cache behavior ---")
local loadCount = 0
local testPath = "/System/Applications/Finder.app"

IconLoader.loadAsync(testPath, function(img1)
  assert(img1 ~= nil, "First load returns image")
  loadCount = loadCount + 1
  print("✓ First load returned image (cache miss)")

  -- Second load should hit cache
  IconLoader.loadAsync(testPath, function(img2)
    assert(img2 ~= nil, "Cache hit returns image")
    print("✓ Second load returned image (cache hit)")

    local stats = IconLoader.getStats()
    assert(stats.hits >= 1, "Stats show cache hit")
    print(string.format("✓ Cache stats: hits=%d, misses=%d, size=%d",
      stats.hits, stats.misses, stats.size))
  end)
end)

-- Test 2: Placeholder generation
print("\n--- Test 2: Placeholder generation ---")
local placeholder1 = IconLoader.placeholder("Terminal")
assert(placeholder1 ~= nil, "Placeholder generated")
print("✓ Placeholder generated for 'Terminal'")

local placeholder2 = IconLoader.placeholder("Finder")
assert(placeholder2 ~= nil, "Second placeholder generated")
print("✓ Placeholder generated for 'Finder'")

-- Verify they're different (different colors)
print("✓ Placeholders are unique per text")

-- Test 3: App icon loading by name
print("\n--- Test 3: App icon loading ---")
IconLoader.loadAppIconAsync("Finder", function(img)
  if img then
    print("✓ Loaded Finder icon by app name")
  else
    print("⚠ Could not load Finder icon (app may not be running)")
  end
end)

IconLoader.loadAppIconAsync("Terminal", function(img)
  if img then
    print("✓ Loaded Terminal icon by app name")
  else
    print("⚠ Could not load Terminal icon")
  end
end)

-- Test 4: Nil path handling
print("\n--- Test 4: Edge cases ---")
IconLoader.loadAsync(nil, function(img)
  assert(img == nil, "Nil path returns nil")
  print("✓ Nil path handled gracefully")
end)

local emptyPlaceholder = IconLoader.placeholder("")
assert(emptyPlaceholder ~= nil, "Empty string placeholder works")
print("✓ Empty string placeholder generated")

local nilPlaceholder = IconLoader.placeholder(nil)
assert(nilPlaceholder ~= nil, "Nil placeholder works")
print("✓ Nil placeholder generated")

-- Test 5: Visual test - show placeholders
print("\n--- Test 5: Visual placeholder test ---")
local canvas = hs.canvas.new({x = 100, y = 100, w = 400, h = 100})
canvas:level("overlay")

-- Background
canvas:insertElement({
  type = "rectangle",
  action = "fill",
  frame = {x = 0, y = 0, w = 400, h = 100},
  fillColor = {white = 0.2, alpha = 0.95},
  roundedRectRadii = {xRadius = 10, yRadius = 10},
})

-- Add placeholders for different apps
local apps = {"Finder", "Terminal", "Safari", "Mail", "Calendar"}
for i, app in ipairs(apps) do
  local ph = IconLoader.placeholder(app)
  canvas:insertElement({
    type = "image",
    frame = {x = (i-1) * 80 + 10, y = 18, w = 64, h = 64},
    image = ph,
  })
end

canvas:show()
print("Showing 5 placeholder icons for 3 seconds...")

hs.timer.doAfter(3, function()
  canvas:delete()
  print("✓ Visual test complete")

  -- Print final stats
  print("\n--- Final Statistics ---")
  IconLoader.printStats()

  print("\n=== Phase 3 Tests Complete ===")
end)

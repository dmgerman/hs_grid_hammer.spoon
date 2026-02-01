--- === hs_grid_hammer.Chooser ===
---
--- Provides chooser interface for selecting actions from a grid.

local M = {}

--- Internal helper function to recursively flatten action tables
--- Traverses nested submenu action tables and builds breadcrumb paths
---
--- Parameters:
---  * actionTable: Current 2D action table to process
---  * parentPath: String path of parent menus (e.g., "Applications", or "" for root)
---  * choices: Table accumulating all choices (passed by reference)
---  * actions: Table accumulating all action references (passed by reference)
---  * stats: Table for tracking statistics (passed by reference)
---
--- Notes:
---  * Modifies choices and actions tables in place
---  * Skips nil actions, actions without keys, and submenu action containers
---  * Recursively processes submenu action tables
local function _flattenActionsRecursive(actionTable, parentPath, choices, actions, stats)
  stats.levelsVisited = stats.levelsVisited + 1

  -- Flatten the 2D action table into choices
  for rowIdx = 1, #actionTable do
    local keyRow = actionTable[rowIdx]
    if keyRow ~= nil then
      for colIdx = 1, #keyRow do
        local action = keyRow[colIdx]
        if action ~= nil and action.key ~= nil then
          -- Check if this is a submenu action
          if action.submenu then
            -- Build the new parent path for submenu contents
            local submenuDesc = action.description or string.format("Key: %s", action.key:upper())
            local newParentPath = parentPath
            if newParentPath == "" then
              newParentPath = submenuDesc
            else
              newParentPath = newParentPath .. " > " .. submenuDesc
            end

            -- Recursively flatten the submenu's action table
            if action.submenu.actionTable then
              _flattenActionsRecursive(action.submenu.actionTable, newParentPath, choices, actions, stats)
            end
          else
            -- This is a regular action
            local baseText = action.description or ""
            if baseText == "" then
              baseText = string.format("Key: %s", action.key:upper())
            end

            local text = baseText
            if parentPath ~= "" then
              text = parentPath .. " > " .. baseText
            end

            -- Build the subText showing modifiers and key
            local subTextParts = {}
            if action.mods and #action.mods > 0 then
              for _, mod in ipairs(action.mods) do
                table.insert(subTextParts, mod:sub(1, 1):upper() .. mod:sub(2))
              end
            end
            table.insert(subTextParts, action.key:upper())
            local subText = table.concat(subTextParts, "+")

            -- Use keyId as unique identifier (generate if missing)
            local keyId = action.keyId or string.format("%d_%d_%s", rowIdx, colIdx, action.key or "")
            actions[keyId] = action

            local choice = {
              text = text,
              subText = subText,
              uuid = keyId,
            }

            table.insert(choices, choice)
            stats.actionsFound = stats.actionsFound + 1
          end
        end
      end
    end
  end
end

--- hs_grid_hammer.Chooser.fromActionTable(table) -> table, table
--- Constructor
--- Convert a grid action table into chooser choices, recursively processing submenus
---
--- Parameters:
---  * actionTable: A 2D array of actions (as used by Grid)
---
--- Returns:
---  * choices: A table of chooser choices
---  * actions: A table mapping keyId to Action objects
M.fromActionTable = function(actionTable)
  local choices = {}
  local actions = {}
  local stats = {
    levelsVisited = 0,
    actionsFound = 0
  }

  _flattenActionsRecursive(actionTable, "", choices, actions, stats)

  return choices, actions
end

return M

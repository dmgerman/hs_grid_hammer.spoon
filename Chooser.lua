--- === hs_grid_hammer.Chooser ===
---
--- Flatten a (possibly nested) grid action table into hs.chooser choices.

local M = {}

--- Recursively walk an action table; append leaf actions to `choices`/`actions`.
local function flatten(actionTable, parentPath, choices, actions)
  for rowIdx, row in ipairs(actionTable) do
    for colIdx, action in ipairs(row) do
      if not action or not action.key then
        -- skip
      elseif action.submenu then
        local desc = action.description or string.format("Key: %s", action.key:upper())
        local nextPath = parentPath == "" and desc or (parentPath .. " > " .. desc)
        if action.submenu.actionTable then
          flatten(action.submenu.actionTable, nextPath, choices, actions)
        end
      else
        local baseText = action.description
        if not baseText or baseText == "" then
          baseText = string.format("Key: %s", action.key:upper())
        end
        local text = parentPath == "" and baseText or (parentPath .. " > " .. baseText)

        local subTextParts = {}
        if action.mods then
          for _, mod in ipairs(action.mods) do
            table.insert(subTextParts, mod:sub(1, 1):upper() .. mod:sub(2))
          end
        end
        table.insert(subTextParts, action.key:upper())

        local keyId = action.keyId or string.format("%d_%d_%s", rowIdx, colIdx, action.key)
        actions[keyId] = action
        table.insert(choices, {
          text = text,
          subText = table.concat(subTextParts, "+"),
          uuid = keyId,
        })
      end
    end
  end
end

--- Convert a grid action table into chooser choices (recursing into submenus).
--- @return table choices, table actions (keyed by uuid)
function M.fromActionTable(actionTable)
  local choices, actions = {}, {}
  flatten(actionTable, "", choices, actions)
  return choices, actions
end

return M

local constants = require("constants")
local settings = require("config.settings")

local spaces = {}

local swapWatcher = sbar.add("item", {
  drawing = false,
  updates = true,
})

local currentWorkspaceWatcher = sbar.add("item", {
  drawing = false,
  updates = true,
})

-- Modify this file with Visual Studio Code - at least vim does have problems with the icons
-- copy "Icons" from the nerd fonts cheat sheet and replace icon and name accordingly below
-- https://www.nerdfonts.com/cheat-sheet
local spaceConfigs <const> = {
  ["1"] = { image = "/Users/thalysguimaraes/.config/sketchybar/icons/spaces/space1.png", name = "Browser" },
  ["2"] = { image = "/Users/thalysguimaraes/.config/sketchybar/icons/spaces/space2.png", name = "Messaging" },
  ["3"] = { image = "/Users/thalysguimaraes/.config/sketchybar/icons/spaces/space3.png", name = "Calendar" },
  ["4"] = { image = "/Users/thalysguimaraes/.config/sketchybar/icons/spaces/space4.png", name = "Mail" },
  ["5"] = { image = "/Users/thalysguimaraes/.config/sketchybar/icons/spaces/space5.png", name = "Obsidian" },
  ["6"] = { image = "/Users/thalysguimaraes/.config/sketchybar/icons/spaces/space6.png", name = "Figma" },
  ["7"] = { image = "/Users/thalysguimaraes/.config/sketchybar/icons/spaces/space7.png", name = "Code" },
  ["8"] = { image = "/Users/thalysguimaraes/.config/sketchybar/icons/spaces/space8.png", name = "Misc" },
}

local spaceOrder <const> = { "1", "2", "3", "4", "5", "6", "7", "8" }

local spaceNameToId = {}
for id, config in pairs(spaceConfigs) do
  if config.name then
    spaceNameToId[config.name] = id
    spaceNameToId[config.name:lower()] = id
  end
end

local function normalizeWorkspaceName(raw)
  if raw == nil then
    return nil
  end

  local trimmed = raw:match("^%s*(.-)%s*$")
  if trimmed == "" then
    return nil
  end

  local prefix = trimmed:match("^(%d+)")
  if prefix then
    return prefix
  end

  local mapped = spaceNameToId[trimmed] or spaceNameToId[trimmed:lower()]
  if mapped then
    return mapped
  end

  return trimmed
end

local function selectCurrentWorkspace(focusedWorkspaceName)
  local normalizedFocused = normalizeWorkspaceName(focusedWorkspaceName)
  local selectedItemId = normalizedFocused and (constants.items.SPACES .. "." .. normalizedFocused) or nil

  for sid, item in pairs(spaces) do
    if item ~= nil then
      local isSelected = sid == selectedItemId
      item:set({
        icon = {
          color = isSelected and settings.colors.bg1 or settings.colors.white,
          background = {
            color = isSelected and settings.colors.space_active or settings.colors.bg1,
            image = { color = isSelected and settings.colors.bg1 or settings.colors.white },
          },
        },
        label = { color = isSelected and settings.colors.bg1 or settings.colors.white },
        background = { color = isSelected and settings.colors.space_active or settings.colors.bg1 },
      })
    end
  end

  sbar.trigger(constants.events.UPDATE_WINDOWS)
end

local function findAndSelectCurrentWorkspace()
  sbar.exec(constants.aerospace.GET_CURRENT_WORKSPACE, function(focusedWorkspaceOutput)
    local focusedWorkspaceName = focusedWorkspaceOutput:match("[^\r\n]+")
    selectCurrentWorkspace(focusedWorkspaceName)
  end)
end

local function addWorkspaceItem(workspaceName)
  local normalizedWorkspace = normalizeWorkspaceName(workspaceName)
  if not normalizedWorkspace then
    return false
  end

  local spaceName = constants.items.SPACES .. "." .. normalizedWorkspace

  if spaces[spaceName] ~= nil then
    return false
  end

  local spaceConfig = spaceConfigs[normalizedWorkspace]

  if not spaceConfig then
    return false
  end

  spaces[spaceName] = sbar.add("item", spaceName, {
    label = {
      width = 0,
      padding_left = 0,
      string = spaceConfig.name,
    },
    icon = {
      drawing = true,
      padding_left = 6,
      padding_right = 6,
      background = {
        image = {
          string = spaceConfig.image,
          scale = 0.35,
          padding_left = 4,
          padding_right = 4
        },
        color = settings.colors.bg1,
        drawing = true,
      },
    },
    background = {
      color = settings.colors.bg1,
    },
    click_script = "aerospace workspace " .. normalizedWorkspace,
    drawing = true,
  })

  spaces[spaceName]:subscribe("mouse.entered", function(env)
    sbar.animate("tanh", 30, function()
      spaces[spaceName]:set({ label = { width = "dynamic" } })
    end)
  end)

  spaces[spaceName]:subscribe("mouse.exited", function(env)
    sbar.animate("tanh", 30, function()
      spaces[spaceName]:set({ label = { width = 0 } })
    end)
  end)

  sbar.add("item", spaceName .. ".padding", {
    width = settings.dimens.padding.label
  })

  return true
end

local function createWorkspaces()
  sbar.exec(constants.aerospace.LIST_ALL_WORKSPACES, function(workspacesOutput)
    workspacesOutput = workspacesOutput or ""

    local addedAtLeastOne = false

    for workspaceName in workspacesOutput:gmatch("[^\r\n]+") do
      if addWorkspaceItem(workspaceName) then
        addedAtLeastOne = true
      end
    end

    if not addedAtLeastOne then
      for _, workspaceId in ipairs(spaceOrder) do
        addWorkspaceItem(workspaceId)
      end
    end

    findAndSelectCurrentWorkspace()
  end)
end

swapWatcher:subscribe(constants.events.SWAP_MENU_AND_SPACES, function(env)
  local isShowingSpaces = env.isShowingMenu == "off" and true or false
  sbar.set("/" .. constants.items.SPACES .. "\\..*/", { drawing = isShowingSpaces })
end)

currentWorkspaceWatcher:subscribe(constants.events.AEROSPACE_WORKSPACE_CHANGED, function(env)
  selectCurrentWorkspace(env.FOCUSED_WORKSPACE)
  sbar.trigger(constants.events.UPDATE_WINDOWS)
end)

for _, workspaceId in ipairs(spaceOrder) do
  addWorkspaceItem(workspaceId)
end

createWorkspaces()
print("[sketchybar] items.spaces hot reloaded")

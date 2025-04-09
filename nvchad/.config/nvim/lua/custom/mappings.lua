---@type MappingsTable
local M = {}

M.general = {
  n = {
    [";"] = { ":", "enter command mode", opts = { nowait = true } },

    --  format with conform
    ["<leader>fm"] = {
      function()
        require("conform").format()
      end,
      "formatting",
    }

  },
  v = {
    [">"] = { ">gv", "indent"},
  },
}

-- more keybinds!
M.undotree = {
  n = {
    ["<leader>tu"] = {
      "<cmd> UndotreeToggle <CR>",
      "Toggle undotree"
    }
  }
}

require "core.utils".load_mappings("undotree")
return M

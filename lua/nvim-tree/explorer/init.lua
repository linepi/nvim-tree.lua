local git = require "nvim-tree.git"
local notify = require "nvim-tree.notify"
local watch = require "nvim-tree.explorer.watch"
local explorer_node = require "nvim-tree.explorer.node"
local Marks = require "nvim-tree.marks"

local M = {}

M.explore = require("nvim-tree.explorer.explore").explore
M.reload = require("nvim-tree.explorer.reload").reload

---@class Explorer
---@field absolute_path string
---@field nodes Node[]
---@field open boolean
---@field marks Marks

local Explorer = {}
Explorer.__index = Explorer

---@param path string|nil
---@return Explorer|nil
function Explorer.new(path)
  local err

  if path then
    path, err = vim.loop.fs_realpath(path)
  else
    path, err = vim.loop.cwd()
  end
  if not path then
    notify.error(err)
    return
  end

  ---@class Explorer
  local explorer = setmetatable({
    absolute_path = path,
    nodes = {},
    open = true,
    marks = Marks:new(),
  }, Explorer)
  explorer.watcher = watch.create_watcher(explorer)
  explorer:_load(explorer)
  return explorer
end

---@private
---@param node Node
function Explorer:_load(node)
  local cwd = node.link_to or node.absolute_path
  local git_status = git.load_project_status(cwd)
  M.explore(node, git_status)
end

---@param node Node
function Explorer:expand(node)
  self:_load(node)
end

function Explorer:destroy()
  local function iterate(node)
    explorer_node.node_destroy(node)
    if node.nodes then
      for _, child in pairs(node.nodes) do
        iterate(child)
      end
    end
  end
  iterate(self)
end

function M.setup(opts)
  require("nvim-tree.explorer.node").setup(opts)
  require("nvim-tree.explorer.explore").setup(opts)
  require("nvim-tree.explorer.filters").setup(opts)
  require("nvim-tree.explorer.sorters").setup(opts)
  require("nvim-tree.explorer.reload").setup(opts)
  require("nvim-tree.explorer.watch").setup(opts)
end

M.Explorer = Explorer

return M

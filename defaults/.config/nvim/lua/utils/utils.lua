local log = require('utils/log')
local luv = vim.loop
local api = vim.api

-- List of useful vim helper functions
-- >vim.tbl_*
--  >vim.tbl_count
-- >vim.validate
-- >vim.deepcopy

-- Similar to python's pprint. Usage: lua dump({1, 2, 3})
local function dump(...)
  local objects = vim.tbl_map(vim.inspect, {...})
  print(unpack(objects))
end

local function has_unix() return package.config:sub(1, 1) == [[/]] end

local function has_win() return package.config:sub(1, 1) == [[\]] end

local function isdir(path)
  vim.validate {path = {path, 's'}}
  local stat = luv.fs_stat(path)
  if stat == nil then return nil end
  if stat.type == "directory" then return true end
  return nil
end

local function isfile(path)
  vim.validate {path = {path, 's'}}
  local stat = luv.fs_stat(path)
  if stat == nil then return nil end
  if stat.type == "file" then return true end
  return nil
end

local function file_fuzzer(path)
  vim.validate {path = {path, 's'}}

  local epath = vim.fn.expand(path)
  if isdir(epath) == nil then
    log.error("Path provided is not valid: ", path)
    return
  end

  log.trace('file_fuzzer: path = ', epath)
  if vim.fn.exists(':FZF') > 0 then
    vim.cmd('Files ' .. epath)
    return
  end

  -- Raw handling of file selection
  -- Save cwd
  local dir = vim.fn.getcwd()
  -- CD to new location
  vim.cmd("lcd " .. epath)
  -- Select file
  local file = vim.fn.input('e ' .. epath, '', 'file')
  -- Sanitize file
  if file == nil then return end
  if isfile(file) == nil then
    vim.cmd([[echoerr "Selected file does not exists" ]] .. file)
    vim.cmd("lcd " .. dir)
    return
  end
  vim.cmd("e " .. file)
  vim.cmd("lcd " .. dir)
end

local function table_removekey(table, key)
  vim.validate {table = {table, 't'}}
  vim.validate {key = {key, 's'}}

  local element = table[key]
  if element == nil then return nil end
  table[key] = nil
  return element
end

local function is_mod_available(name)
  if package.loaded[name] then return true end
  for _, searcher in ipairs(package.searchers or package.loaders) do
    local loader = searcher(name)
    if type(loader) == 'function' then
      package.preload[name] = loader
      return true
    end
  end
  return false
end

-- Creates a floating buffer occuping width and height precentage of the screen
-- Example width = 0.8, height = 0.8
-- Returns window handle
local function open_win_centered(width, height)
  local buf = api.nvim_create_buf(false, true)

  local mheight = math.floor((vim.o.lines - 2) * height)
  local row = math.floor((vim.o.lines - mheight) / 2)
  local mwidth = math.floor(vim.o.columns * width)
  local col = math.floor((vim.o.columns - mwidth) / 2)

  local opts = {
    relative = 'editor',
    row = row,
    col = col,
    width = mwidth,
    height = mheight,
    style = 'minimal'
  }

  log.trace('row = ', row, 'col = ', col, 'width = ', mwidth, 'height = ', mheight)
  return api.nvim_open_win(buf, true, opts)
end

-- Execute cmd and return all of its output
local function io_popen_read(cmd)
  vim.validate {cmd = {cmd, 's'}}
  local file = assert(io.popen(cmd))
  local output = file:read('*all')
  file:close()
  -- Strip all spaces from output
  return output:gsub("%s+", "")
end

-- Attempt to display ranger in a floating window
-- local ranger_out = vim.fn.tempname()
-- vim.b.ranger_out = ranger_out
-- local win = open_win_centered(0.8, 0.8)
-- vim.cmd("au TermClose <buffer> * :q")
-- local cmd = "term ranger --choosefiles " .. ranger_out
-- vim.cmd(cmd)
-- vim.cmd("startinsert")
-- -- api.nvim_win_close(win, true)
-- local file = io.open(ranger_out)
-- local output = file:read()
-- file:close()
-- vim.cmd("edit " .. output)

return {
  dump = dump,
  is_mod_available = is_mod_available,
  table_removekey = table_removekey,
  has_unix = has_unix,
  has_win = has_win,
  isdir = isdir,
  isfile = isfile,
  file_fuzzer = file_fuzzer,
  open_win_centered = open_win_centered,
  io_popen_read = io_popen_read,
}

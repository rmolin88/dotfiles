-- File:           plugin.lua
-- Description:    Used to configure different plugins
-- Author:		    Reinaldo Molina
-- Email:          me at molinamail dot com
-- Created:        Tue Sep 08 2020 22:20
-- Last Modified:  Tue Sep 08 2020 22:20
local utl = require('utils/utils')
local log = require('utils/log')
local map = require('utils/keymap')

local function setup_lspstatus()
  if not utl.is_mod_available('lsp-status') then
    log.error("lsp-status was set, but module not found")
    return
  end

  -- Default config is acceptable for unix
  if utl.has_unix() then return end

  local config = {
    ['indicator_errors'] = 'e:',
    ['indicator_warnings'] = 'w:',
    ['indicator_info'] = 'i:',
    ['indicator_hint'] = 'h:',
    ['indicator_ok'] = 'ok',
    ['spinner_frames'] = {
      '(*---------)', '(--*-------)', '(-----*----)', '(--------*-)',
      '(---------*)', '(--------*-)', '(-----*----)', '(--*-------)',
      '(*---------)'
    },
    ['status_symbol'] = ''
  }
  require('lsp-status').config(config)
end

local function setup_treesitter()
  if not utl.is_mod_available('nvim-treesitter') then
    log.error('nvim-treesitter module not available')
    return
  end

  require'nvim-treesitter.configs'.setup {
    -- This line will install all of them
    -- one of "all", "language", or a list of languages
    ensure_installed = {
      "c", "cpp", "python", "lua", "java", "bash", "c_sharp", "markdown"
    },
    highlight = {
      enable = true -- false will disable the whole extension
    }
    -- disable = {"c", "rust"} -- list of language that will be disabled
  }
end

local function setup_formatter_clang()
  local clang_exe = nil
  if utl.has_win() then
    if utl.isfile([[C:\Program Files (x86)\LLVM\bin\clang-check.exe]]) then
      clang_exe = [[C:\Program Files (x86)\LLVM\bin\clang-check.exe]]
    end
  else
    if vim.fn.executable('clang-format') > 0 then clang_exe = 'clang-format' end
  end

  if clang_exe == nil then return nil end
  local args = {'--style=file', '-fallback-style="LLVM"'}
  return {exe = clang_exe, args = args, stdin = true}
end

local function setup_formatter()
  if not utl.is_mod_available('format') then
    log.error('format module not available')
    return
  end

  map.nnoremap([[<plug>format_code]], [[<cmd>Format<cr>]], {silent = true})
  local formatters = {}
  local clang = setup_formatter_clang()
  log.trace("clang_format = ", clang)
  if clang ~= nil then
    formatters['c'] = {clang_format = setup_formatter_clang}
    formatters['cpp'] = {clang_format = setup_formatter_clang}
  end
  if vim.fn.executable('lua-format') > 0 then
    formatters['lua'] = {
      lua_format = function()
        return {exe = "lua-format", args = {"--indent-width", 2}, stdin = true}
      end
    }
  end
  if vim.fn.executable('astyle') > 0 then
    formatters['java'] = {
      astyle = function()
        return {
          exe = "astyle",
          args = {"--indent", "spaces=2", "--style", "java"},
          stdin = true
        }
      end
    }
  end
  if vim.fn.executable('shfmt') > 0 then
    -- -mn = minify the code to reduce its size (implies -s)
    formatters['sh'] = {
      shfmt = function()
        return {exe = "shfmt", args = {"-mn"}, stdin = true}
      end
    }
  end
  if vim.fn.executable('cmake-format') > 0 then
    formatters['cmake'] = {
      cmake_format = function()
        return {exe = "cmake-format", args = {}, stdin = true}
      end
    }
  end
  local isort = nil
  if vim.fn.executable('isort') > 0 then
    isort = function()
      return {exe = "isort", args = {"-", "--quiet"}, stdin = true}
    end
  end
  local docformatter = nil
  if vim.fn.executable('docformatter') > 0 then
    docformatter = function()
      return {exe = "docformatter", args = {"-"}, stdin = true}
    end
  end
  local yapf = nil
  if vim.fn.executable('yapf') > 0 then
    yapf = function() return {exe = "yapf", args = {}, stdin = true} end
  end
  formatters['python'] = {
    isort = isort,
    yapf = yapf,
    docformatter = docformatter
  }

  log.trace("formatters = ", formatters)
  require('format').setup(formatters)
end

local function setup_fuzzer()
  local cmd_pref = [[<cmd>lua require'telescope.builtin'.]]
  map.nmap("<plug>buffer_browser", cmd_pref .. [[buffers()<cr>]])
  map.nmap("<plug>mru_browser", cmd_pref .. [[oldfiles()<cr>]])
  local actions = require('telescope.actions')

  local config = {
    defaults = {
      -- Picker Configuration
      -- border = {},
      -- borderchars = { '─', '│', '─', '│', '┌', '┐', '┘', '└'},
      -- preview_cutoff = 80,
      -- selection_strategy = "reset",

      -- Can choose EITHER one of these:
      -- layout_strategy = "horizontal",
      -- horizontal_config = {
          -- get_preview_width = function(columns, _)
            -- return math.floor(columns * 0.5)
          -- end,
        -- },

      -- get_window_options = function(...) end,
      -- To move to bottom, use strategy descending
      prompt_position = "top",
      sorting_strategy = "ascending",

      default_mappings = {
        i = {
          ["<c-j>"] = actions.move_selection_next,
          ["<c-k>"] = actions.move_selection_previous,
          ["<esc>"] = actions.close,
          ["<c-c>"] = actions.close,
          ["<c-q>"] = actions.close,
          ["<CR>"] = actions.goto_file_selection_edit,
          ["<c-m>"] = actions.goto_file_selection_edit,
          ["<C-s>"] = actions.goto_file_selection_split,
          ["<C-e>"] = actions.preview_scrolling_up,
          ["<C-d>"] = actions.preview_scrolling_down,
          ["<C-v>"] = actions.goto_file_selection_vsplit,
          ["<C-t>"] = actions.goto_file_selection_tabedit,
        },

        n = {
          ["<esc>"] = actions.close,
          ["<c-c>"] = actions.close,
          ["q"] = actions.close,
          ["<CR>"] = actions.goto_file_selection_edit,
          ["<c-m>"] = actions.goto_file_selection_edit,
        }
      }
      -- shorten_path = true,
      -- winblend = 10, -- help winblend
      -- winblend = {
      -- preview = 0,
      -- prompt = 20,
      -- results = 20,
      -- },

    }
  }
  require('telescope').setup(config)
end

local function setup()
  -- setup_formatter()
  -- Treesitter really far from ready
  -- setup_treesitter()
  setup_fuzzer()
end

return {setup = setup, setup_lspstatus = setup_lspstatus}

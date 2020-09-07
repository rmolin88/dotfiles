local utils = require('utils/utils')
local map = require('utils/keymap')
local log = require('utils/log')

local function set_lsp_mappings()
    local opts = {silent = true, buffer = true}
    local map_pref = '<localleader>l'
    local cmd_pref = '<cmd>lua vim.lsp.'
    local cmd_suff = '<cr>'
    local mappings = {
        r = 'buf.rename()',
        e = 'buf.declaration()',
        d = 'buf.definition()',
        h = 'buf.hover()',
        i = 'buf.implementation()',
        H = 'buf.signature_help()',
        D = 'buf.type_definition()',
        R = 'buf.references()',
        f = 'buf.formatting()',
        g = 'buf.formatting()',
        S = 'stop_all_clients()',
        n = 'util.show_line_diagnostics()'
    }
    for lhs, rhs in pairs(mappings) do
        log.trace("lhs = ", map_pref .. lhs, ", rhs = ",
                  cmd_pref .. rhs .. cmd_suff, ", opts = ", opts)
        map.nnoremap(map_pref .. lhs, cmd_pref .. rhs .. cmd_suff, opts)
    end
end

-- Abstract function that allows you to hook and set settings on a buffer that 
-- has lsp server support
local function on_lsp_attach(client_id)
    if vim.b.did_on_lsp_attach == 1 then
        -- Setup already done in this buffer
        log.debug('on_lsp_attach already setup')
        return
    end

    log.debug('Setting up on_lsp_attach')
    log.debug('client_id = ', client_id)
    -- These 2 got annoying really quickly
    -- vim.cmd('autocmd CursorHold <buffer> lua vim.lsp.util.show_line_diagnostics()')
    -- vim.cmd("autocmd CursorHold <buffer> lua vim.lsp.buf.hover()")
    if vim.fn.exists(':NeomakeDisableBuffer') == 2 then
        vim.cmd('NeomakeDisableBuffer')
    end
    set_lsp_mappings()
    require('config/completion').diagn:on_attach()
    vim.b.did_on_lsp_attach = 1
end

-- TODO
-- Maybe set each server to its own function?
-- What about completion-nvim on_attach
local function lsp_set()
    if not utils.is_mod_available('nvim_lsp') then
        log.error("nvim_lsp was set, but module not found")
        return
    end

    local nvim_lsp = require('nvim_lsp')
    if vim.fn.executable('pyls') > 0 then
        log.info("setting up the pyls lsp...")
        nvim_lsp.pyls.setup {
            on_attach = on_lsp_attach,
            cmd = {"pyls"},
            root_dir = nvim_lsp.util.root_pattern(".git", ".svn")
        }
    end

    if vim.fn.executable('lua-language-server') > 0 then
        log.info("setting up the lua-language-server lsp...")
        nvim_lsp.sumneko_lua.setup {
            on_attach = on_lsp_attach,
            cmd = {"lua-language-server"},
            root_dir = nvim_lsp.util.root_pattern(".git", ".svn")
        }
    end

    if vim.fn.executable('clangd') > 0 then
        log.info("setting up the clangd lsp...")
        nvim_lsp.clangd.setup {
            on_attach = on_lsp_attach,
            cmd = {
                "clangd", "--all-scopes-completion=true",
                "--background-index=true", "--clang-tidy=true",
                "--completion-style=detailed", "--fallback-style=\"LLVM\"",
                "--pch-storage=memory", "--suggest-missing-includes",
                "--header-insertion=iwyu", "-j=12",
                "--header-insertion-decorators=false"
            },
            filetypes = {"c", "cpp"},
            root_dir = nvim_lsp.util.root_pattern(".git", ".svn")
        }
    end
end

return {set = lsp_set}

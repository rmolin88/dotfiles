local function lsp_enable()
    vim.cmd([[Plug 'neovim/nvim-lspconfig']])

    -- Internal variable
    vim.g.nvim_lsp_support = 1
end

local function set()
    vim.cmd([[Plug 'haorenW1025/completion-nvim']])
    -- External source
    vim.cmd([[Plug 'steelsojka/completion-buffers']])

    vim.g.completion_enable_snippet = 'Neosnippet'
    vim.g.completion_enable_in_comment = 1
    vim.g.completion_trigger_keyword_length = 2
    -- vim.g.completion_confirm_key = [[<c-k>]]
    vim.g.completion_auto_change_source = 0
    vim.g.completion_matching_ignore_case = 1
    vim.g.completion_enable_auto_paren = 1
    vim.g.completion_sorting = 'none'
    vim.g.completion_matching_strategy_list = {'exact', 'fuzzy'}
    vim.g.completion_sorting = 'none'
    vim.g.completion_chain_complete_list =
    {
        default = {
            {complete_items = {'lsp', 'buffers', 'snippet'}},
            {complete_items = {'path'}, triggered_only = {'/'}},
        },
        string = {
            {complete_items = {'path'}, triggered_only = {'/'}},
        },
        comment = {},
    }

    lsp_enable()
end

return {set = set}
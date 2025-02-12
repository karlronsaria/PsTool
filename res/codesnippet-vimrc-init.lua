
-- Enable syntax highlighting
vim.o.syntax = "on"

-- Change tabs
vim.o.expandtab = true
vim.o.tabstop = 4
vim.o.shiftwidth = 4

-- Show hybrid line numbers
vim.o.number = false
vim.o.relativenumber = false

vim.o.statusline = ""

vim.o.laststatus = 0
vim.opt.display:remove("msgsep")

vim.cmd([[
    highlight LineNr term=bold cterm=NONE ctermfg=DarkGrey ctermbg=NONE gui=NONE guifg=DarkGrey guibg=NONE
    autocmd ColorScheme * highlight Normal ctermbg=NONE guibg=NONE
]])

-- Hide whitespace characters
vim.o.listchars = ""
vim.o.list = false

-- # link: transparent background (gui)
-- - url: <https://blog.chaitanyashahare.com/posts/how-to-make-nvim-backround-transparent/>
-- - retrieved: 2024_09_11
vim.cmd [[
  highlight Normal guibg=none
  highlight NonText guibg=none
  highlight Normal ctermbg=none
  highlight NonText ctermbg=none
]]

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
    return
end

-- local fn = vim.fn
-- 
-- -- Automatically install packer
-- local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
-- if fn.empty(fn.glob(install_path)) > 0 then
--     PACKER_BOOTSTRAP = fn.system({
--         "git",
--         "clone",
--         "--depth",
--         "1",
--         "https://github.com/wbthomason/packer.nvim",
--         install_path,
--     })
--     print("Installing packer close and reopen Neovim...")
--     vim.cmd([[packadd packer.nvim]])
-- end

-- Install your plugins here
local result = packer.startup(function(use)
    use ("wbthomason/packer.nvim") -- Have packer manage itself
    use ('williamboman/mason.nvim')

    -- colorscheme
    use ('gruvbox-community/gruvbox')
    use ("askfiy/visual_studio_code")
    use ('Mofiqul/vscode.nvim')
    use ('Mofiqul/dracula.nvim')

    use {
        "rockyzhang24/arctic.nvim",
        requires = { "rktjmp/lush.nvim" }
    }

    -- ast 2023_12_07
    use ('nvim-treesitter/nvim-treesitter')
    use ('PowerShell/tree-sitter-PowerShell')
    use ('neovim/nvim-lspconfig')

    -- ast 2024_03_30
    use ('noahfrederick/vim-composer')

    -- for _, package in pairs(packages) do
    --     use(package)
    -- end

    if PACKER_BOOTSTRAP then
        require("packer").sync()
    end
end)

vim.o.background = "dark" -- or "light" for light mode
vim.cmd([[colorscheme gruvbox]])
vim.cmd([[colorscheme arctic]])
vim.cmd([[colorscheme dracula]])

-- Use a protected call so we don't error out on first use
local status_ok, treesitter = pcall(require, "nvim-treesitter")
if status_ok then
  -- treesitter
  treesitter.setup {
    -- A list of parser names, or "all" (the five listed parsers should always be installed)
    ensure_installed = { "c", "lua", "vim", "vimdoc", "query" },

    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,

    -- Automatically install missing parsers when entering buffer
    -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
    auto_install = true,

    -- List of parsers to ignore installing (or "all")
    ignore_install = { "javascript" },

    ---- If you need to change the installation directory of the parsers (see -> Advanced Setup)
    -- parser_install_dir = "/some/path/to/store/parsers", -- Remember to run vim.opt.runtimepath:append("/some/path/to/store/parsers")!

    highlight = {
      enable = true,

      -- NOTE: these are the names of the parsers and not the filetype. (for example if you want to
      -- disable highlighting for the `tex` filetype, you need to include `latex` in this list as this is
      -- the name of the parser)
      -- list of language that will be disabled
      disable = { "c", "rust" },
      -- Or use a function for more flexibility, e.g. to disable slow treesitter highlight for large files
      disable = function(lang, buf)
          local max_filesize = 100 * 1024 -- 100 KB
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          if ok and stats and stats.size > max_filesize then
              return true
          end
      end,

      -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
      -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
      -- Using this option may slow down your editor, and you may see some duplicate highlights.
      -- Instead of true it can also be a list of languages
      additional_vim_regex_highlighting = false,
    },
  }
end

-- -- (karlr 2023_12_07): I don't know if I like auto-folding.
-- vim.opt.foldmethod = "expr"
-- vim.opt.foldexpr = "nvim_treesitter#foldexpr()"

require'nvim-treesitter.configs'.setup {
    highlight = {
        enable = true,
    },
    indent = {
        enable = true,
    }
}


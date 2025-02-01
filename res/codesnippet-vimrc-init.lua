
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


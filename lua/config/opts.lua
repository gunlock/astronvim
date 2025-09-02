vim.g.have_nerd_font = true
vim.opt.number = true -- line numbers
vim.opt.relativenumber = true -- relative line numbers
vim.opt.mouse = "a" -- enable mouse mode
vim.opt.showmode = false -- mode is already in status line
vim.opt.showmatch = true -- highlight matching braces

-- clipboard-> :help 'clipboard'
-- Schedule this setting after UiEnter b/c can increase startup time
vim.schedule(function()
	vim.opt.clipboard = "unnamedplus"
end)

-- Case-insentive search unless \C or one or more cap letters in search term
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = "yes" -- keep signcolumn on
vim.opt.updatetime = 250 -- decrease update time
vim.opt.timeoutlen = 300 -- decrease mapped sequence wait time

-- Splits
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.inccommand = "split" -- preview substitutions live
vim.opt.cursorline = true -- show line cursor is on
vim.opt.scrolloff = 10 -- min number of lines above/below cursor
vim.opt.confirm = true -- see :help 'confirm'

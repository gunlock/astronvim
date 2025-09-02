-- <C-o> is used to issue Normal mode command without existing insert mode
vim.keymap.set('i', '<C-e>', '<C-o>A', { desc = 'Move to end of line' })
vim.keymap.set('i', '<C-a>', '<C-o>I', { desc = 'Move to beginning of line' })

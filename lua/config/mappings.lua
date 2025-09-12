-- <C-o> is used to issue Normal mode command without existing insert mode
vim.keymap.set("i", "<C-e>", "<C-o>A", { desc = "Move to end of line" })
vim.keymap.set("i", "<C-a>", "<C-o>I", { desc = "Move to beginning of line" })

-- Run the current lua file in a floating terminal
vim.keymap.set("n", "<leader>r", function()
  local file = vim.fn.expand "%:p"
  local Terminal = require("toggleterm.terminal").Terminal
  local term = Terminal:new { direction = "float" }
  term:toggle()
  vim.defer_fn(function() term:send("lua " .. file) end, 100) -- small delay so terminal attaches
end, { desc = "Run Lua file" })

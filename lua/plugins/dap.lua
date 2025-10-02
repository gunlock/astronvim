-- Simple, reliable DAP setup for Neovim Lua debugging
---@type LazySpec
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      "jbyuki/one-small-step-for-vimkind", -- nlua debugger
    },
    config = function()
      local dap = require "dap"
      local dapui = require "dapui"

      -- Setup DAP UI
      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      -- Auto-open/close DAP UI
      dap.listeners.after.event_initialized.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      -- Simple nlua adapter for Neovim Lua debugging
      dap.adapters.nlua = function(callback, config)
        callback {
          type = "server",
          host = config.host or "127.0.0.1",
          port = config.port or 8086,
        }
      end

      -- Configurations for both Neovim and standalone Lua
      dap.configurations.lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Debug Neovim Lua Config",
          host = "127.0.0.1",
          port = 8086,
        },
        {
          type = "nlua",
          request = "launch",
          name = "Debug Current Lua File",
          program = "${file}",
        },
      }

      -- Key mappings
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue/Start debugging" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
      vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step over" })
      vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Step out" })
      vim.keymap.set("n", "<leader>dt", function()
        dap.terminate()
        dapui.close()
      end, { desc = "Terminate and close DAP UI" })

      -- Start debug server command
      vim.keymap.set("n", "<leader>dS", function()
        require("osv").launch { port = 8086 }
        vim.notify "Lua debug server started on port 8086"
      end, { desc = "Start debug server" })

      -- Debug status and info command
      vim.api.nvim_create_user_command("DapStatus", function()
        print "=== DAP Status ==="
        print("Session active: " .. tostring(dap.session() ~= nil))
        if dap.session() then
          print("Session ID: " .. tostring(dap.session().id))
          print("Adapter: " .. tostring(dap.session().adapter.type))
        end

        -- Check if nlua server is running
        local handle =
          io.popen "netstat -an 2>/dev/null | grep 8086 || ss -tuln 2>/dev/null | grep 8086 || echo 'Port check failed'"
        if handle then
          local port_status = handle:read "*a"
          handle:close()
          print("Port 8086 status: " .. (port_status:match "8086" and "LISTENING" or "NOT LISTENING"))
        end

        print "Available configurations:"
        if dap.configurations.lua then
          for i, config in ipairs(dap.configurations.lua) do
            print("  " .. i .. ". " .. config.name)
          end
        end
      end, { desc = "Show DAP status and info" })

      vim.keymap.set("n", "<leader>dI", ":DapStatus<CR>", { desc = "Show DAP status and info" })
    end,
  },
}

local M = {}

local function log(msg, level)
  level = level or "INFO"
  print(string.format("[PioCD %s] %s", level, msg))
end

local function normalize_path_for_json(path)
  local home = os.getenv("HOME")
  if path:match("^" .. vim.pesc(home)) then
    return path:gsub("^" .. vim.pesc(home), "~")
  end
  return path
end

local function expand_path(path)
  if path:match("^~/") then
    local home = os.getenv("HOME")
    return path:gsub("^~/", home .. "/")
  end
  return path
end

local function parse_ccls_file(ccls_path)
  if vim.fn.filereadable(ccls_path) == 0 then
    return nil, "No .ccls file found"
  end

  local lines = vim.fn.readfile(ccls_path)
  local result = {
    c_flags = {},
    cpp_flags = {},
    includes = {},
    defines = {}
  }

  for _, line in ipairs(lines) do
    line = vim.trim(line)
    if line == "" then
      goto continue
    end

    if line:match("^%%c ") then
      local flags = vim.split(line:sub(4), "%s+")
      for _, flag in ipairs(flags) do
        if flag ~= "" and not flag:match("^%-I") and not flag:match("^%-D") then
          table.insert(result.c_flags, flag)
        end
      end
    elseif line:match("^%%cpp ") then
      local flags = vim.split(line:sub(6), "%s+")
      for _, flag in ipairs(flags) do
        if flag ~= "" and not flag:match("^%-I") and not flag:match("^%-D") then
          table.insert(result.cpp_flags, flag)
        end
      end
    elseif line:match("^%-I") then
      table.insert(result.includes, line)
    elseif line:match("^%-D") then
      table.insert(result.defines, line)
    end

    ::continue::
  end

  return result
end

local function find_source_files(project_dir)
  local extensions = { "c", "cpp", "cc", "cxx", "c++", "ino", "h", "hpp", "hxx", "h++" }
  local directories = { "src", "lib", "include", "test" }
  local files = {}

  for _, dir in ipairs(directories) do
    local full_dir = project_dir .. "/" .. dir
    if vim.fn.isdirectory(full_dir) == 1 then
      for _, ext in ipairs(extensions) do
        local find_cmd = string.format("find %s -name '*.%s' 2>/dev/null", vim.fn.shellescape(full_dir), ext)
        local found_files = vim.fn.systemlist(find_cmd)

        if vim.v.shell_error == 0 then
          for _, file in ipairs(found_files) do
            if file ~= "" then
              local rel_path = file:gsub("^" .. vim.pesc(project_dir) .. "/", "")
              table.insert(files, rel_path)
            end
          end
        end
      end
    end
  end

  if #files == 0 then
    table.insert(files, "src/main.cpp")
  end

  return files
end

local function generate_clangd_config(ccls_data)
  local config = {
    "CompileFlags:",
    "  Add:"
  }

  -- Arduino/PlatformIO compatibility flags (must come first)
  table.insert(config, "    - -std=gnu++17")
  table.insert(config, "    - -fpermissive")
  table.insert(config, "    - -Wno-error=narrowing")
  table.insert(config, "    - -Wno-redeclared-class-member")
  table.insert(config, "    - -Wno-error=redeclared-class-member")

  -- Add includes
  for _, include in ipairs(ccls_data.includes) do
    local path = include:sub(3)
    local expanded_path = expand_path(path)
    table.insert(config, "    - -I" .. expanded_path)
  end

  -- Add defines
  for _, define in ipairs(ccls_data.defines) do
    table.insert(config, "    - " .. define)
  end

  -- Add remaining C++ flags (excluding duplicates)
  for _, flag in ipairs(ccls_data.cpp_flags) do
    -- Skip flags we've already hardcoded for Arduino compatibility
    if not (flag == "-std=gnu++17" or
            flag == "-fpermissive" or
            flag == "-Wno-error=narrowing") then
      table.insert(config, "    - " .. flag)
    end
  end

  return config
end

local function generate_compile_commands(ccls_data, project_dir)
  local source_files = find_source_files(project_dir)
  local compile_commands = {}

  for _, file in ipairs(source_files) do
    local command_parts = { "clang++" }

    for _, include in ipairs(ccls_data.includes) do
      local path = include:sub(3)
      local norm_path = normalize_path_for_json(path)
      table.insert(command_parts, "-I" .. norm_path)
    end
    vim.list_extend(command_parts, ccls_data.defines)

    local is_cpp = file:match("%.cpp$") or file:match("%.cc$") or file:match("%.cxx$") or
                   file:match("%.c%+%+$") or file:match("%.ino$") or file:match("%.hpp$") or
                   file:match("%.hxx$") or file:match("%.h%+%+$")

    if is_cpp then
      vim.list_extend(command_parts, ccls_data.cpp_flags)
    else
      vim.list_extend(command_parts, ccls_data.c_flags)
    end

    table.insert(command_parts, "-c")
    table.insert(command_parts, file)

    table.insert(compile_commands, {
      directory = project_dir,
      file = file,
      command = table.concat(command_parts, " ")
    })
  end

  return compile_commands
end

function M.generate_clangd_files()
  local cwd = vim.fn.getcwd()
  local ccls_path = cwd .. "/.ccls"

  log("Parsing .ccls file...")
  local ccls_data, err = parse_ccls_file(ccls_path)
  if not ccls_data then
    log(err, "ERROR")
    return false
  end

  log("Generating .clangd config...")
  local clangd_config = generate_clangd_config(ccls_data)
  local clangd_path = cwd .. "/.clangd"

  local ok = pcall(vim.fn.writefile, clangd_config, clangd_path)
  if not ok then
    log("Failed to write .clangd file", "ERROR")
    return false
  end
  log("✅ Generated .clangd")

  log("Generating compile_commands.json...")
  local compile_commands = generate_compile_commands(ccls_data, cwd)
  local compile_commands_path = cwd .. "/compile_commands.json"

  local function format_json(data)
    local function escape_string(str)
      return str:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n'):gsub('\r', '\\r'):gsub('\t', '\\t')
    end

    local function format_command(cmd_str)
      local parts = vim.split(cmd_str, " ")
      local formatted_parts = {}
      local current_line = ""
      local max_line_length = 80

      for _, part in ipairs(parts) do
        if #current_line + #part + 1 > max_line_length and current_line ~= "" then
          table.insert(formatted_parts, current_line .. " \\")
          current_line = "  " .. part
        else
          if current_line == "" then
            current_line = part
          else
            current_line = current_line .. " " .. part
          end
        end
      end

      if current_line ~= "" then
        table.insert(formatted_parts, current_line)
      end

      return table.concat(formatted_parts, "\\n")
    end

    local lines = { "[" }
    for i, entry in ipairs(data) do
      table.insert(lines, "  {")
      table.insert(lines, string.format('    "directory": "%s",', escape_string(entry.directory)))
      table.insert(lines, string.format('    "file": "%s",', escape_string(entry.file)))

      local formatted_command = format_command(entry.command)
      table.insert(lines, string.format('    "command": "%s"', escape_string(formatted_command)))

      if i < #data then
        table.insert(lines, "  },")
      else
        table.insert(lines, "  }")
      end
    end
    table.insert(lines, "]")
    return lines
  end

  local formatted_lines = format_json(compile_commands)
  local write_ok = pcall(vim.fn.writefile, formatted_lines, compile_commands_path)
  if not write_ok then
    log("Failed to write compile_commands.json", "ERROR")
    return false
  end
  log("✅ Generated compile_commands.json")

  log("✅ Successfully generated both .clangd and compile_commands.json")
  return true
end

vim.api.nvim_create_user_command("PioCompiledb", function()
  M.generate_clangd_files()
end, { desc = "Generate .clangd and compile_commands.json from .ccls" })

vim.keymap.set("n", "<leader>pc", "<cmd>PioCompiledb<CR>", { desc = "Generate .clangd and compile_commands.json" })

return M
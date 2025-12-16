local M = {}

M.config = {
  markers = {
    new = "[ ]",
    pending = "[-]",
    done = "[x]",
  },
  archive_section = "## Archived",
  date_format = "%Y-%m-%d",
  timestamp_format = "%d-%m-%YT%H:%M:%S",
}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})
end

function M.create_todo(text)
  if not text or text == "" then
    vim.ui.input({ prompt = "New todo: " }, function(input)
      if input and input ~= "" then
        M.create_todo(input)
      end
    end)
    return
  end

  local marker = M.config.markers.new
  local line = vim.api.nvim_get_current_line()
  local indent = line:match("^(%s*)") or ""
  local timestamp = os.date(M.config.timestamp_format)
  local new_line = indent .. marker .. " " .. text .. " {new:" .. timestamp .. "}"

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, { new_line })
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
end

local function replace_marker(line, old_marker, new_marker)
  local start_pos, end_pos = line:find(old_marker, 1, true)
  if start_pos then
    return line:sub(1, start_pos - 1) .. new_marker .. line:sub(end_pos + 1)
  end
  return line
end

local function remove_timestamp(line, status)
  return line:gsub("%s*{" .. status .. ":[^}]+}", "")
end

local function has_timestamp(line, status)
  return line:find("{" .. status .. ":", 1, true) ~= nil
end

local function add_timestamp(line, status)
  if has_timestamp(line, status) then
    return line
  end
  local timestamp = os.date(M.config.timestamp_format)
  return line .. " {" .. status .. ":" .. timestamp .. "}"
end

local function get_indent_level(line)
  local indent = line:match("^(%s*)") or ""
  return #indent
end

local function mark_line_done(line)
  local new_line = line
  for name, marker in pairs(M.config.markers) do
    if name ~= "done" then
      new_line = replace_marker(new_line, marker, M.config.markers.done)
    end
  end
  return add_timestamp(new_line, "done")
end

function M.mark_done()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local current_line = lines[row]
  local current_indent = get_indent_level(current_line)

  local updated_lines = {}
  for i, line in ipairs(lines) do
    if i == row then
      table.insert(updated_lines, mark_line_done(line))
    elseif i > row then
      local line_indent = get_indent_level(line)
      if line_indent > current_indent and line:match("%[.%]") then
        table.insert(updated_lines, mark_line_done(line))
      elseif line_indent <= current_indent and line:match("%S") then
        table.insert(updated_lines, line)
        for j = i + 1, #lines do
          table.insert(updated_lines, lines[j])
        end
        break
      else
        table.insert(updated_lines, line)
      end
    else
      table.insert(updated_lines, line)
    end
  end

  if #updated_lines < #lines then
    for i = #updated_lines + 1, #lines do
      table.insert(updated_lines, lines[i])
    end
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, updated_lines)
end

function M.mark_pending()
  local line = vim.api.nvim_get_current_line()
  local new_line = line

  for name, marker in pairs(M.config.markers) do
    if name ~= "pending" then
      new_line = replace_marker(new_line, marker, M.config.markers.pending)
    end
  end

  new_line = remove_timestamp(new_line, "done")
  new_line = add_timestamp(new_line, "pending")

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
end

function M.mark_new()
  local line = vim.api.nvim_get_current_line()
  local new_line = line

  for name, marker in pairs(M.config.markers) do
    if name ~= "new" then
      new_line = replace_marker(new_line, marker, M.config.markers.new)
    end
  end

  new_line = remove_timestamp(new_line, "pending")
  new_line = remove_timestamp(new_line, "done")
  new_line = add_timestamp(new_line, "new")

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
end

function M.toggle_todo()
  local line = vim.api.nvim_get_current_line()

  if line:find(M.config.markers.done, 1, true) then
    M.mark_new()
  elseif line:find(M.config.markers.pending, 1, true) then
    M.mark_done()
  else
    M.mark_pending()
  end
end

function M.archive_completed()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local completed = {}
  local remaining = {}
  local archive_idx = nil

  for i, line in ipairs(lines) do
    if line:find(M.config.archive_section, 1, true) then
      archive_idx = i
    end

    if line:find(M.config.markers.done, 1, true) and (not archive_idx or i < archive_idx) then
      table.insert(completed, line)
    else
      table.insert(remaining, line)
    end
  end

  if #completed == 0 then
    vim.notify("No completed items to archive", vim.log.levels.INFO)
    return
  end

  if not archive_idx then
    table.insert(remaining, "")
    table.insert(remaining, M.config.archive_section)
  end

  local date_header = "### " .. os.date(M.config.date_format)
  table.insert(remaining, date_header)
  for _, item in ipairs(completed) do
    table.insert(remaining, item)
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, remaining)
  vim.notify(string.format("Archived %d item(s)", #completed), vim.log.levels.INFO)
end

function M.move_up()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  if row <= 1 then
    return
  end
  vim.cmd("move -2")
  vim.api.nvim_win_set_cursor(0, { row - 1, 0 })
end

function M.move_down()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local total = vim.api.nvim_buf_line_count(0)
  if row >= total then
    return
  end
  vim.cmd("move +1")
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
end

function M.add_tag(tag)
  if not tag or tag == "" then
    vim.ui.input({ prompt = "Tag name: " }, function(input)
      if input and input ~= "" then
        M.add_tag(input)
      end
    end)
    return
  end

  tag = tag:gsub("^@", "")

  local line = vim.api.nvim_get_current_line()

  if line:find("@" .. tag, 1, true) then
    vim.notify("Tag @" .. tag .. " already exists", vim.log.levels.WARN)
    return
  end

  local timestamp_pos = line:find("%s*{%w+:[^}]+}")
  local new_line
  if timestamp_pos then
    local before = line:sub(1, timestamp_pos - 1):gsub("%s+$", "")
    local after = line:sub(timestamp_pos)
    new_line = before .. " @" .. tag .. " " .. after
  else
    new_line = line .. " @" .. tag
  end

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
end

function M.remove_tag(tag)
  local line = vim.api.nvim_get_current_line()

  if not tag or tag == "" then
    local tags = {}
    for t in line:gmatch("@(%w+)") do
      table.insert(tags, t)
    end

    if #tags == 0 then
      vim.notify("No tags on this line", vim.log.levels.INFO)
      return
    end

    vim.ui.select(tags, { prompt = "Remove tag:" }, function(choice)
      if choice then
        M.remove_tag(choice)
      end
    end)
    return
  end

  tag = tag:gsub("^@", "")

  local new_line = line:gsub("%s*@" .. tag .. "(%s*)", " ")
  new_line = new_line:gsub("%s+", " "):gsub("%s+$", "")

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row - 1, row, false, { new_line })
end

function M.list_tags()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local tags = {}
  local tag_set = {}

  for _, line in ipairs(lines) do
    for tag in line:gmatch("@(%w+)") do
      if not tag_set[tag] then
        tag_set[tag] = true
        table.insert(tags, tag)
      end
    end
  end

  table.sort(tags)
  return tags
end

function M.find_tag(tag)
  if not tag or tag == "" then
    local tags = M.list_tags()
    if #tags == 0 then
      vim.notify("No tags in this file", vim.log.levels.INFO)
      return
    end

    vim.ui.select(tags, { prompt = "Find tag:" }, function(choice)
      if choice then
        M.find_tag(choice)
      end
    end)
    return
  end

  tag = tag:gsub("^@", "")
  local pattern = "@" .. tag

  local found = vim.fn.search(pattern, "w")
  if found == 0 then
    vim.notify("Tag @" .. tag .. " not found", vim.log.levels.INFO)
  end
end

function M.find_todo_file()
  local path = vim.fn.expand("%:p:h")
  if path == "" then
    path = vim.fn.getcwd()
  end

  local todo_names = { ".TODO", "TODO", ".todo", "todo.TODO" }

  while path and path ~= "" and path ~= "/" do
    for _, name in ipairs(todo_names) do
      local todo_path = path .. "/" .. name
      if vim.fn.filereadable(todo_path) == 1 then
        return todo_path
      end
    end
    path = vim.fn.fnamemodify(path, ":h")
  end

  for _, name in ipairs(todo_names) do
    local todo_path = "/" .. name
    if vim.fn.filereadable(todo_path) == 1 then
      return todo_path
    end
  end

  return nil
end

function M.open_todo()
  local todo_file = M.find_todo_file()
  local cwd = vim.fn.getcwd()
  local git_root = vim.fn.systemlist("git rev-parse --show-toplevel 2>/dev/null")[1]
  if not git_root or git_root == "" then
    git_root = nil
  end

  local options = {}
  local actions = {}

  if todo_file then
    local display_path = todo_file
    if todo_file:sub(1, #cwd) == cwd then
      display_path = "." .. todo_file:sub(#cwd + 1)
    end
    table.insert(options, "Open " .. display_path)
    table.insert(actions, function()
      vim.cmd("edit " .. vim.fn.fnameescape(todo_file))
    end)
  end

  local current_dir = vim.fn.expand("%:p:h")
  if current_dir == "" then
    current_dir = cwd
  end
  local current_display = current_dir
  if current_dir:sub(1, #cwd) == cwd then
    current_display = "." .. current_dir:sub(#cwd + 1)
  end
  if current_display == "." then
    current_display = "./"
  end
  table.insert(options, "Create in " .. current_display)
  table.insert(actions, function()
    vim.cmd("edit " .. vim.fn.fnameescape(current_dir .. "/.TODO"))
  end)

  if git_root then
    local root_display = git_root
    if git_root:sub(1, #cwd) == cwd then
      root_display = "." .. git_root:sub(#cwd + 1)
    end
    if root_display == "." then
      root_display = "./"
    end
    table.insert(options, "Create in " .. root_display .. " (project root)")
    table.insert(actions, function()
      vim.cmd("edit " .. vim.fn.fnameescape(git_root .. "/.TODO"))
    end)
  elseif cwd ~= current_dir then
    table.insert(options, "Create in ./ (cwd)")
    table.insert(actions, function()
      vim.cmd("edit " .. vim.fn.fnameescape(cwd .. "/.TODO"))
    end)
  end

  table.insert(options, "Cancel")
  table.insert(actions, function() end)

  vim.ui.select(options, { prompt = "TODO file:" }, function(choice, idx)
    if idx and actions[idx] then
      actions[idx]()
    end
  end)
end

function M.add_subtask(text)
  if not text or text == "" then
    vim.ui.input({ prompt = "Subtask: " }, function(input)
      if input and input ~= "" then
        M.add_subtask(input)
      end
    end)
    return
  end

  local line = vim.api.nvim_get_current_line()
  local indent = line:match("^(%s*)") or ""
  local new_indent = indent .. "  "
  local marker = M.config.markers.new
  local timestamp = os.date(M.config.timestamp_format)
  local new_line = new_indent .. marker .. " " .. text .. " {new:" .. timestamp .. "}"

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, { new_line })
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
end

function M.add_note(text)
  if not text or text == "" then
    vim.ui.input({ prompt = "Note: " }, function(input)
      if input and input ~= "" then
        M.add_note(input)
      end
    end)
    return
  end

  local line = vim.api.nvim_get_current_line()
  local indent = line:match("^(%s*)") or ""
  local new_indent = indent .. "  "
  local new_line = new_indent .. "> " .. text

  local row = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(0, row, row, false, { new_line })
  vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
end

function M.format()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local formatted = {}

  for _, line in ipairs(lines) do
    local formatted_line = line

    formatted_line = formatted_line:gsub("%[X%]", M.config.markers.done)
    formatted_line = formatted_line:gsub("%[x%]", M.config.markers.done)
    formatted_line = formatted_line:gsub("%[ %]", M.config.markers.new)
    formatted_line = formatted_line:gsub("%[%]", M.config.markers.new)
    formatted_line = formatted_line:gsub("%[%-%]", M.config.markers.pending)

    formatted_line = formatted_line:gsub("%s+$", "")

    table.insert(formatted, formatted_line)
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted)
  vim.notify("Formatted TODO file", vim.log.levels.INFO)
end

return M

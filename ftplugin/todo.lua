if vim.b.did_ftplugin_ndo then
  return
end
vim.b.did_ftplugin_ndo = true

local ndo = require("ndo")

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = 0, silent = true, desc = desc })
end

map("n", "<leader>tn", ndo.create_todo, "New todo")
map("n", "<leader>tt", ndo.toggle_todo, "Toggle todo")
map("n", "<leader>td", ndo.mark_done, "Mark done [x]")
map("n", "<leader>tp", ndo.mark_pending, "Mark pending [-]")
map("n", "<leader>tr", ndo.mark_new, "Reset to new [ ]")
map("n", "<leader>ta", ndo.archive_completed, "Archive done")
map("n", "<leader>tF", ndo.format, "Format TODO file")
map("n", "<leader>tk", ndo.move_up, "Move todo up")
map("n", "<leader>tj", ndo.move_down, "Move todo down")
map("n", "<leader>t@", ndo.add_tag, "Add tag")
map("n", "<leader>tX", ndo.remove_tag, "Remove tag")
map("n", "<leader>t/", ndo.find_tag, "Find by tag")
map("n", "<leader>ts", ndo.add_subtask, "Add subtask")
map("n", "<leader>tN", ndo.add_note, "Add note")

vim.opt_local.commentstring = "// %s"
vim.opt_local.conceallevel = 2
vim.opt_local.concealcursor = "nc"

local ns = vim.api.nvim_create_namespace("ndo_timestamps")

local function parse_timestamp(timestamp)
  local day, month, year, hour, min, sec = timestamp:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)")
  if not day then return nil end
  return os.time({
    year = tonumber(year),
    month = tonumber(month),
    day = tonumber(day),
    hour = tonumber(hour),
    min = tonumber(min),
    sec = tonumber(sec),
  })
end

local function format_duration(seconds)
  if seconds < 60 then
    return string.format("%ds", seconds)
  elseif seconds < 3600 then
    return string.format("%dm", math.floor(seconds / 60))
  elseif seconds < 86400 then
    local hours = math.floor(seconds / 3600)
    local mins = math.floor((seconds % 3600) / 60)
    if mins > 0 then
      return string.format("%dh %dm", hours, mins)
    end
    return string.format("%dh", hours)
  else
    local days = math.floor(seconds / 86400)
    local hours = math.floor((seconds % 86400) / 3600)
    if hours > 0 then
      return string.format("%dd %dh", days, hours)
    end
    return string.format("%dd", days)
  end
end

local function format_single_timestamp(status, timestamp, is_current_status)
  local day, month, year, hour, min = timestamp:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+)")
  if not day then return nil end

  local months = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" }
  local month_name = months[tonumber(month)] or month

  local icons = { new = "○", pending = "◐", done = "●" }
  local icon = icons[status] or "•"

  if status == "pending" and is_current_status then
    local ts_time = parse_timestamp(timestamp)
    if ts_time then
      local elapsed = os.time() - ts_time
      local duration = format_duration(elapsed)
      return string.format("%s %s", icon, duration)
    end
  end

  return string.format("%s %s %s %s:%s", icon, day, month_name, hour, min)
end

local function parse_timestamps(line)
  local timestamps = {}
  for status, ts in line:gmatch("{(%w+):([^}]+)}") do
    table.insert(timestamps, { status = status, timestamp = ts })
  end
  return timestamps
end

local function find_timestamps_start(line)
  return line:find("%s*{%w+:[^}]+}")
end

local function get_current_status(line)
  if line:find("%[x%]") or line:find("%[X%]") then
    return "done"
  elseif line:find("%[%-%]") then
    return "pending"
  elseif line:find("%[ %]") then
    return "new"
  end
  return nil
end

local function get_content_end(line)
  local pos = find_timestamps_start(line)
  if pos then
    local content = line:sub(1, pos - 1)
    return #content:gsub("%s+$", "")
  end
  return #line
end

local function update_virtual_text()
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)

  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    local timestamps = parse_timestamps(line)
    if #timestamps > 0 then
      local current_status = get_current_status(line)

      local parts = {}

      if current_status == "done" then
        for _, ts in ipairs(timestamps) do
          if ts.status == "done" then
            local formatted = format_single_timestamp(ts.status, ts.timestamp, false)
            if formatted then
              table.insert(parts, formatted)
            end
            break
          end
        end
      elseif current_status == "pending" then
        for _, ts in ipairs(timestamps) do
          if ts.status == "pending" then
            local formatted = format_single_timestamp(ts.status, ts.timestamp, false)
            if formatted then
              table.insert(parts, formatted)
            end
            local ts_time = parse_timestamp(ts.timestamp)
            if ts_time then
              local elapsed = os.time() - ts_time
              table.insert(parts, format_duration(elapsed))
            end
            break
          end
        end
      else
        for _, ts in ipairs(timestamps) do
          if ts.status == "new" then
            local formatted = format_single_timestamp(ts.status, ts.timestamp, false)
            if formatted then
              table.insert(parts, formatted)
            end
            break
          end
        end
      end

      if #parts > 0 then
        local display = "  " .. table.concat(parts, " → ")
        local content_end = get_content_end(line)

        vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, content_end, {
          end_col = #line,
          conceal = "",
        })
        vim.api.nvim_buf_set_extmark(bufnr, ns, i - 1, 0, {
          virt_text = { { display, "Comment" } },
          virt_text_pos = "eol",
        })
      end
    end
  end
end

local in_insert_mode = false

local augroup = vim.api.nvim_create_augroup("NdoVirtualText", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged" }, {
  group = augroup,
  buffer = 0,
  callback = function()
    if not in_insert_mode then
      update_virtual_text()
    end
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  group = augroup,
  buffer = 0,
  callback = function()
    in_insert_mode = true
    vim.opt_local.conceallevel = 0
    vim.api.nvim_buf_clear_namespace(0, ns, 0, -1)
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  group = augroup,
  buffer = 0,
  callback = function()
    in_insert_mode = false
    vim.opt_local.conceallevel = 2
    update_virtual_text()
  end,
})

update_virtual_text()

local timer = vim.loop.new_timer()
timer:start(60000, 60000, vim.schedule_wrap(function()
  if vim.api.nvim_buf_is_valid(vim.api.nvim_get_current_buf()) then
    update_virtual_text()
  end
end))

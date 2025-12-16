if vim.g.loaded_ndo then
  return
end
vim.g.loaded_ndo = true

vim.api.nvim_create_user_command("NdoCreate", function()
  require("ndo").create_todo()
end, { desc = "Create a new todo item" })

vim.api.nvim_create_user_command("NdoDone", function()
  require("ndo").mark_done()
end, { desc = "Mark todo as done [x]" })

vim.api.nvim_create_user_command("NdoPending", function()
  require("ndo").mark_pending()
end, { desc = "Mark todo as pending [-]" })

vim.api.nvim_create_user_command("NdoNew", function()
  require("ndo").mark_new()
end, { desc = "Mark todo as new [ ]" })

vim.api.nvim_create_user_command("NdoToggle", function()
  require("ndo").toggle_todo()
end, { desc = "Toggle todo status" })

vim.api.nvim_create_user_command("NdoArchive", function()
  require("ndo").archive_completed()
end, { desc = "Archive done todos" })

vim.api.nvim_create_user_command("NdoFormat", function()
  require("ndo").format()
end, { desc = "Format TODO file" })

vim.api.nvim_create_user_command("NdoMoveUp", function()
  require("ndo").move_up()
end, { desc = "Move todo up" })

vim.api.nvim_create_user_command("NdoMoveDown", function()
  require("ndo").move_down()
end, { desc = "Move todo down" })

vim.api.nvim_create_user_command("NdoAddTag", function(opts)
  require("ndo").add_tag(opts.args)
end, { desc = "Add tag to todo", nargs = "?" })

vim.api.nvim_create_user_command("NdoRemoveTag", function(opts)
  require("ndo").remove_tag(opts.args)
end, { desc = "Remove tag from todo", nargs = "?" })

vim.api.nvim_create_user_command("NdoFindTag", function(opts)
  require("ndo").find_tag(opts.args)
end, { desc = "Find todos with tag", nargs = "?" })

vim.api.nvim_create_user_command("NdoOpen", function()
  require("ndo").open_todo()
end, { desc = "Open closest TODO file" })

vim.api.nvim_create_user_command("NdoSubtask", function()
  require("ndo").add_subtask()
end, { desc = "Add subtask" })

vim.api.nvim_create_user_command("NdoNote", function()
  require("ndo").add_note()
end, { desc = "Add note" })

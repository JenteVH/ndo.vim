vim.filetype.add({
  extension = {
    TODO = "todo",
  },
  filename = {
    ["TODO"] = "todo",
    [".TODO"] = "todo",
  },
  pattern = {
    [".*%.TODO"] = "todo",
  },
})

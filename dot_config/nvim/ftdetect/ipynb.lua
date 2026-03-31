-- Set the filetype for .ipynb files
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  pattern = "*.ipynb",
  command = "set filetype=ipynb",
})

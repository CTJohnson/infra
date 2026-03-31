return {
  "goerz/jupytext.nvim",
  version = "0.2.0", -- Pinning to a specific version is good practice
  opts = {
    -- This is the key option to enable automatic synchronization on save.
    autosync = true,
    -- You can customize which file patterns are considered for syncing.
    -- The defaults are usually sufficient.
    sync_patterns = { "*.md", "*.py", "*.jl", "*.R", "*.Rmd", "*.qmd" },
    -- This option ensures the original .ipynb is updated with outputs preserved.
    update = true,
  },
}

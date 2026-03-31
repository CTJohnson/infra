return {
  "snacks.nvim",
  opts = {
    explorer = {
      -- your explorer configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      layout = { preset = "vertical", position = "right", preview = true },
    },
    picker = {
      sources = {
        explorer = {
          -- your explorer picker configuration comes here
          -- or leave it empty to use the default settings
          layout = { preset = "vertical", position = "right", preview = true },
        },
      },
    },
    dashboard = {
      preset = {
        pick = function(cmd, opts)
          return LazyVim.pick(cmd, opts)()
        end,
        header = [[
        Another fine production of
██████╗ ██╗██╗  ██╗███████╗███╗   ██╗ ██████╗███████╗
██╔══██╗██║╚██╗██╔╝██╔════╝████╗  ██║██╔════╝██╔════╝
██║  ██║██║ ╚███╔╝ █████╗  ██╔██╗ ██║██║     █████╗  
██║  ██║██║ ██╔██╗ ██╔══╝  ██║╚██╗██║██║     ██╔══╝  
██████╔╝██║██╔╝ ██╗███████╗██║ ╚████║╚██████╗███████╗
╚═════╝ ╚═╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝╚══════╝
        die Mobiliar
 ]],
        -- stylua: ignore
        ---@type snacks.dashboard.Item[]
        keys = {
          { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
          { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
          { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
          { icon = " ", key = "r", desc = "Recent Files", action = ":lua Snacks.dashboard.pick('oldfiles')" },
          { icon = " ", key = "c", desc = "Config", action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})" },
          { icon = " ", key = "s", desc = "Restore Session", section = "session" },
          { icon = " ", key = "x", desc = "Lazy Extras", action = ":LazyExtras" },
          { icon = "󰒲 ", key = "l", desc = "Lazy", action = ":Lazy" },
          { icon = " ", key = "q", desc = "Quit", action = ":qa" },
        },
      },
    },
  },
}

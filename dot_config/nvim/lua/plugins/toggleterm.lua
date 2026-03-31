return {
    {'akinsho/toggleterm.nvim',
    version = '*',
    keys = {
      { '<leader>td', '<cmd>ToggleTerm size=40 dir=$PWD direction=float<cr>', desc = 'Open a horizontal terminal at the Desktop directory' }
      },
			config = true,
  },

}

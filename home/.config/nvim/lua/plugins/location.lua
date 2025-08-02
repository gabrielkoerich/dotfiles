return {
  {
    'SmiteshP/nvim-navic',
    config = function()
      local navic = require('nvim-navic')
      local get_icon_color = require('nvim-web-devicons').get_icon_color

      local winbar_ignore_filetypes = {
        NvimTree = true,
      }

      navic.setup({
        highlight = true,
        safe_output = true,
        separator = ' › ',
        icons = {
          File = ' ',
          Module = ' ',
          Namespace = ' ',
          Package = ' ',
          Class = ' ',
          Method = ' ',
          Property = ' ',
          Field = ' ',
          Constructor = ' ',
          Enum = ' ',
          Interface = ' ',
          Function = ' ',
          Variable = ' ',
          Constant = ' ',
          String = ' ',
          Number = ' ',
          Boolean = ' ',
          Array = ' ',
          Object = ' ',
          Key = ' ',
          Null = ' ',
          EnumMember = ' ',
          Struct = ' ',
          Event = ' ',
          Operator = ' ',
          TypeParameter = ' ',
        },
      })

      function Breadcrumbs()
        local location = navic.get_location()

        local current_file = vim.fn.expand('%:t')
        local current_file_extension = vim.fn.fnamemodify(current_file, ':e')

        if current_file == '' then
          current_file = '[No Name]'
        end

        local icon, fg = get_icon_color(current_file, current_file_extension, { default = true })
        local bg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID('Normal')), 'bg')

        vim.api.nvim_set_hl(0, 'Winbar', { bg = bg })
        vim.api.nvim_set_hl(0, 'WinbarNC', { bg = bg })
        vim.api.nvim_set_hl(0, 'BreadcrumbsIconColor', { fg = fg, bg = bg })

        local parent_folders = {}

        for i in string.gmatch(vim.fn.expand('%:h:r'), '([^/]+)') do
          table.insert(parent_folders, i)
        end

        local parent_folders_string = table.concat(parent_folders, ' › ')
        local has_parent_folders = parent_folders_string ~= '' and parent_folders_string ~= '.'

        return ' '
          .. (has_parent_folders and parent_folders_string .. ' › ' or '')
          .. table.concat({
            '%#BreadcrumbsIconColor#' .. icon .. '%#Winbar# ' .. current_file,
            location == '' and '…' or location,
          }, ' › ')
      end

      vim.api.nvim_create_autocmd('BufWinEnter', {
        pattern = '*',
        callback = function()
          local filetype = vim.bo.filetype
          local buftype = vim.bo.buftype

          local window_name = vim.api.nvim_buf_get_name(0)
          local window_config = vim.api.nvim_win_get_config(0).relative

          if
            winbar_ignore_filetypes[filetype]
            or filetype == ''
            or buftype ~= ''
            or window_name == ''
            or window_config ~= ''
          then
            return
          end

          vim.wo.winbar = '%{%v:lua.Breadcrumbs()%}'
        end,
      })
    end,
  },
}

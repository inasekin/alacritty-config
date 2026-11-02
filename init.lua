-- ~/.config/nvim/init.lua
-- Neovim «как WebStorm»: тема JetBrains Dark, поиск, дерево проекта, вкладки, git,
-- языковые серверы для C/C++, C#, Java, JavaScript/TypeScript (Node.js), PHP и Python,
-- ESLint и Prettier, подсветка Treesitter, сессии.
-- Серверы ставятся автоматически через Mason (прогресс: :Mason).
-- Для подсветки Treesitter нужен tree-sitter-cli: brew install tree-sitter-cli

vim.g.mapleader = " "
vim.o.termguicolors = true

-- ---------- Окружение для языковых серверов ----------
-- C#: .NET SDK из нативного Homebrew (brew install dotnet)
local dotnet_root = "/opt/homebrew/opt/dotnet/libexec"
if vim.uv.fs_stat(dotnet_root) then
  vim.env.DOTNET_ROOT = dotnet_root
end

-- Java: сервер jdtls требует Java 21+. Если стоит openjdk из Homebrew — используем его только для jdtls.
for _, home in ipairs({
  "/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home",
  "/opt/homebrew/opt/openjdk/libexec/openjdk.jdk/Contents/Home",
}) do
  if vim.uv.fs_stat(home) then
    vim.lsp.config("jdtls", {
      cmd_env = { JAVA_HOME = home, PATH = home .. "/bin:" .. vim.env.PATH },
    })
    break
  end
end

-- ---------- Менеджер плагинов lazy.nvim (ставится сам при первом запуске) ----------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- Тема на палитре JetBrains "Dark"
  { "doums/dark.nvim", lazy = false, priority = 1000 },

  -- Поиск: файлы, текст по проекту, символы (Cmd+Shift+O, Cmd+Shift+F, Cmd+O)
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" } },

  -- Дерево проекта (Cmd+1)
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", "nvim-tree/nvim-web-devicons" },
    opts = {
      window = {
        position = "right", width = 35,                   -- проводник справа
        mappings = {
          -- Y — скопировать полный путь файла в буфер обмена
          ["Y"] = function(state)
            local path = state.tree:get_node():get_id()
            vim.fn.setreg("+", path)
            vim.notify("Скопирован путь: " .. path)
          end,
          -- gO — показать файл в Finder
          ["gO"] = function(state)
            vim.fn.jobstart({ "open", "-R", state.tree:get_node():get_id() }, { detach = true })
          end,
          -- T — открыть терминал в этой папке
          ["T"] = function(state)
            local path = state.tree:get_node():get_id()
            if vim.fn.isdirectory(path) == 0 then path = vim.fn.fnamemodify(path, ":h") end
            require("webstorm").new_terminal(path)
          end,
        },
      },
      filesystem = {
        follow_current_file = { enabled = true },
        -- Показываем скрытые и игнорируемые git файлы (приглушённым цветом), как в WebStorm
        filtered_items = {
          visible = true,
          hide_dotfiles = false,
          hide_gitignored = false,
          never_show = { ".DS_Store", ".git" },
        },
      },
    },
  },

  -- Подсветка синтаксиса и сворачивание блоков (Treesitter)
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local langs = {
        "bash", "c", "c_sharp", "cpp", "css", "diff", "dockerfile", "gitcommit", "git_rebase",
        "html", "java", "javascript", "jsdoc", "json", "lua", "markdown", "markdown_inline",
        "php", "python", "query", "regex", "scss", "sql", "toml", "tsx", "typescript",
        "vim", "vimdoc", "yaml",
      }
      if vim.fn.executable("tree-sitter") == 1 then
        require("nvim-treesitter").install(langs)
      else
        vim.schedule(function()
          vim.notify("Для подсветки синтаксиса установите: brew install tree-sitter-cli", vim.log.levels.WARN)
        end)
      end
      vim.api.nvim_create_autocmd("FileType", {
        callback = function(args)
          if pcall(vim.treesitter.start, args.buf) then
            vim.wo.foldmethod = "expr"
            vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          end
        end,
      })
    end,
  },

  -- Форматирование: Prettier из проекта (если в проекте есть его конфиг), иначе языковой сервер
  {
    "stevearc/conform.nvim",
    cmd = "ConformInfo",
    opts = {
      formatters_by_ft = (function()
        local t = {}
        for _, ft in ipairs({ "javascript", "javascriptreact", "typescript", "typescriptreact", "vue",
          "css", "scss", "less", "html", "json", "jsonc", "yaml", "markdown", "graphql" }) do
          t[ft] = { "prettier" }
        end
        t.python = { "ruff_format" }
        return t
      end)(),
      default_format_opts = { lsp_format = "fallback" },
      formatters = { prettier = { require_cwd = true } },
    },
  },

  -- Вкладки открытых файлов сверху
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
      options = {
        diagnostics = "nvim_lsp",
        close_command = function(n) require("mini.bufremove").delete(n, false) end,
        right_mouse_command = false,
        offsets = { { filetype = "neo-tree", text = "Проект", highlight = "Directory", separator = true } },
        always_show_bufferline = true,
      },
    },
  },

  -- Автозакрытие скобок и кавычек; закрытие файла без поломки раскладки окон
  {
    "nvim-mini/mini.nvim",
    version = false,
    config = function()
      require("mini.pairs").setup()
      require("mini.bufremove").setup()
    end,
  },

  -- Подсказка клавиш: нажали пробел — видно, что можно нажать дальше
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      delay = 400,
      spec = {
        { "<leader>g", group = "Git" },
        { "<leader>e", group = "ESLint" },
        { "<leader>s", group = "Сессия" },
      },
    },
  },

  -- Строка состояния снизу: ветка, изменения, ошибки, язык
  {
    "nvim-lualine/lualine.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    opts = {
      options = { theme = "auto", globalstatus = true, component_separators = "│", section_separators = "" },
      extensions = { "neo-tree", "lazy", "mason", "trouble" },
    },
  },

  -- Сессии: при запуске в проекте открываются те же файлы
  { "folke/persistence.nvim", lazy = false, opts = {} },

  -- Замена по всему проекту (Replace in Files)
  { "MagicDuck/grug-far.nvim", cmd = "GrugFar", opts = {} },

  -- Окно Problems: все ошибки и предупреждения
  { "folke/trouble.nvim", cmd = "Trouble", opts = {} },

  -- Git: изменённые строки слева от номеров, автор строки (blame), откат изменений
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = true,  -- автор и дата текущей строки серым текстом справа
      current_line_blame_opts = { delay = 500 },
      current_line_blame_formatter = "<author>, <author_time:%d.%m.%Y> · <summary>",
    },
  },

  -- Git: список изменённых файлов с диффом и история файла (как окно Commit в WebStorm)
  { "sindrets/diffview.nvim", cmd = { "DiffviewOpen", "DiffviewFileHistory" } },

  -- Автодополнение с документацией, как в IDE
  {
    "saghen/blink.cmp",
    version = "1.*",
    opts = {
      -- Enter — принять, Ctrl+Space — показать, ↑/↓ — выбор
      keymap = {
        preset = "enter",
        -- Shift+Tab: в шаблоне — к предыдущему полю, иначе убрать отступ строки (как в WebStorm)
        ["<S-Tab>"] = {
          "snippet_backward",
          function()
            vim.api.nvim_feedkeys(vim.keycode("<C-d>"), "n", false)
            return true
          end,
        },
      },
      completion = { documentation = { auto_show = true, auto_show_delay_ms = 300 } },
      signature = { enabled = true },  -- подсказка параметров при вводе
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
    },
  },

  -- Языковые серверы: Mason скачивает их сам и включает для нужных файлов
  {
    "mason-org/mason-lspconfig.nvim",
    lazy = false,
    dependencies = {
      { "mason-org/mason.nvim", opts = {} },
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        "clangd",        -- C / C++
        "csharp_ls",     -- C#   (нужен .NET SDK: brew install dotnet)
        "jdtls",         -- Java (нужна Java 21+)
        "ts_ls",         -- JavaScript / TypeScript / Node.js
        "intelephense",  -- PHP
        "pyright",       -- Python: автодополнение, переходы, типы
        "ruff",          -- Python: линтер и форматирование
        "eslint",        -- ESLint для JS/TS (берёт конфиг и версию из проекта)
      },
    },
  },
}, { checker = { enabled = false } })

-- ---------- Автодополнение и ошибки, как в IDE ----------
-- Сообщаем серверам, что редактор умеет полноценное автодополнение (blink.cmp)
local ok_blink, blink = pcall(require, "blink.cmp")
if ok_blink then
  vim.lsp.config("*", { capabilities = blink.get_lsp_capabilities() })
end
vim.diagnostic.config({ virtual_text = true, severity_sort = true })

-- У Python два сервера: подсказки при наведении оставляем за pyright
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "ruff" then client.server_capabilities.hoverProvider = false end
  end,
})

-- ---------- Хоткеи и внешний вид в стиле WebStorm ----------
require("webstorm")

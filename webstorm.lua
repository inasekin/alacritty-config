-- ~/.config/nvim/lua/webstorm.lua
-- Подключение: добавьте в init.lua строку  require("webstorm")
-- Нужен Neovim >= 0.10. Рекомендуемые плагины:
--   nvim-telescope/telescope.nvim  — поиск файлов, символов, текста
--   doums/dark.nvim                — тема на палитре JetBrains "Dark"
--   nvim-neo-tree/neo-tree.nvim    — дерево проекта (необязательно, иначе netrw)
-- <D-…> = Cmd на macOS (Super на Linux), их присылает Alacritty из alacritty.toml.

-- ---------- Внешний вид как в IDE ----------
local o = vim.opt
o.termguicolors = true
o.number = true
o.cursorline = true
o.signcolumn = "yes"
o.mouse = "a"
o.clipboard = "unnamedplus"
o.scrolloff = 5
o.colorcolumn = "120"        -- правая граница как в WebStorm
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.updatetime = 300
o.undofile = true             -- отмена изменений работает и после закрытия файла (как Local History)
o.foldlevel = 99              -- блоки кода развёрнуты по умолчанию
o.foldlevelstart = 99
o.foldcolumn = "1"            -- значки сворачивания слева, по ним можно кликать
o.fillchars = { foldopen = "▾", foldclose = "▸", fold = " ", foldsep = " ", eob = " " }
o.sessionoptions = "buffers,curdir,folds,help,tabpages,winsize,globals,skiprtp"

-- Русская раскладка: команды обычного режима (dd, yy, hjkl и т.д.) работают и на ней
o.langmap = table.concat({
  "ФИСВУАПРШОЛДЬТЩЗЙКЫЕГМЦЧНЯ;ABCDEFGHIJKLMNOPQRSTUVWXYZ",
  "фисвуапршолдьтщзйкыегмцчня;abcdefghijklmnopqrstuvwxyz",
  "х[", "ъ]", "Х{", "Ъ}", "ж\\;", "Ж:", "э'", "Э\\\"", "б\\,", "Б<", "ю.", "Ю>",
}, ",")
pcall(vim.cmd.colorscheme, "dark")

-- ---------- Хелперы ----------
local function map(modes, lhs, rhs, desc, opts)
  opts = vim.tbl_extend("force", { silent = true, desc = desc }, opts or {})
  for _, key in ipairs(type(lhs) == "table" and lhs or { lhs }) do
    vim.keymap.set(modes, key, rhs, opts)
  end
end

-- Cmd+Shift+буква может прийти как <D-S-x> или <D-X> — вешаем оба варианта
local function ds(ch) return { "<D-S-" .. ch .. ">", "<D-" .. ch:upper() .. ">" } end

local function tb(name, args)
  return function()
    local ok, builtin = pcall(require, "telescope.builtin")
    if ok then builtin[name](args or {})
    else vim.notify("Установите telescope.nvim", vim.log.levels.WARN) end
  end
end

local function diag(count)
  return function()
    if vim.diagnostic.jump then vim.diagnostic.jump({ count = count, float = true })
    elseif count > 0 then vim.diagnostic.goto_next()
    else vim.diagnostic.goto_prev() end
  end
end

-- ---------- Файл и редактирование ----------
map({ "n", "i", "v" }, "<D-s>", "<cmd>write<cr>", "Save")
map("n", "<D-z>", "u", "Undo")
map("i", "<D-z>", "<C-o>u", "Undo")
map("n", ds("z"), "<C-r>", "Redo")
map("i", ds("z"), "<C-o><C-r>", "Redo")
map({ "n", "i", "v" }, "<D-a>", "<esc>ggVG", "Select all")

-- Буфер обмена как в WebStorm (Cmd+V обрабатывает сам Alacritty — вставка работает в любом режиме)
map("v", "<D-c>", '"+y', "Копировать выделение")
map("n", "<D-c>", '"+yy', "Копировать строку")
map("i", "<D-c>", '<C-o>"+yy', "Копировать строку")
map("v", "<D-x>", '"+d', "Вырезать выделение")
map("n", "<D-x>", '"+dd', "Вырезать строку")
map("i", "<D-x>", '<C-o>"+dd', "Вырезать строку")

map("n", "<D-d>", "<cmd>t.<cr>", "Duplicate line")
map("i", "<D-d>", "<cmd>t.<cr>", "Duplicate line")
map("v", "<D-d>", ":t'><cr>gv", "Duplicate selection")

map("n", "<D-BS>", '"_dd', "Delete line")
map("i", "<D-BS>", '<C-o>"_dd', "Delete line")
map("v", "<D-BS>", '"_d', "Delete selection")

-- gc/gcc — встроенное комментирование Neovim 0.10+
map("n", "<D-/>", "gcc", "Comment line", { remap = true })
map("v", "<D-/>", "gcgv", "Comment selection", { remap = true })
map("i", "<D-/>", "<C-o>gcc", "Comment line", { remap = true })

map("n", "<D-f>", "/", "Find in file", { silent = false })
map("n", "<D-r>", ":%s/", "Replace in file", { silent = false })
map("v", "<D-r>", ":s/", "Replace in selection", { silent = false })

-- Tab / Shift+Tab — отступ, как в WebStorm
map("v", "<Tab>", ">gv", "Сдвинуть выделение вправо")
map("v", "<S-Tab>", "<gv", "Сдвинуть выделение влево")
map("n", "<S-Tab>", "<<", "Убрать отступ строки")
map("i", "<S-Tab>", "<C-d>", "Убрать отступ строки")  -- запасной вариант, если blink.cmp не загружен

-- Alt+Shift+↑/↓ — перенос строки
map("n", "<M-S-Down>", "<cmd>m .+1<cr>==", "Move line down")
map("n", "<M-S-Up>", "<cmd>m .-2<cr>==", "Move line up")
map("i", "<M-S-Down>", "<esc><cmd>m .+1<cr>==gi", "Move line down")
map("i", "<M-S-Up>", "<esc><cmd>m .-2<cr>==gi", "Move line up")
map("v", "<M-S-Down>", ":m '>+1<cr>gv=gv", "Move selection down")
map("v", "<M-S-Up>", ":m '<-2<cr>gv=gv", "Move selection up")

-- ---------- Навигация ----------
map("n", ds("o"), tb("find_files"), "Go to file")
map("n", "<D-o>", tb("lsp_dynamic_workspace_symbols"), "Go to symbol")
map("n", "<D-F12>", tb("lsp_document_symbols"), "File structure")
map("n", "<D-e>", tb("oldfiles", { cwd_only = true }), "Recent files")
map("n", ds("f"), tb("live_grep"), "Find in files")
map("n", ds("a"), tb("commands"), "Find action")
map("n", "<D-[>", "<C-o>", "Navigate back")
map("n", "<D-]>", "<C-i>", "Navigate forward")

-- ---------- LSP (как в WebStorm) ----------
map("n", "<D-b>", vim.lsp.buf.definition, "Go to declaration")
map("n", "<D-M-b>", vim.lsp.buf.implementation, "Go to implementation")
map("n", "<M-F7>", tb("lsp_references"), "Find usages")
map("n", "<S-F6>", vim.lsp.buf.rename, "Rename")
map({ "n", "v" }, "<M-CR>", vim.lsp.buf.code_action, "Show context actions")
local function format_code()
  local ok, conform = pcall(require, "conform")
  if ok then conform.format({ async = true, lsp_format = "fallback" })
  else vim.lsp.buf.format({ async = true }) end
end
_G.ws_format = format_code  -- для меню правой кнопки
map({ "n", "v" }, "<D-M-l>", format_code, "Reformat code (Prettier из проекта или сервер языка)")
map("n", "<leader>ef", "<cmd>LspEslintFixAll<cr>", "ESLint: исправить всё в файле")
map("n", "<D-6>", "<cmd>Trouble diagnostics toggle<cr>", "Problems: все ошибки")
map("n", { "<D-S-r>", "<D-S-R>" }, function()
  require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") } })
end, "Replace in Files: замена по проекту")
map("v", { "<D-S-r>", "<D-S-R>" }, function() require("grug-far").with_visual_selection() end, "Replace in Files")
-- Option+клик по имени — переход к определению (как Cmd+клик в WebStorm)
map("n", "<M-LeftMouse>", "<LeftMouse><cmd>lua vim.lsp.buf.definition()<cr>", "Перейти к определению")
map("n", "<F1>", vim.lsp.buf.hover, "Quick documentation")
map({ "n", "i" }, "<D-p>", vim.lsp.buf.signature_help, "Parameter info")
map("n", "<F2>", diag(1), "Next error")
map("n", "<S-F2>", diag(-1), "Previous error")
map("n", "<D-F1>", vim.diagnostic.open_float, "Error description")

-- ---------- Git (как в WebStorm) ----------
local function gs(fn, ...)
  local args = { ... }
  return function()
    local ok, gitsigns = pcall(require, "gitsigns")
    if ok then gitsigns[fn](unpack(args)) end
  end
end

map("n", "<D-k>", "<cmd>DiffviewOpen<cr>", "Commit: все изменения с диффом")
map("n", "<D-9>", tb("git_status"), "Git: список изменённых файлов")
map("n", "<D-M-z>", gs("reset_hunk"), "Rollback: откатить изменённый блок")
map("n", { "<C-M-S-Down>", "]c" }, gs("nav_hunk", "next"), "Следующее изменение")
map("n", { "<C-M-S-Up>", "[c" }, gs("nav_hunk", "prev"), "Предыдущее изменение")

map("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", "Git: все изменения")
map("n", "<leader>gq", "<cmd>DiffviewClose<cr>", "Git: закрыть дифф")
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", "Git: история файла")
map("n", "<leader>gH", "<cmd>DiffviewFileHistory<cr>", "Git: история проекта")
map("n", "<leader>gs", tb("git_status"), "Git: изменённые файлы")
map("n", "<leader>gp", gs("preview_hunk"), "Git: показать изменение")
map("n", "<leader>gr", gs("reset_hunk"), "Git: откатить изменение")
map("n", "<leader>gb", gs("blame_line", { full = true }), "Git: кто изменил строку")
map("n", "<leader>gB", gs("blame"), "Git: авторы всех строк (Annotate)")
map("n", "<leader>ga", gs("stage_hunk"), "Git: добавить изменение в коммит (stage)")
map("v", "<leader>ga", function()
  require("gitsigns").stage_hunk({ vim.fn.line("v"), vim.fn.line(".") })
end, "Git: добавить выделенные строки в коммит")
map("n", "<leader>gA", gs("stage_buffer"), "Git: добавить весь файл в коммит")
map("n", "<leader>gu", gs("undo_stage_hunk"), "Git: убрать из коммита последнее добавленное")

local function git_root_here()
  local dir = vim.fn.expand("%:p:h")
  if dir == "" or vim.fn.isdirectory(dir) == 0 then dir = vim.fn.getcwd() end
  local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
  return vim.v.shell_error == 0 and out[1] or nil
end

map("n", "<leader>gc", function()
  local root = git_root_here()
  if not root then return vim.notify("Здесь нет git-репозитория", vim.log.levels.WARN) end
  vim.fn.system({ "git", "-C", root, "diff", "--cached", "--quiet" })
  local all = ""
  if vim.v.shell_error == 0 then
    local choice = vim.fn.confirm("В коммит ничего не добавлено. Закоммитить все изменённые файлы?", "&Да\n&Нет", 2)
    if choice ~= 1 then return end
    all = "-a "
  end
  vim.ui.input({ prompt = "Сообщение коммита: " }, function(msg)
    if not msg or msg == "" then return end
    require("webstorm").run_command({
      cmd = "git commit " .. all .. "-m " .. vim.fn.shellescape(msg), cwd = root, title = "git commit",
    })
  end)
end, "Git: коммит")
map("n", "<leader>gP", function()
  local root = git_root_here()
  if not root then return vim.notify("Здесь нет git-репозитория", vim.log.levels.WARN) end
  require("webstorm").run_command({ cmd = "git push", cwd = root, title = "git push" })
end, "Git: push")
map("n", "<leader>gg", function()
  if vim.fn.executable("lazygit") == 1 then
    vim.cmd("tabnew | terminal lazygit")
    vim.cmd("startinsert")
  else
    vim.notify("Установите lazygit: brew install lazygit", vim.log.levels.WARN)
  end
end, "Git: lazygit")

-- ---------- Вкладки (буферы), панели, терминал ----------
map("n", "<D-w>", function()
  local ok, br = pcall(require, "mini.bufremove")
  if ok then br.delete(0, false) else vim.cmd("bdelete") end
end, "Close tab")
map("n", { "<D-S-[>", "<D-{>" }, "<cmd>BufferLineCyclePrev<cr>", "Previous tab")
map("n", { "<D-S-]>", "<D-}>" }, "<cmd>BufferLineCycleNext<cr>", "Next tab")

-- ---------- Сессии: открытые файлы восстанавливаются при следующем запуске в этой папке ----------
map("n", "<leader>sr", function() require("persistence").load() end, "Сессия: восстановить для этой папки")
map("n", "<leader>sl", function() require("persistence").load({ last = true }) end, "Сессия: последняя")
map("n", "<leader>sd", function() require("persistence").stop() end, "Сессия: не сохранять при выходе")
-- Перед сохранением сессии закрываем служебные окна (проводник, терминалы, диффы)
vim.api.nvim_create_autocmd("User", {
  pattern = "PersistenceSavePre",
  callback = function()
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      if vim.bo[vim.api.nvim_win_get_buf(w)].buftype ~= "" or vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neo-tree" then
        pcall(vim.api.nvim_win_close, w, true)
      end
    end
  end,
})
-- Запуск как `nvim` или `nvim .` — восстанавливаем файлы, которые были открыты в этой папке
vim.api.nvim_create_autocmd("VimEnter", {
  nested = true,
  callback = function()
    local argc = vim.fn.argc()
    if argc > 1 then return end
    if argc == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 0 then return end
    local ok, p = pcall(require, "persistence")
    if ok and vim.fn.filereadable(p.current()) == 1 then
      p.load()
    end
  end,
})

map("n", "<D-1>", function()
  if vim.fn.exists(":Neotree") == 2 then vim.cmd("Neotree toggle reveal")
  elseif vim.fn.exists(":NvimTreeFindFileToggle") == 2 then vim.cmd("NvimTreeFindFileToggle")
  else vim.cmd("Lexplore") end
end, "Project tool window")

-- ---------- Терминалы: до трёх, внизу, каждый своего цвета ----------
local M = {}
local MAX_TERMS = 3
local Term = { bufs = {}, last = 1, height = 15 }

local term_colors = {
  { bg = "#1B2433", bar = "#22324A", accent = "#56A8F5" },  -- 1: синий
  { bg = "#1C2A21", bar = "#25392B", accent = "#6AAB73" },  -- 2: зелёный
  { bg = "#2A1F2E", bar = "#3A2A40", accent = "#C77DBB" },  -- 3: фиолетовый
  { bg = "#2B2219", bar = "#3D3022", accent = "#CF8E6D" },  -- окно «Запуск»: оранжевый
}
local RUN = 4  -- номер окна запуска (не считается среди трёх терминалов)

local function set_term_highlights()
  for i, c in ipairs(term_colors) do
    vim.api.nvim_set_hl(0, "WsTerm" .. i, { bg = c.bg, fg = "#BCBEC4" })
    vim.api.nvim_set_hl(0, "WsTermTag" .. i, { bg = c.accent, fg = "#1E1F22", bold = true })
    vim.api.nvim_set_hl(0, "WsTermBar" .. i, { bg = c.bar, fg = "#DFE1E5" })
    vim.api.nvim_set_hl(0, "WsTermBarNC" .. i, { bg = c.bg, fg = "#6F737A" })
    vim.api.nvim_set_hl(0, "WsTermSep" .. i, { fg = c.accent, bg = c.bg })
  end
end
set_term_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_term_highlights })

local function term_alive(i)
  local b = Term.bufs[i]
  return b ~= nil and vim.api.nvim_buf_is_valid(b)
    and vim.fn.jobwait({ vim.bo[b].channel }, 0)[1] == -1
end

-- Окна нижней панели с нашими терминалами (в порядке слева направо)
local function panel_wins()
  local res = {}
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.b[vim.api.nvim_win_get_buf(w)].ws_term then table.insert(res, w) end
  end
  return res
end

local function term_win(i)
  for _, w in ipairs(panel_wins()) do
    if vim.b[vim.api.nvim_win_get_buf(w)].ws_term == i then return w end
  end
end

local function equalize_panel()
  local ws = panel_wins()
  if #ws < 2 then return end
  local total = 0
  for _, w in ipairs(ws) do total = total + vim.api.nvim_win_get_width(w) end
  local each = math.floor(total / #ws)
  for k, w in ipairs(ws) do
    if k < #ws then pcall(vim.api.nvim_win_set_width, w, each) end
  end
end

local function style_term_win(w, i, label, hint)
  local wo = vim.wo[w]
  wo.winhighlight = table.concat({
    "Normal:WsTerm" .. i, "NormalNC:WsTerm" .. i, "EndOfBuffer:WsTerm" .. i,
    "WinBar:WsTermBar" .. i, "WinBarNC:WsTermBarNC" .. i, "WinSeparator:WsTermSep" .. i,
  }, ",")
  if label then
    wo.winbar = ("%%#WsTermTag%d# %s %%* %%<%%{get(b:,'ws_status','')}%%=%s "):format(i, label, hint or "")
  else
    wo.winbar = ("%%#WsTermTag%d# ● Терминал %d %%* %%<%%{get(b:,'term_title','')}%%=Opt+Shift+%d "):format(i, i, i)
  end
  wo.winfixheight = true
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = "no"
  wo.cursorline = false
end

local function free_slot()
  for i = 1, MAX_TERMS do
    if not term_alive(i) then return i end
  end
end

-- Показать терминал i (создать, если его ещё нет) и перейти в него
local function open_term(i, cwd)
  local w = term_win(i)
  if not w then
    local ws = panel_wins()
    if #ws > 0 then
      vim.api.nvim_set_current_win(ws[#ws])
      vim.cmd("rightbelow vsplit")
    else
      vim.cmd("botright " .. Term.height .. "split")
    end
    w = vim.api.nvim_get_current_win()
    if term_alive(i) then
      vim.api.nvim_win_set_buf(w, Term.bufs[i])
    else
      vim.cmd("enew")
      local b = vim.api.nvim_get_current_buf()
      local dir = cwd or vim.fn.getcwd()
      vim.fn.jobstart({ vim.o.shell }, { term = true, cwd = dir })
      vim.b[b].ws_cwd = dir
      vim.bo[b].buflisted = false
      vim.b[b].ws_term = i
      Term.bufs[i] = b
    end
    style_term_win(w, i)
    equalize_panel()
  end
  vim.api.nvim_set_current_win(w)
  Term.last = i
  vim.cmd("startinsert")
end

-- Новый терминал в первом свободном слоте (в папке cwd, если задана)
local function new_term(cwd)
  local i = free_slot()
  if not i then
    vim.notify("Уже открыто " .. MAX_TERMS .. " терминала. Закройте один: Option+X", vim.log.levels.WARN)
    return
  end
  open_term(i, cwd)
end
M.new_terminal = new_term

-- Спрятать/показать всю панель терминалов (процессы при этом продолжают работать)
local function toggle_panel()
  local ws = panel_wins()
  if #ws > 0 then
    Term.height = vim.api.nvim_win_get_height(ws[1])
    for _, w in ipairs(ws) do pcall(vim.api.nvim_win_hide, w) end
    return
  end
  local any = false
  for i = 1, MAX_TERMS do
    if term_alive(i) then open_term(i); any = true end
  end
  if not any then
    open_term(1)
  elseif term_alive(Term.last) then
    open_term(Term.last)
  end
end

-- Закрыть текущий терминал совсем (процесс завершается)
local function close_term()
  local b = vim.api.nvim_get_current_buf()
  local i = vim.b[b].ws_term
  if not i then return end
  Term.bufs[i] = nil
  pcall(vim.api.nvim_buf_delete, b, { force = true })
  equalize_panel()
end

-- Вернуться из терминала в код
local function focus_code()
  local function is_code(w)
    local b = vim.api.nvim_win_get_buf(w)
    return vim.bo[b].buftype == "" and vim.bo[b].filetype ~= "neo-tree"
  end
  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  if prev ~= 0 and is_code(prev) then return vim.api.nvim_set_current_win(prev) end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_code(w) then return vim.api.nvim_set_current_win(w) end
  end
end

local function resize(dh, dw)
  return function()
    if dh ~= 0 then vim.cmd(("resize %+d"):format(dh)) end
    if dw ~= 0 then vim.cmd(("vertical resize %+d"):format(dw)) end
  end
end

map({ "n", "t" }, "<M-F12>", toggle_panel, "Терминалы: показать/спрятать")
map("n", "<leader>t", toggle_panel, "Терминалы: показать/спрятать (Space, t)")
for i = 1, MAX_TERMS do
  map({ "n", "i", "t" }, "<M-S-" .. i .. ">", function() open_term(i) end, "Терминал " .. i .. " (Option+Shift+" .. i .. ")")
end
map({ "n", "i", "t" }, "<M-t>", function() new_term() end, "Новый терминал")
map({ "n", "t" }, "<M-x>", close_term, "Закрыть текущий терминал")
map({ "n", "i", "t" }, "<M-S-0>", focus_code, "Перейти в код (Option+Shift+0)")
map("t", "<Esc><Esc>", [[<C-\><C-n>]], "Выйти из режима ввода терминала")
-- Размер терминала: Alt+Shift+стрелки (только внутри терминала)
map("t", "<M-S-Up>", resize(3, 0), "Терминал выше")
map("t", "<M-S-Down>", resize(-3, 0), "Терминал ниже")
map("t", "<M-S-Left>", resize(0, -5), "Терминал уже")
map("t", "<M-S-Right>", resize(0, 5), "Терминал шире")

-- ---------- Переход к файлам из вывода терминала ----------
-- Понимает: git status, git diff (a/ b/), git grep -n, ошибки вида file:12:5 и file.ts(12,5), ссылки http(s)

local function token_bounds(text, col)
  if not text or col < 1 or col > #text or text:sub(col, col):match("%s") then return nil end
  local s, e = col, col
  while s > 1 and not text:sub(s - 1, s - 1):match("%s") do s = s - 1 end
  while e < #text and not text:sub(e + 1, e + 1):match("%s") do e = e + 1 end
  return s, e
end

-- Слово под курсором; если терминал перенёс длинный путь или ссылку на следующую строку — склеиваем
local function tokens_at(buf, lnum, col, width)
  local function line(n)
    if n < 1 then return nil end
    return vim.api.nvim_buf_get_lines(buf, n - 1, n, false)[1]
  end
  local function full(t) return vim.fn.strdisplaywidth(t) >= width end
  local text = line(lnum)
  local s, e = token_bounds(text, col)
  if not s then return {} end
  local plain = text:sub(s, e)
  local joined = plain
  -- хвост на следующих строках
  local n, cur, ce = lnum, text, e
  while ce == #cur and full(cur) do
    local nxt = line(n + 1)
    local piece = nxt and nxt:match("^%S+")
    if not piece then break end
    joined = joined .. piece
    n, cur, ce = n + 1, nxt, #piece
  end
  -- начало на предыдущих строках
  n = lnum
  local cs = s
  while cs == 1 do
    local prev = line(n - 1)
    if not prev or not full(prev) then break end
    local piece = prev:match("%S+$")
    if not piece then break end
    joined = piece .. joined
    n, cs = n - 1, #prev - #piece + 1
  end
  if joined ~= plain then return { joined, plain } end
  return { plain }
end

local function parse_location(tok)
  tok = tok:gsub("^[\"'`%(%[<{]+", ""):gsub("[\"'`%]>},;:%.]+$", "")
  local url = tok:match("https?://[%w%-%._~:/%?#%[%]@!%$&'%(%)%*%+,;=%%]+")
  if url then return { url = (url:gsub("[%.,;:%)]+$", "")) } end
  local path, l, c = tok:match("^(.-):(%d+):(%d+)")
  if not path then path, l = tok:match("^(.-):(%d+)") end
  if not path then path, l, c = tok:match("^(.-)%((%d+),(%d+)%)?$") end
  if not path or path == "" then path = tok:gsub("%)$", "") end
  return { path = path, line = tonumber(l), col = tonumber(c) }
end

local git_root_cache = {}
local function git_root(dir)
  if git_root_cache[dir] == nil then
    local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
    git_root_cache[dir] = (vim.v.shell_error == 0 and out[1]) or false
  end
  return git_root_cache[dir] or nil
end

-- Папки, относительно которых ищем путь: папка терминала, папка из заголовка терминала, папка nvim, корни git
local function search_dirs(buf)
  local dirs, seen = {}, {}
  local function add(d)
    if d and d ~= "" and not seen[d] and vim.fn.isdirectory(d) == 1 then
      seen[d] = true
      table.insert(dirs, d)
    end
  end
  local title = vim.b[buf].term_title or ""
  local tdir = title:match("([~/][^%s:]*)$")
  if tdir then add(vim.fs.normalize(tdir)) end
  add(vim.b[buf].ws_cwd)
  add(vim.fn.getcwd())
  for _, d in ipairs(vim.deepcopy(dirs)) do add(git_root(d)) end
  return dirs
end

local function resolve_path(path, buf)
  if path:sub(1, 1) == "~" then path = vim.fs.normalize(path) end
  local candidates = { path }
  local no_prefix = path:match("^[abiwco]/(.+)$")  -- префиксы git diff: a/ b/ i/ w/
  if no_prefix then table.insert(candidates, no_prefix) end
  for _, p in ipairs(candidates) do
    if p:sub(1, 1) == "/" then
      if vim.fn.filereadable(p) == 1 then return p end
    else
      for _, d in ipairs(search_dirs(buf)) do
        local f = d .. "/" .. p
        if vim.fn.filereadable(f) == 1 then return vim.fs.normalize(f) end
      end
    end
  end
end

local function open_in_code_window(file, line, col)
  local target
  local prev = vim.fn.win_getid(vim.fn.winnr("#"))
  local function is_code(w)
    local b = vim.api.nvim_win_get_buf(w)
    return vim.bo[b].buftype == "" and vim.bo[b].filetype ~= "neo-tree"
  end
  if prev ~= 0 and vim.api.nvim_win_is_valid(prev) and is_code(prev) then target = prev end
  if not target then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if is_code(w) then target = w break end
    end
  end
  if target then
    vim.api.nvim_set_current_win(target)
  else
    vim.cmd("topleft split")
  end
  vim.cmd("stopinsert")
  vim.cmd.edit(vim.fn.fnameescape(file))
  if line then
    local last = vim.api.nvim_buf_line_count(0)
    pcall(vim.api.nvim_win_set_cursor, 0, { math.min(line, last), math.max((col or 1) - 1, 0) })
    vim.cmd("normal! zz")
  end
end

-- Открыть путь или ссылку в позиции (buf, строка, колонка). true — если получилось
local function jump_at(buf, win, lnum, col)
  local tried
  for _, tok in ipairs(tokens_at(buf, lnum, col, vim.api.nvim_win_get_width(win))) do
    local loc = parse_location(tok)
    if loc.url then
      vim.ui.open(loc.url)
      return true
    end
    local file = resolve_path(loc.path, buf)
    if file then
      open_in_code_window(file, loc.line, loc.col)
      return true
    end
    tried = tried or loc.path
  end
  return false, tried
end

local function jump_under_cursor()
  local cur = vim.api.nvim_win_get_cursor(0)
  return jump_at(vim.api.nvim_get_current_buf(), vim.api.nvim_get_current_win(), cur[1], cur[2] + 1)
end

local function jump_under_mouse()
  local pos = vim.fn.getmousepos()
  if pos.winid == 0 or pos.line == 0 then return false end
  local buf = vim.api.nvim_win_get_buf(pos.winid)
  return jump_at(buf, pos.winid, pos.line, vim.fn.virtcol2col(pos.winid, pos.line, pos.column))
end
M.jump_under_cursor = jump_under_cursor

local function feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "n", false)
end

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function(args)
    -- Открыть файл из вывода: gf или Enter (после Esc Esc), двойной клик или Option+клик
    local bo = { buffer = args.buf, silent = true }
    vim.keymap.set("n", "gf", function()
      local ok, tried = jump_under_cursor()
      if not ok then vim.notify("Не нашёл файл: " .. (tried or "под курсором нет пути"), vim.log.levels.WARN) end
    end, bo)
    vim.keymap.set("n", "<CR>", function()
      if not jump_under_cursor() then feed("<CR>") end
    end, bo)
    vim.keymap.set({ "n", "t" }, "<2-LeftMouse>", function()
      if not jump_under_mouse() then feed("<2-LeftMouse>") end
    end, bo)
    vim.keymap.set({ "n", "t" }, "<M-LeftMouse>", function()
      if not jump_under_mouse() then feed("<LeftMouse>") end
    end, bo)
    if vim.b[args.buf].ws_run then
      vim.keymap.set("n", "r", function() require("webstorm").rerun() end, bo)
      vim.keymap.set("n", "q", "<cmd>close<cr>", bo)
    end

    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.cursorline = false
    -- те же стрелки в обычном режиме внутри терминала
    local o = { buffer = args.buf, silent = true }
    vim.keymap.set("n", "<M-S-Up>", resize(3, 0), o)
    vim.keymap.set("n", "<M-S-Down>", resize(-3, 0), o)
    vim.keymap.set("n", "<M-S-Left>", resize(0, -5), o)
    vim.keymap.set("n", "<M-S-Right>", resize(0, 5), o)
  end,
})
-- В терминал сразу можно печатать
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  pattern = "term://*",
  command = "startinsert",
})
-- Набрали exit — окно терминала закрывается само
vim.api.nvim_create_autocmd("TermClose", {
  callback = function(args)
    local buf = args.buf
    if not vim.api.nvim_buf_is_valid(buf) then return end
    local i = vim.b[buf].ws_term
    if not i then return end
    if vim.b[buf].ws_run then
      local code = vim.v.event.status
      vim.b[buf].ws_status = code == 0 and "завершено успешно" or ("завершено с ошибкой, код " .. code)
      vim.cmd("redrawstatus!")
      return
    end
    Term.bufs[i] = nil
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then pcall(vim.api.nvim_buf_delete, buf, { force = true }) end
      equalize_panel()
    end)
  end,
})

-- ---------- Запуск текущего файла (как Run в WebStorm) ----------
local Run = { last = nil }

local function find_python(file)
  for _, venv in ipairs({ ".venv", "venv" }) do
    local root = vim.fs.root(file, venv)
    if root and vim.fn.executable(root .. "/" .. venv .. "/bin/python") == 1 then
      return root .. "/" .. venv .. "/bin/python"
    end
  end
  return vim.fn.executable("python3") == 1 and "python3" or "python"
end

-- Команда запуска для текущего файла: { cmd, cwd, title } или nil + причина
local function run_spec_for_buffer()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or vim.bo.buftype ~= "" then return nil, "Откройте файл с кодом" end
  local ft = vim.bo.filetype
  local dir = vim.fn.fnamemodify(file, ":h")
  local name = vim.fn.fnamemodify(file, ":t")
  local q = vim.fn.shellescape
  local bindir = vim.fn.stdpath("cache") .. "/run"
  vim.fn.mkdir(bindir, "p")
  local exe = q(bindir .. "/" .. vim.fn.fnamemodify(file, ":t:r"))
  local cxx = vim.fn.executable("clang++") == 1 and "clang++" or "g++"
  local cc = vim.fn.executable("clang") == 1 and "clang" or "gcc"
  local cwd, cmd = dir, nil
  local function rel(root) return vim.fs.relpath(root, file) or file end
  local head = table.concat(vim.api.nvim_buf_get_lines(0, 0, 40, false), "\n")

  -- Тесты: vitest / playwright / jest / pytest
  if name:match("%.test%.[cm]?[jt]sx?$") or name:match("%.spec%.[cm]?[jt]sx?$") then
    local root = vim.fs.root(file, "package.json") or dir
    local runner
    if head:find("@playwright/test", 1, true) then
      runner = "npx playwright test "
    elseif head:find("vitest", 1, true) or vim.fs.root(file, { "vitest.config.ts", "vitest.config.js", "vitest.config.mts" }) then
      runner = "npx vitest run "
    else
      runner = "npx jest "
    end
    return { cmd = runner .. q(rel(root)), cwd = root, title = "тесты: " .. name }
  end
  if ft == "python" and (name:match("^test_.*%.py$") or name:match("_test%.py$")) then
    local root = vim.fs.root(file, { "pyproject.toml", "pytest.ini", "setup.cfg", "tox.ini", ".git" }) or dir
    return { cmd = q(find_python(file)) .. " -m pytest -q " .. q(rel(root)), cwd = root, title = "тесты: " .. name }
  end

  if ft == "python" then
    cmd = q(find_python(file)) .. " -u " .. q(name)
  elseif ft == "cpp" then
    cmd = ("%s -std=c++20 -g -Wall -Wextra %s -o %s && %s"):format(cxx, q(name), exe, exe)
  elseif ft == "c" then
    cmd = ("%s -std=c17 -g -Wall -Wextra %s -o %s && %s"):format(cc, q(name), exe, exe)
  elseif ft == "javascript" then
    cmd = "node " .. q(name)
  elseif ft == "typescript" then
    cmd = "npx --yes tsx " .. q(name)
  elseif ft == "java" then
    cmd = "java " .. q(name)
  elseif ft == "php" then
    cmd = "php " .. q(name)
  elseif ft == "cs" then
    cwd = vim.fs.root(file, function(n) return n:match("%.csproj$") ~= nil end) or dir
    cmd = "dotnet run"
  elseif ft == "go" then
    cmd = "go run " .. q(name)
  elseif ft == "rust" then
    local root = vim.fs.root(file, "Cargo.toml")
    if root then cwd, cmd = root, "cargo run" else
      cmd = ("rustc -g %s -o %s && %s"):format(q(name), exe, exe)
    end
  elseif ft == "sh" or ft == "bash" or ft == "zsh" then
    cmd = (ft == "zsh" and "zsh " or "bash ") .. q(name)
  else
    return nil, "Не знаю, как запускать файлы типа «" .. ft .. "»"
  end
  return { cmd = cmd, cwd = cwd, title = name }
end

local function start_run(spec)
  vim.cmd("silent! wall")
  local old = Term.bufs[RUN]
  local w = term_win(RUN)
  if not w then
    local ws = panel_wins()
    if #ws > 0 then
      vim.api.nvim_set_current_win(ws[#ws])
      vim.cmd("rightbelow vsplit")
    else
      vim.cmd("botright " .. Term.height .. "split")
    end
    w = vim.api.nvim_get_current_win()
  end
  vim.api.nvim_set_current_win(w)
  vim.cmd("enew")
  local b = vim.api.nvim_get_current_buf()
  vim.bo[b].buflisted = false
  vim.b[b].ws_term = RUN
  vim.b[b].ws_run = true
  vim.b[b].ws_cwd = spec.cwd
  vim.b[b].ws_status = "выполняется: " .. spec.cmd
  Term.bufs[RUN] = b
  if old and old ~= b and vim.api.nvim_buf_is_valid(old) then
    pcall(vim.fn.jobstop, vim.bo[old].channel)
    pcall(vim.api.nvim_buf_delete, old, { force = true })
  end
  vim.fn.jobstart({ vim.o.shell, "-c", spec.cmd }, { term = true, cwd = spec.cwd })
  style_term_win(w, RUN, "▶ " .. spec.title, "Ctrl+Shift+R — ещё раз ")
  equalize_panel()
  Run.last = spec
  vim.cmd("startinsert")
end

-- Запустить текущий файл; если сейчас не файл с кодом — повторить последний запуск
local function run_file()
  local spec, why = run_spec_for_buffer()
  if spec then return start_run(spec) end
  if Run.last then return start_run(Run.last) end
  vim.notify(why, vim.log.levels.WARN)
end

local function rerun()
  if Run.last then start_run(Run.last) else run_file() end
end

local function stop_run()
  local b = Term.bufs[RUN]
  if b and vim.api.nvim_buf_is_valid(b) then pcall(vim.fn.jobstop, vim.bo[b].channel) end
end

map({ "n", "i", "t" }, { "<C-S-r>", "<C-S-R>" }, run_file, "Запустить текущий файл")
map("n", "<leader>r", run_file, "Запустить текущий файл (Space, r)")
map("n", "<leader>R", rerun, "Повторить последний запуск (Space, R)")
map({ "n", "i", "t" }, "<D-F2>", stop_run, "Остановить запуск")
M.run_file, M.rerun, M.stop_run, M.run_command = run_file, rerun, stop_run, start_run

-- ---------- Меню правой кнопки мыши (как контекстное меню WebStorm) ----------
vim.o.mousemodel = "popup_setpos"  -- правый клик сначала ставит курсор туда, куда кликнули
pcall(vim.api.nvim_del_augroup_by_name, "nvim.popupmenu")  -- убираем стандартное меню Neovim
pcall(vim.api.nvim_del_augroup_by_name, "nvim_popupmenu")

local function menu_escape(str)
  return (str:gsub("([ .\\])", "\\%1"))
end

local function add_menu(modes, label, hint, rhs)
  local name = menu_escape(label)
  if hint then name = name .. "<Tab>" .. menu_escape(hint) end
  for _, m in ipairs(modes) do
    vim.cmd(("%smenu PopUp.%s %s"):format(m, name, rhs))
  end
end

local sep_count = 0
local function add_sep(modes)
  sep_count = sep_count + 1
  for _, m in ipairs(modes) do
    vim.cmd(("%smenu PopUp.-sep%d- <Nop>"):format(m, sep_count))
  end
end

local function build_popup_menu()
  vim.cmd("silent! aunmenu PopUp")
  vim.cmd("silent! tlunmenu PopUp")
  sep_count = 0
  local ft, bt = vim.bo.filetype, vim.bo.buftype

  if ft == "neo-tree" then
    -- Пункты отправляют клавиши neo-tree, поэтому работают с файлом под курсором
    add_menu({ "n" }, "Открыть", "Enter", "<CR>")
    add_sep({ "n" })
    add_menu({ "n" }, "Новый файл", "a", "a")
    add_menu({ "n" }, "Новая папка", "A", "A")
    add_sep({ "n" })
    add_menu({ "n" }, "Переименовать", "r", "r")
    add_menu({ "n" }, "Копировать", "c", "c")
    add_menu({ "n" }, "Переместить", "m", "m")
    add_menu({ "n" }, "Удалить", "d", "d")
    add_sep({ "n" })
    add_menu({ "n" }, "Копировать путь", "Y", "Y")
    add_menu({ "n" }, "Показать в Finder", "gO", "gO")
    add_menu({ "n" }, "Открыть в терминале", "T", "T")
    return
  end

  if bt == "terminal" then
    add_menu({ "n", "tl" }, "Вставить", nil, "<Cmd>lua vim.api.nvim_paste(vim.fn.getreg('+'), true, -1)<CR>")
    add_sep({ "n", "tl" })
    add_menu({ "n", "tl" }, "Новый терминал", "Opt+T", "<Cmd>lua require('webstorm').new_terminal()<CR>")
    add_menu({ "n", "tl" }, "Закрыть этот терминал", "Opt+X", "<Cmd>lua require('webstorm').close_terminal()<CR>")
    add_menu({ "n", "tl" }, "Спрятать терминалы", "Space t", "<Cmd>lua require('webstorm').toggle_terminals()<CR>")
    add_menu({ "n", "tl" }, "Перейти в код", "Opt+Shift+0", "<Cmd>lua require('webstorm').focus_code()<CR>")
    add_menu({ "n", "tl" }, "Запустить снова", "Ctrl+Shift+R", "<Cmd>lua require('webstorm').rerun()<CR>")
    return
  end

  -- Обычный файл с кодом
  if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
    add_menu({ "n" }, "Перейти к объявлению", "Cmd+B", "<Cmd>lua vim.lsp.buf.definition()<CR>")
    add_menu({ "n" }, "Найти использования", "Alt+F7", "<Cmd>lua require('telescope.builtin').lsp_references()<CR>")
    add_menu({ "n" }, "Переименовать", "Shift+F6", "<Cmd>lua vim.lsp.buf.rename()<CR>")
    add_menu({ "n", "v" }, "Действия и исправления", "Alt+Enter", "<Cmd>lua vim.lsp.buf.code_action()<CR>")
    add_menu({ "n" }, "Документация", "F1", "<Cmd>lua vim.lsp.buf.hover()<CR>")
    add_sep({ "n", "v" })
  end
  add_menu({ "v" }, "Вырезать", "x", '"+x')
  add_menu({ "v" }, "Копировать", "y", '"+y')
  add_menu({ "n" }, "Вставить", "p", '"+gP')
  add_menu({ "v" }, "Вставить", "p", '"+P')
  add_menu({ "n" }, "Выделить всё", "Cmd+A", "ggVG")
  add_sep({ "n", "v" })
  add_menu({ "n" }, "Закомментировать", "Cmd+/", "gcc")
  add_menu({ "v" }, "Закомментировать", "Cmd+/", "gc")
  add_menu({ "n", "v" }, "Форматировать", "Cmd+Alt+L", "<Cmd>lua ws_format()<CR>")
  add_sep({ "n" })
  add_menu({ "n" }, "Запустить файл", "Ctrl+Shift+R", "<Cmd>lua require('webstorm').run_file()<CR>")
  add_sep({ "n" })
  add_menu({ "n" }, "Git: кто изменил строку", "Space g b", "<Cmd>lua require('gitsigns').blame_line({ full = true })<CR>")
  add_menu({ "n" }, "Git: откатить изменение", "Cmd+Alt+Z", "<Cmd>lua require('gitsigns').reset_hunk()<CR>")
end

build_popup_menu()
vim.api.nvim_create_autocmd("MenuPopup", { callback = build_popup_menu })

-- ---------- Автосохранение (как в WebStorm) ----------
vim.g.autosave = true
vim.o.autoread = true
local autosave_timer = vim.uv.new_timer()

local function autosave(buf)
  if not vim.g.autosave or not vim.api.nvim_buf_is_valid(buf) then return end
  local bo = vim.bo[buf]
  if bo.buftype ~= "" or not bo.modifiable or bo.readonly or not bo.modified then return end
  if vim.api.nvim_buf_get_name(buf) == "" then return end
  vim.api.nvim_buf_call(buf, function() vim.cmd("silent! lockmarks update") end)
end

-- Через 1 секунду после выхода из режима ввода или правки в обычном режиме
vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
  callback = function(args)
    autosave_timer:stop()
    autosave_timer:start(1000, 0, vim.schedule_wrap(function()
      if vim.fn.mode() ~= "i" then autosave(args.buf) end
    end))
  end,
})
-- Сразу при уходе в другой файл, другое окно приложения или при выходе
vim.api.nvim_create_autocmd({ "BufLeave", "FocusLost", "VimLeavePre" }, {
  callback = function(args) autosave(args.buf) end,
})
-- Подхватить изменения файла снаружи (git checkout и т.п.)
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  callback = function()
    if vim.fn.getcmdwintype() == "" then vim.cmd("silent! checktime") end
  end,
})

vim.api.nvim_create_user_command("AutosaveToggle", function()
  vim.g.autosave = not vim.g.autosave
  vim.notify("Автосохранение " .. (vim.g.autosave and "включено" or "выключено"))
end, {})

M.toggle_terminals = toggle_panel
M.close_terminal = close_term
M.focus_code = focus_code
M.open_terminal = open_term
return M

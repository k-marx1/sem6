-- callouts.lua
-- Превращает Obsidian callouts вида:
-- > [!note] Title
-- > text
-- в Div class="callout note" с атрибутом title="Title"

local function stringify_inlines(inlines)
  return pandoc.utils.stringify(pandoc.Inlines(inlines))
end

local function parse_callout_marker(inlines)
  -- ожидаем, что первая строка начинается с [!type]
  local s = stringify_inlines(inlines)
  -- варианты: "[!note]" или "[!note] Заголовок"
  local ctype, title = s:match("^%[!(%w+)%]%s*(.*)$")
  if ctype then
    if title == "" then title = ctype end
    return ctype:lower(), title
  end
  return nil
end

function BlockQuote(el)
  if #el.content == 0 then return nil end

  -- ищем первую Para в цитате
  local first = el.content[1]
  if first.t ~= "Para" then return nil end

  local ctype, title = parse_callout_marker(first.content)
  if not ctype then return nil end

  -- убрать первую строку-маркер из содержимого
  table.remove(el.content, 1)

  -- обернуть оставшееся в Div
  local div = pandoc.Div(el.content)
  div.classes:insert("callout")
  div.classes:insert(ctype)
  div.attributes["title"] = title
  return div
end

function Div(el)
  if not el.classes:includes("callout") then
    return nil
  end

  local title = el.attributes["title"] or "Callout"
  local ctype = "note"
  for _, c in ipairs(el.classes) do
    if c ~= "callout" then ctype = c end
  end

  local env = "calloutnote"
  if ctype == "info" then env = "calloutinfo" end
  if ctype == "warning" then env = "calloutwarning" end
  if ctype == "tip" then env = "callouttip" end

  local blocks = {}
  table.insert(blocks, pandoc.RawBlock("latex", "\\begin{"..env.."}{"..title.."}"))
  for _, b in ipairs(el.content) do table.insert(blocks, b) end
  table.insert(blocks, pandoc.RawBlock("latex", "\\end{"..env.."}"))
  return blocks
end


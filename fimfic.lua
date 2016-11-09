-- fimfic.lua
-- Author: Jason Seeley (HeirOfNorton)
-- Copious modifications by Oliver@FimFiction.
--
-- Description:
-- This script is meant to be used as a custom writer for Pandoc.
-- The output is BBCODE format that is compatible with www.fimfiction.net
--
-- Usage example: pandoc [pandoc options] -t fimfic.lua input_file -o output_file
--
-- See README for more information and options for customization.

-- Table to store footnotes, so they can be included at the end.
local notes = {}

-- This script has options that can be customized with the
-- input file's metadata, but the metadata is only available
-- to the script in the "Doc" function, after most of the
-- markup has already been converted. Most of the file is
-- given temporary markup using the unlikely character
-- sequence "{{! ... !}}" so that it can be easily replaced
-- with the correct markup in the "Doc" function once the
-- options are available.

-- There is no option for proper superscript in FimFiction.
-- However, it is possible to imitate at least certain characters.

local function isempty(s)
    return s == nil or s == ''
end

local function csplit(str,sep)
    local ret={}
    local n=1
    for w in str:gmatch("([^"..sep.."]*)") do
        ret[n]=ret[n] or w -- only set once (so the blank after a string is ignored)
        if w=="" then n=n+1 end -- step forwards on a blank but not a string
    end
    return ret
end

function string:split_on_space()
    local result = {}
    for token in self:gmatch('[^ ]+') do
        table.insert(result, token)
    end
    return result
end

function string:tr_spaced(from, to)
    from, to = from:split_on_space(), to:split_on_space()
    assert(#from == #to, "#from = "..tostring(#from)..", #to = "..tostring(#to))
    local conversion_table = {}
    for i = 1, #from do
        conversion_table[from[i]] = to[i]
    end
    local result = self:gsub("%w",conversion_table)
    return result -- to suppress gsub's second return value
end

function faux_superscript(input_string)
    return tostring(input_string):tr_spaced(
        "0 1 2 3 4 5 6 7 8 9 A B D E G H I J K L M N O P R T U V W a b c d e f g h i j k l m n o p r s t u v w x y z",
        "⁰ ¹ ² ³ ⁴ ⁵ ⁶ ⁷ ⁸ ⁹ ᴬ ᴮ ᴰ ᴱ ᴳ ᴴ ᴵ ᴶ ᴷ ᴸ ᴹ ᴺ ᴼ ᴾ ᴿ ᵀ ᵁ ⱽ ᵂ ᵃ ᵇ ᶜ ᵈ ᵉ ᶠ ᵍ ʰ ⁱ ʲ ᵏ ˡ ᵐ ⁿ ᵒ ᵖ ʳ ˢ ᵗ ᵘ ᵛ ʷ ˣ ʸ ᶻ"
    )
end

function faux_subscript(input_string)
    return tostring(input_string):tr_spaced(
        "0 1 2 3 4 5 6 7 8 9 a e h i j k l m n o p r s t u v x",
        "₀ ₁ ₂ ₃ ₄ ₅ ₆ ₇ ₈ ₉ ₐ ₑ ₕ ᵢ ⱼ ₖ ₗ ₘ ₙ ₒ ₚ ᵣ ₛ ₜ ᵤ ᵥ ₓ"
    )
end

-- Blocksep is used to separate block elements.
function Blocksep()
    return "\n\n"
end

-- The functions that follow render corresponding pandoc elements.
-- s is always a string, attr is always a table of attributes, and
-- items is always an array of strings (the items in a list).

function Str(s)
    return s
end

function Space()
    return " "
end

function SoftBreak()
    return "\n"
end

function LineBreak()
    return "\n"
end

function Emph(s)
    return "[i]" .. s .. "[/i]"
end

function Strong(s)
    return "[b]" .. s .. "[/b]"
end

-- Subscripts and Superscripts not supported by FimFiction,
-- but we can simulate some of it.
function Subscript(s)
    return faux_subscript(s)
end

function Superscript(s)
    return faux_superscript(s)
end

function SmallCaps(s)
    return '[smcaps]' .. s .. '[/smcaps]'
end

function Strikeout(s)
    return '[s]' .. s .. '[/s]'
end

-- we need that.
function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function Link(s, src, tit, attr)
    -- Intra-site urls can use site_url tag instead, which has the benefit of being
    -- http/https consistent when rendered.
    local http = "http://www.fimfiction.net"
    local https = "https://www.fimfiction.net"
    if string.starts(src, http) then
        return "[site_url=" .. string.sub(src,string.len(http)+1) .. "]" .. s .. "[/site_url]"
    end
    if string.starts(src, https) then
        return "[site_url=" .. string.sub(src,string.len(https)+1) .. "]" .. s .. "[/site_url]"
    end
    -- Urls which have title 'youtube_inline' will be assumed to refer to youtube
    -- and rendered with [youtube] tag.
    if attr["class"] == "youtube" then
        local youtube_table = {
            "https://www.youtube.com/watch%?v=",
            "http://www.youtube.com/watch%?v=",
            "http://youtu.be/",
            "https://youtu.be/",
        }
        for i,v in ipairs(youtube_table) do
            src = string.gsub(src, v, "")
        end
        if isempty(s) then
            return "[center][youtube=" .. src .. "][/center]"
        end
        return "[center][youtube=" .. src .. "]{{!figcaption!".. s .."!}}[/center]"
    end
    -- Everything else is a regular old url.
    return "[url=" .. src .. "]" .. s .. "[/url]"
end

function captioned_img(src, caption)
    if isempty(caption) then
        return "[center][img]" .. src .. "[/img][/center]"
    end

    return "[center][img]" .. src .. "[/img]\n"..
    "{{!figcaption!" .. caption .. "!}}"
    .."[/center]"

end

function Image(s, src, tit, attr)
    if attr["class"] == "centered" then
        if isempty(tit) then
            return captioned_img(src, s)
        end

        return captioned_img(src, tit)
    end
    return "[img]" .. src .. "[/img]"
end

function CaptionedImage(src, tit, caption, attr)
    if tit == "fig:" then
        tit = ""
    end
    if isempty(caption) then
        return captioned_img(src, tit)
    end
    return captioned_img(src, caption)
end

-- Inline code is not supported by FimFiction in any way.
function Code(s, attr)
    return s
end

-- FimFiction has no support for "math mode"
-- Just pass text through
function InlineMath(s)
    return s
end

function DisplayMath(s)
    return s
end

-- FimFiction does not have proper support for footnotes,
-- so we will fake it by inserting the text and markers
-- ourselves.

function Note(s)
    local num = #notes + 1
    table.insert(notes, s)
    -- Write out the footnote reference with a bold faux-superscript unicode character.
    -- Also leave a marker which we will use to target the paragraph containing the reference.
    local charnum = tonumber(num)
    return '[b]' .. faux_superscript(charnum) .. '[/b]{{!fn'.. num ..'!}}'
end

-- These are Unicode open and close quote characters.
-- Used with pandoc's -s option
function SingleQuoted(s)
    return "‘" .. s .. "’"
end

function DoubleQuoted(s)
    return "“" .. s .. "”"
end

-- FimFiction allows text to have size and color set,
-- which is not possible in MarkDown. As a workaround,
-- this will detect Spans that have relevant style
-- attributes set
function Span(s, attr)
    local text = s
    if attr["style"] then
        -- color
        local _, _, color = attr["style"]:find("color%s*:%s*(.-)%s*;")
        if color then
            text = "[color=" .. color .. "]" .. text .. "[/color]"
        end

        --size
        local _, _, textsize = attr["style"]:find("size%s*:%s*(.-)%s*;")
        if textsize then
            text = "[size=" .. textsize .. "]" .. text .. "[/size]"
        end

        --small caps, in case they get missed by pandoc
        local _, _, caps = attr["style"]:find("variant%s*:%s*small%-caps")
        if caps then
            text = "[smcaps]" .. text .. "[/smcaps]"
        end
    end
    return text
end

-- FimFiction has no support for Citations.
-- Just pass the text through
function Cite(s)
    return s
end

function Plain(s)
    return s
end

function table.empty (self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end

function insert_footnotes(block)
    if #notes > 0 then
        local buff = {}
        for key, note in ipairs(notes) do
            local fn_key = '{{!fn'.. key ..'!}}'
            if block:find(fn_key) then
                table.insert(buff, key)
                block = block:gsub(fn_key,'')
            end
        end
        if table.getn(buff) > 0 then
            block = block .. "{{!footnote_bodies!".. table.concat(buff,"!") .. "!}}"
        end
    end
    return block
end

function style_footnote_block(footnote_table)
    local quoteblock = table.concat(footnote_table, '\n')
    -- Prevent failures on urlencoded urls in footnotes.
    quoteblock = quoteblock:gsub("%%", "%%%%")

    quoteblock = quoteblock:gsub("{{!para!}}","{{!para!}}[size={!fnscale!}]")
    quoteblock = quoteblock:gsub("{{!paraend!}}","[/size]{{!paraend!}}")
    -- Clean up stray tags. Yeah, bad code, not used to lua.
    quoteblock = quoteblock:gsub("%[/size%]{{!para!}}%[size=0%.75em%]","{{!para!}}")

    return "\n[quote]" .. "{{!footnote_marker!}}\n" .. quoteblock .. "\n[/quote]"
end

function style_footnote_start(key, note)
    return "[size={!fnscale!}][b]" .. key .. '.[/b] [/size]' .. note
end

function insert_footnote_bodies(block)

    -- If there is an {{!endnotes!}} marker in the text, put all the footnotes there.
    -- Otherwise, place them by number where {{!footnote_bodies!...}} markers are.

    if block:find('{{!endnotes!}}') then
        if #notes > 0 then
            local buff = {}
            for key, note in ipairs(notes) do
                table.insert(buff, style_footnote_start(key, note))
            end
            return block:gsub("{{!endnotes!}}", style_footnote_block(buff))
        else
            return block:gsub("{{!endnotes!}}", "")
        end
    else
        repeat
            local marker = block:match("{{!footnote_bodies!.-!}}")
            if marker then

                local numbers = csplit(marker:gsub("{{!footnote_bodies!(.-)!}}","%1"),"!")
                local buff = {}
                for index, number in ipairs(numbers) do
                    table.insert(buff, style_footnote_start(number, notes[tonumber(number)]))
                end

                block = block:gsub(marker, style_footnote_block(buff))
            end
        until not marker
    end
    -- Apply span-level sizing to every line of the buffer first.
    return block
end

-- Add a placeholder before paragraphs, to support indenting
-- or not, and a placeholder at the end, to detect and
-- remove extra space between paragraphs when the user
-- chooses single-spacing.
function Para(s)
    local para = "{{!para!}}" .. s .. "{{!paraend!}}"
    -- Also use this moment to see if the paragraph contains any footnotes and
    -- render them as their own quote block and remove the marker.
    return insert_footnotes(para)
end

-- FimFiction has no concept of a Header.
-- Everything is a paragraph. There are options
-- that allow the user to customize how Headers are
-- output in the final document.
-- Attribute on Headers are currently ignored.
function Header(lev, s, attr)
    return "{{!h" .. lev .. "!" .. s .. "!}}"
end

function BlockQuote(s)
    return "[quote]\n" .. s .. "[/quote]"
end

function HorizontalRule()
    return "{{!hr!}}"
end

-- A LineBlock is a block which is pre-wrapped.
-- In Fimfiction, everything is pre-wrapped.
function LineBlock(ls)
  return table.concat(ls, '\n')
end

-- Not sure when those two come up just yet.
function RawInline(format, str)
  return str
end

function RawBlock(format, str)
  return str
end

-- Paradoxically, Fimfiction does have code blocks.
-- But they still parse bbcode tags, which is why we will sanitize them,
-- by adding a '[b][/b]' after every opening bracket, thus preventing
-- them from being parsed.
function CodeBlock(s, attr)
    return "[code]" .. s:gsub('%[','[[b][/b]') .. "[/code]"
end

-- FimFiction does not have proper list tags
-- So we're faking bullets using FontAwesome icons it has.
function BulletList(items)
    local buffer = {}
    for _, item in pairs(items) do
        table.insert(buffer, "{{!list_bullet!}} " .. item )
    end
    return insert_footnotes(table.concat(buffer, "\n"))
end

function OrderedList(items)
    local buffer = {}
    for num, item in pairs(items) do
        table.insert(buffer, "[b]" .. num .. ".[/b] " .. item)
    end
    return insert_footnotes(table.concat(buffer, "\n"))
end

function DefinitionList(items)
    local buffer = {}
    for _,item in pairs(items) do
        for k, v in pairs(item) do
            table.insert(buffer,"[b]" .. k .. ":[/b] " ..
                table.concat(v,", "))
        end
    end
    return insert_footnotes(table.concat(buffer, "\n"))
end

-- FimFiction does not have tables. For now I am
-- just doing tab-separated tables, until I can find
-- or adapt a better table-rendering function

-- Caption is a string, aligns is an array of strings,
-- widths is an array of floats, headers is an array of
-- strings, rows is an array of arrays of strings.
function Table(caption, aligns, widths, headers, rows)
    local buffer = {}
    local function add(s)
        table.insert(buffer, s)
    end
    if caption ~= "" then
        add("[center][b]" .. caption .. "[/b][/center]\n")
    end
    local header_row = {}
    local empty_header = true
    for i, h in pairs(headers) do
        table.insert(header_row, "[b]" .. h .. "[/b]")
        empty_header = empty_header and h == ""
    end
    if not empty_header then
        add(table.concat(header_row, "\t"))
    end
    for _, row in pairs(rows) do
        add(table.concat(row, "\t"))
    end
    return insert_footnotes(table.concat(buffer,'\n'))
end

-- FimFiction has no concept of Divs or the possible
-- attribute they could have. But I am going to use them for certain things, notably verse.
function Div(s, attr)
    text = s
    if attr['class'] == 'verse' then
        -- If we've marked it as a verse, do this:
        -- strip every parastart/paraend tag.
        -- wrap every line in parastart/paraend tags
        -- and add an extra 8 spaces to beginning. (I could use color, but fimfiction
        -- screws up color on non-default color schemes.)
        -- prepend an empty paragraph before and append one after.

        -- I can style it whichever way I like in html/epub builds, so it's not a problem there.
        -- This is a dirty hack even for pandoc, but works for the limited use I need it for.

        local m = text:gsub("{{!para!}}", "")
        m = m:gsub("{{!paraend!}}","")
        local t = csplit(m,"\n")
        -- local o = "{{!para!}}{{!paraend!}}\n"
        local o = "{{!verse_start!}}"
        for i,v in ipairs(t) do
            o = o .. "{{!para!}}{{!verse_indent!}}{{!verse_open!}}" ..
            v .. "{{!verse_close!}}{{!paraend!}}{{!verse_eol!}}"
        end
        -- o = o .. "\n{{!para!}}{{!paraend!}}"
        o = o .. "{{!verse_end!}}"
        text = o
    end
    if attr['class'] == "center" then
        text = "[center]" .. text .. "[center]"
    end
    if attr['class'] == "right" then
        text = "[right]" .. text .. "[right]"
    end

    return insert_footnotes(text)
end

-- Finally, putting it all together.
function Doc(text, metadata, variables)
    local body = text

    -- Append footnotes to the end of the body text, before
    -- replacing options and placeholders.
    -- Commenting this out for the moment.
    --[[
    if #notes > 0 then
        local buff = {}
        for key, note in ipairs(notes) do
            table.insert(buff, "[b]" .. key .. '.[/b] ' .. note)
        end
        body = body .. "[hr]\n" .. table.concat(buff, '\n\n') .. "\n"
    end
    ]]--

    -- Replace temporary markup with correct markup now
    -- that the metadata is available.

    -- Handle verse tags:
    if metadata["fimfic-single-space"] then
        body = body:gsub("{{!verse_eol!}}", "\n")
        body = body:gsub("{{!verse_end!}}", "\n{{!para!}}{{!paraend!}}")
        body = body:gsub("{{!verse_start!}}", "{{!para!}}{{!paraend!}}\n")
    else
        body = body:gsub("{{!verse_eol!}}{{!verse_end!}}","")
        body = body:gsub("{{!verse_eol!}}","\n")
        body = body:gsub("{{!verse_end!}}", "")
        body = body:gsub("{{!verse_start!}}", "")
    end
    -- Verse indent is configurable too:
    if metadata["fimfic-verse-indent"] then
        body = body:gsub("{{!verse_indent!}}", string.rep(' ',tonumber(metadata["fimfic-verse-indent"])))
    else
        body = body:gsub("{{!verse_indent!}}", string.rep(' ',8))
    end
    -- So is verse style
    if metadata["fimfic-verse-style"] then
        body = body:gsub("{{!verse_open!}}", metadata["fimfic-verse-style"][1])
        body = body:gsub("{{!verse_close!}}", metadata["fimfic-verse-style"][2])
    else
        body = body:gsub("{{!verse_open!}}", "[i]")
        body = body:gsub("{{!verse_close!}}", "[/i]")
    end

    -- Install footnote bodies where they belong.
    if metadata["fimfic-endnotes"] then
        body = insert_footnote_bodies(body .. "\n{{!endnotes!}}")
        body = body:gsub("{{!footnote_bodies!(.-)!}}","")
    else
        body = insert_footnote_bodies(body)
    end

    -- for double or single spacing
    -- (double-spaced by default)
    if metadata["fimfic-single-space"] then
        body = body:gsub("{{!paraend!}}%s*\n\n%s*{{!para!}}", "\n{{!para!}}")
    end

    -- Remove no longer needed paraend markers

    body = body:gsub("{{!paraend!}}", "")

    -- Indented paragraphs
    -- (Not indented by default)
    if metadata["fimfic-no-indent"] then
        body = body:gsub("{{!para!}}", "")
    else
        body = body:gsub("{{!para!}}", "\t")
    end

    -- Headers
    -- With hopefully sensible defaults
    if metadata["fimfic-header-1"] then
        body = body:gsub("{{!h1!(.-)!}}", metadata["fimfic-header-1"][1] .. "%1" .. metadata["fimfic-header-1"][2])
    else
        body = body:gsub("{{!h1!(.-)!}}", "[center][size=2em][b]%1[/b][/size][/center]")
    end
    if metadata["fimfic-header-2"] then
        body = body:gsub("{{!h2!(.-)!}}", metadata["fimfic-header-2"][1] .. "%1" .. metadata["fimfic-header-2"][2])
    else
        body = body:gsub("{{!h2!(.-)!}}", "[center][size=1.5em][b]%1[/b][/size][/center]")
    end
    if metadata["fimfic-header-3"] then
        body = body:gsub("{{!h3!(.-)!}}", metadata["fimfic-header-3"][1] .. "%1" .. metadata["fimfic-header-3"][2])
    else
        body = body:gsub("{{!h3!(.-)!}}", "[center][b]%1[/b][/center]")
    end
    if metadata["fimfic-header-4"] then
        body = body:gsub("{{!h4!(.-)!}}", metadata["fimfic-header-4"][1] .. "%1" .. metadata["fimfic-header-4"][2])
    else
        body = body:gsub("{{!h4!(.-)!}}", "[center][b]%1[/b][/center]")
    end
    if metadata["fimfic-header-5"] then
        body = body:gsub("{{!h5!(.-)!}}", metadata["fimfic-header-5"][1] .. "%1" .. metadata["fimfic-header-5"][2])
    else
        body = body:gsub("{{!h5!(.-)!}}", "[center][i]%1[/i][/center]")
    end
    if metadata["fimfic-header-6"] then
        body = body:gsub("{{!h6!(.-)!}}", metadata["fimfic-header-6"][1] .. "%1" .. metadata["fimfic-header-6"][2])
    else
        body = body:gsub("{{!h6!(.-)!}}", "[center]%1[/center]")
    end

    -- Section breaks
    -- By default is a [hr] tag (horizontal rule)
    if metadata["fimfic-section-break"] then
        body = body:gsub("{{!hr!}}", metadata["fimfic-section-break"])
    else
        body = body:gsub("{{!hr!}}", "[hr]")
    end

    -- Footnote marker. Appears at the start of the footnote block.
    if metadata["fimfic-footnote-block"] then
        body = body:gsub("{{!footnote_marker!}}", metadata["fimfic-footnote-block"])
    else
        body = body:gsub("{{!footnote_marker!}}", string.rep('﹏',40))
    end

    -- Footnote scale. Defaults to 0.75em
    if metadata["fimfic-footnote-scale"] then
        body = body:gsub("{!fnscale!}", metadata["fimfic-footnote-scale"])
    else
        body = body:gsub("{!fnscale!}", "0.75em")
    end

    -- Image caption styling.
    if metadata["fimfic-image-caption"] then
        body = body:gsub("{{!figcaption!(.-)!}}",
            metadata["fimfic-image-caption"][1] .. "%1" .. metadata["fimfic-image-caption"][2])
    else
        body = body:gsub("{{!figcaption!(.-)!}}", "[b]%1[/b]")
    end

    -- Bullet list styling.
    if metadata["fimfic-list-bullet"] then
        body = body:gsub("{{!list_bullet!}}", metadata["fimfic-list-bullet"])
    else
        body = body:gsub("{{!list_bullet!}}", "[b][icon]caret-right[/icon][/b]")
    end

    return body
end

-- The following code will produce runtime warnings when you haven't defined
-- all of the functions you need for the custom writer, so it's useful
-- to include when you're working on a writer.
local meta = {}
meta.__index =
function(_, key)
    io.stderr:write(string.format("WARNING: Undefined function '%s'",key))
    return function() return "" end
end
setmetatable(_G, meta)

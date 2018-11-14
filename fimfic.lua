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

-- Version check: We require Pandoc 2.4 or later to run,
-- because we use PANDOC_DOCUMENT, introduced in 2.4
assert(PANDOC_VERSION[1] >= 2 and PANDOC_VERSION[2] >= 4,
       "This writer requires Pandoc 2.4 or later.")

-- Functions provided by pandoc
local pipe = pandoc.pipe
local stringify = (require "pandoc.utils").stringify

-- Certain utility functions
local function isempty(s)
    return s == nil or s == ''
end

function string:split_on_char(ch)
    local result = {}
    for token in self:gmatch('[^' ..ch .. ']+') do
        table.insert(result, token)
    end
    return result
end

function string:tr_spaced(from, to)
    from, to = from:split_on_char(" "), to:split_on_char(" ")
    assert(#from == #to, "#from = "..tostring(#from)..", #to = "..tostring(#to))
    local conversion_table = {}
    for i = 1, #from do
        conversion_table[from[i]] = to[i]
    end
    local result = self:gsub("%w", conversion_table)
    return result -- to suppress gsub's second return value
end

-- Shorthand function to get at metadata.
local function metavar(name, index)
    local thatMeta = PANDOC_DOCUMENT.meta[name]
    -- If we got nothing, return nil.
    if thatMeta == nil then
        return nil
    end
    -- If we attempted to get an index and this is not a metalist, also return nil.
    if index and (
        type(thatMeta) == 'boolean' or thatMeta.tag ~= 'MetaList'
    ) then
        return nil
    end
    -- Booleans are stored as booleans. Which stringify eats,
    -- so we need to return these as is.
    if type(thatMeta) == 'boolean' then
        return thatMeta
    end
    -- Values stored as metainline need to be returned through stringify.
    if thatMeta.tag == 'MetaInlines' then
        return stringify(thatMeta)
    end
    -- List items need to be gotten out before getting stringified.
    -- Notice that boolean list items won't work, but we don't use those.
    if thatMeta.tag == 'MetaList' then
        return stringify(thatMeta[index])
    end
    -- If we don't know what to do, return nil and print a warning.
    io.stderr:write(string.format(
                        "WARNING: Unhandled metavar type for var: '%s'", name
    ))
    return nil
end

-- Table to store footnotes, so they can be included at the end.
local notes = {}

--- Continuing with functions that rended corresponding pandoc elements.

-- Blocksep is used to separate block elements.
function Blocksep()
    return "\n\n"
end

function Str(s)

    -- Faux emoji are handled here, at string level:
    -- Font awesome.
    s = s:gsub(":fa%-(.-):", "[icon]%1[/icon]")
    -- Page break.
    s = s:gsub(":page_break:", "[page_break]")

    return s
end

function Space()
    return " "
end

function SoftBreak()
    return " "
end

function LineBreak()
    return "\n"
end

function Emph(s)
    return "[em]" .. s .. "[/em]"
end

function Strong(s)
    return "[strong]" .. s .. "[/strong]"
end

function Subscript(s)
    return "[sub]" .. s .. "[/sub]"
end

function Superscript(s)
    return "[sup]" .. s .. "[/sup]"
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
    -- Intra-site urls should be relative.
    local http = "http://www.fimfiction.net"
    local https = "https://www.fimfiction.net"
    if string.starts(src, http) then
        return "[url=" .. string.sub(src,string.len(http)+1)
            .. "]" .. s .. "[/url]"
    end
    if string.starts(src, https) then
        return "[url=" .. string.sub(src,string.len(https)+1)
            .. "]" .. s .. "[/url]"
    end
    -- Urls which have class 'youtube' will be assumed to refer to youtube
    -- and rendered as an embed tag with a known working url.
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
            return "[center][embed]https://www.youtube.com/watch?v=" ..
                src .. "][/embed][/center]"
        end
        return "[center][embed]https://www.youtube.com/watch?v=" ..
            src .. "[/embed]{{!figcaption!".. s .."!}}[/center]"
    end
    -- Urls which have class 'embed' will be wrapped in embed tag,
    -- and let fimfiction sort it out whether it can or cannot embed it.
    if attr["class"] == "embed" then
        return "[center][embed]" .. src .. "[/embed][/center]"
    end
    -- Everything else is a regular old url.
    return "[url=" .. src .. "]" .. s .. "[/url]"
end

function captioned_img(src, caption)
    if isempty(caption) then
        return "[center][img]" .. src .. "[/img][/center]"
    end

    local captionstart = metavar("fimfic-image-caption", 1)
    local captionend =  metavar("fimfic-image-caption", 2)

    if not captionstart then
        captionstart = "[strong]"
        captionend = "[/strong]"
    end

    return "[center][img]" .. src .. "[/img]\n" .. captionstart
        .. caption .. captionend .. "[/center]"

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

-- Inline code is supported by FimFiction. Which is actually a bit annoying.
-- For literary purposes, it's best rendered as monospace:
-- should anyone actually want to talk about actual code,
-- a codeblock is a better option.
-- Fortunately, we can make this configurable at runtime.
function Code(s, attr)
    if metavar("fimfic-inline-code", 1)
    and metavar("fimfic-inline-code", 2) then
        return metavar("fimfic-inline-code", 1) ..
            s .. metavar("fimfic-inline-code", 2)
    end
    return "[code]" .. s .. "[/code]"
end

-- FimFiction does support "math mode" -- in MathJax terms.
-- Best effort is to pass this through.
function InlineMath(s)
    return "[math]" .. s .. "[/math]"
end

function DisplayMath(s)
    return "[mathblock]" .. s .. "[/mathblock]"
end

-- FimFiction does not have proper support for footnotes,
-- so we will fake it by inserting the text and markers
-- ourselves.

function Note(s)
    local num = #notes + 1
    table.insert(notes, s)
    -- Write out the footnote reference with targeting markers.
    local charnum = tonumber(num)

    local fnstart = "[strong][sup][size=0.75em]"
    local fnend = "[/size][/sup][/strong]"
    if metavar("fimfic-footnote-marker-style", 1) then
        fnstart = metavar("fimfic-footnote-marker-style", 1)
        fnend = metavar("fimfic-footnote-marker-style", 2)
    end

    return fnstart .. charnum .. fnend .. '{{!fn'.. num ..'!}}'
end

-- These are Unicode open and close quote characters.
-- Used with pandoc's +smart option
function SingleQuoted(s)
    return "‘" .. s .. "’"
end

function DoubleQuoted(s)
    return "“" .. s .. "”"
end

-- FimFiction allows text to have size and color set,
-- which is not possible in MarkDown. As a workaround,
-- this will detect Spans that have relevant style
-- attributes set, or act on specific given classes.
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
    if attr["class"] then
        if attr["class"] == "blackletter" then
            text = "{{!blackletter!" .. text .. "!}}"
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
        if #buff > 0 then
            block = "{{!footnote_bodies_pre!".. table.concat(buff,"!") ..
                "!}}" .. block .. "{{!footnote_bodies_post!"..
                table.concat(buff,"!") .. "!}}"
        end
    end
    return block
end

function style_footnote_block(footnote_table)
    local quoteblock = table.concat(footnote_table, '\n')
    -- Prevent failures on urlencoded urls in footnotes.
    quoteblock = quoteblock:gsub("%%", "%%%%")
    return "{{!footnote_block_begins!}}" .. quoteblock .. "{{!footnote_block_ends!}}"
end

function style_footnote_start(key, note)
    local fnstart = "[strong]("
    local fnend = ")[/strong]"
    if metavar("fimfic-footnote-marker-style", 3) then
        fnstart = metavar("fimfic-footnote-marker-style", 3)
        fnend = metavar("fimfic-footnote-marker-style", 4)
    end
    return fnstart .. key .. fnend .. note
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
                local numbers = marker:gsub("{{!footnote_bodies!(.-)!}}",
                                            "%1" ):split_on_char("!")
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

-- Spacing is a user option now...
function Para(s)
    -- Use this moment to see if the paragraph contains any footnotes and
    -- render them as their own quote block and remove the marker.
    return insert_footnotes(s)
end

-- FimFiction has headers, but we might want to customize them.
function Header(lev, s, attr)
    if metavar("fimfic-header-" .. lev, 1) then
        return metavar("fimfic-header-" .. lev, 1) ..
            s .. metavar("fimfic-header-" .. lev, 2)
    end
    return "[h" .. lev .. "]" .. s .. "[/h" .. lev .."]"
end

function BlockQuote(s)
    return "[quote]\n" .. s .. "[/quote]"
end

function HorizontalRule()
    if metavar("fimfic-section-break") then
        return metavar("fimfic-section-break")
    end
    return "[hr]"
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
function CodeBlock(s, attr)
    if attr['class'] ~= "" then
        return "[codeblock=" .. attr['class'] .. "]" .. s .. "[/codeblock]"
    end
    return "[codeblock]" .. s .. "[/codeblock]"
end

-- FimFiction has proper list tags these days.
function BulletList(items)
    local buffer = {}
    for _, item in pairs(items) do
        table.insert(buffer, "[*]" .. insert_footnotes(item ))
    end
    return "[list]" .. table.concat(buffer, "\n") .. "[/list]"
end

function OrderedList(items)
    local buffer = {}
    for num, item in pairs(items) do
        table.insert(buffer, "[*]" .. insert_footnotes(item))
    end
    return "[list=1]" .. table.concat(buffer, "\n") .. "[/list]"
end

-- But proper list tags do not include definition lists.
function DefinitionList(items)
    local buffer = {}
    -- These are individual definitions.
    for _, item in pairs(items) do
        -- but we still need to iterate over that because pandoc is being stupid.
        for k, v in pairs(item) do
             table.insert(buffer, "[strong]" .. k .. ":[/strong] " ..
                              table.concat(v, ", "))
        end
    end
    return insert_footnotes(table.concat(buffer, "\n"))
end

-- FimFiction does not have tables.
-- This whole thing is a remarkably poor attempt at doing them and needs to be rewritten.
function Table(caption, aligns, widths, headers, rows)
    local buffer = {}
    local function add(s)
        table.insert(buffer, s)
    end
    if caption ~= "" then
        add("[center][strong]" .. caption .. "[/strong][/center]\n")
    end
    local header_row = {}
    local empty_header = true
    for i, h in pairs(headers) do
        table.insert(header_row, "[strong]" .. h .. "[/strong]")
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

-- Some trickery: Imitating cursive script through Unicode abuse.
-- Namely, we're going to exploit the Mathematical Styled Latin section.

function UnicodeCursive(s)
    return tostring(s):tr_spaced(
        "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z " ..
            "a b c d e f g h i j k l m n o p q r s t u v w x y z ",
        "𝓐 𝓑 𝓒 𝓓 𝓔 𝓕 𝓖 𝓗 𝓘 𝓙 𝓚 𝓛 𝓜 𝓝 𝓞 𝓟 𝓠 𝓡 𝓢 𝓣 𝓤 𝓥 𝓦 𝓧 𝓨 𝓩 " ..
            "𝓪 𝓫 𝓬 𝓭 𝓮 𝓯 𝓰 𝓱 𝓲 𝓳 𝓴 𝓵 𝓶 𝓷 𝓸 𝓹 𝓺 𝓻 𝓼 𝓽 𝓾 𝓿 𝔀 𝔁 𝔂 𝔃 "
    )
end

-- For further Unicode abuse, we can have Blackletter.
function Blackletter(s)
    return tostring(s):tr_spaced(
        "A B C D E F G H I J K L M N O P Q R S T U V W X Y Z " ..
            "a b c d e f g h i j k l m n o p q r s t u v w x y z ",
        "𝕬 𝕭 𝕮 𝕯 𝕰 𝕱 𝕲 𝕳 𝕴 𝕵 𝕶 𝕷 𝕸 𝕹 𝕺 𝕻 𝕼 𝕽 𝕾 𝕿 𝖀 𝖁 𝖂 𝖃 𝖄 𝖅 " ..
            "𝖆 𝖇 𝖈 𝖉 𝖊 𝖋 𝖌 𝖍 𝖎 𝖏 𝖐 𝖑 𝖒 𝖓 𝖔 𝖕 𝖖 𝖗 𝖘 𝖙 𝖚 𝖛 𝖜 𝖝 𝖞 𝖟 "
    )
end

-- FimFiction has no concept of Divs or the possible
-- attribute they could have. But we can use them to apply fimfiction formatting.
function Div(s, attr)
    text = s
    if attr['class'] == 'verse' then
        -- If we've marked it as a verse, wrap it in [pre-line].
        -- Leave a marker for an indent tag.
        if metavar("fimfic-verse-wrapper", 1) then
            text = metavar("fimfic-verse-wrapper", 1) ..
                text .. metavar("fimfic-verse-wrapper", 2)
        else
            text = "[indent=2][i][pre-line]" .. text ..
                "[/pre-line][/i][/indent]"
        end
    end
    if attr['class'] == 'letter' then
        text = "[quote]{{!cursive!}}" .. text .. "{{!cursiveend!}}[/quote]"
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

    -- Replace temporary markup with correct markup -- it's easier to position
    -- footnotes properly once we have the full text processed, rather
    -- than before.

    -- If footnotes are to be installed at the beginning of the paragraph,
    -- clean out the paragraph-ending tags.
    -- Otherwise, clean out the paragraph-beginning tags.
    if metadata["fimfic-footnote-pre"] then
        body = body:gsub("{{!footnote_bodies_post!(.-)!}}","")
        body = body:gsub("{{!footnote_bodies_pre!","{{!footnote_bodies!")
    else
        body = body:gsub("{{!footnote_bodies_pre!(.-)!}}","")
        body = body:gsub("{{!footnote_bodies_post!","{{!footnote_bodies!")
    end

    -- Install footnote bodies where they belong.
    if metadata["fimfic-endnotes"] then
        body = insert_footnote_bodies(body .. "\n{{!endnotes!}}")
        body = body:gsub("{{!footnote_bodies!(.-)!}}","")
    else
        body = insert_footnote_bodies(body)
    end

    -- Footnote block tag. Wraps a footnote block.
    if metadata["fimfic-footnote-block-tag"] then
        body = body:gsub("{{!footnote_block_begins!}}",
                         metadata["fimfic-footnote-block-tag"][1])
        body = body:gsub("{{!footnote_block_ends!}}",
                         metadata["fimfic-footnote-block-tag"][2])
    else
        body = body:gsub("{{!footnote_block_begins!}}",
                         "[quote=Footnotes][size=0.75em]")
        body = body:gsub("{{!footnote_block_ends!}}", "[/size][/quote]")
    end

    -- Fake font spans and blocks.
    -- There is, unfortunately, no easy way to handle this correctly,
    -- i.e. at Str level, since Str doesn't know whether it has any styled
    -- parents. I'd have to walk the tree to do this.
    if metadata["fimfic-disable-unicode-trickery"] then
        body = body:gsub("{{!blackletter!(.-)!}}", "[b]%1[/b]")
        body = body:gsub("{{!cursive!}}(.-){{!cursiveend!}}", "%1")
    else
        body = body:gsub("{{!blackletter!(.-)!}}", Blackletter)
        body = body:gsub("{{!cursive!}}(.-){{!cursiveend!}}", UnicodeCursive)
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

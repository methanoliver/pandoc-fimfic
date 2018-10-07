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
        return "[url=" .. string.sub(src,string.len(http)+1) .. "]" .. s .. "[/url]"
    end
    if string.starts(src, https) then
        return "[url=" .. string.sub(src,string.len(https)+1) .. "]" .. s .. "[/url]"
    end
    -- Urls which have class 'youtube' will be assumed to refer to youtube
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
            return "[center][embed]https://www.youtube.com/watch?v=" .. src .. "][/embed][/center]"
        end
        return "[center][embed]https://www.youtube.com/watch?v=" .. src .. "[/embed]{{!figcaption!".. s .."!}}[/center]"
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

-- Inline code is supported by FimFiction. Which is actually a bit annoying.
-- For literary purposes, it's best rendered as monospace, though:
-- should anyone actually want to talk about actual code,
-- a codeblock is a better option.
-- But I want to make that configurable at runtime...
function Code(s, attr)
    return "{!inlinecodestart!}" .. s .. "{!inlinecodeend!}"
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
    return '{{!sfn_sb_pre!}}' .. charnum .. '{{!sfn_sb_post!}}{{!fn'.. num ..'!}}'
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
    return "{{!sfn_sbb_pre!}}" .. key .. '{{!sfn_sbb_post!}}' .. note
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

-- Spacing is a user option now...
function Para(s)
    -- Use this moment to see if the paragraph contains any footnotes and
    -- render them as their own quote block and remove the marker.
    return insert_footnotes(s)
end

-- FimFiction has headers, but we might want to customize them.
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
    for _,item in pairs(items) do
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
    local result = self:gsub("%w", conversion_table)
    return result -- to suppress gsub's second return value
end

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
        text = "{{!verse_wrapper_start!}}[pre-line]" .. text .. "[/pre-line]{{!verse_wrapper_end!}}"
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

    -- Replace temporary markup with correct markup now
    -- that the metadata is available.

    -- Code tag is switchable:
    if metadata["fimfic-inline-code"] then
        body = body:gsub("{!inlinecodestart!}", metadata["fimfic-inline-code"][1])
        body = body:gsub("{!inlinecodeend!}", metadata["fimfic-inline-code"][2])
    else
        body = body:gsub("{!inlinecodestart!}", "[code]")
        body = body:gsub("{!inlinecodeend!}", "[/code]")
    end

    -- Verse wrapping is configurable:
    if metadata["fimfic-verse-wrapper"] then
        body = body:gsub("{{!verse_wrapper_start!}}", metadata["fimfic-verse-wrapper"][1])
        body = body:gsub("{{!verse_wrapper_end!}}", metadata["fimfic-verse-wrapper"][2])
    else
        body = body:gsub("{{!verse_wrapper_start!}}", "[indent=2][i]")
        body = body:gsub("{{!verse_wrapper_end!}}", "[/i][/indent]")
    end

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

    -- Headers
    -- With hopefully sensible defaults
    if metadata["fimfic-header-1"] then
        body = body:gsub("{{!h1!(.-)!}}", metadata["fimfic-header-1"][1] .. "%1" .. metadata["fimfic-header-1"][2])
    else
        body = body:gsub("{{!h1!(.-)!}}", "[h1]%1[/h1]")
    end
    if metadata["fimfic-header-2"] then
        body = body:gsub("{{!h2!(.-)!}}", metadata["fimfic-header-2"][1] .. "%1" .. metadata["fimfic-header-2"][2])
    else
        body = body:gsub("{{!h2!(.-)!}}", "[h2]%1[/h2]")
    end
    if metadata["fimfic-header-3"] then
        body = body:gsub("{{!h3!(.-)!}}", metadata["fimfic-header-3"][1] .. "%1" .. metadata["fimfic-header-3"][2])
    else
        body = body:gsub("{{!h3!(.-)!}}", "[h3]%1[/h3]")
    end
    if metadata["fimfic-header-4"] then
        body = body:gsub("{{!h4!(.-)!}}", metadata["fimfic-header-4"][1] .. "%1" .. metadata["fimfic-header-4"][2])
    else
        body = body:gsub("{{!h4!(.-)!}}", "[h4]%1[/h4]")
    end
    if metadata["fimfic-header-5"] then
        body = body:gsub("{{!h5!(.-)!}}", metadata["fimfic-header-5"][1] .. "%1" .. metadata["fimfic-header-5"][2])
    else
        body = body:gsub("{{!h5!(.-)!}}", "[h5]%1[/h5]")
    end
    if metadata["fimfic-header-6"] then
        body = body:gsub("{{!h6!(.-)!}}", metadata["fimfic-header-6"][1] .. "%1" .. metadata["fimfic-header-6"][2])
    else
        body = body:gsub("{{!h6!(.-)!}}", "[h6]%1[/h6]")
    end

    -- Section breaks
    -- By default is a [hr] tag (horizontal rule)
    if metadata["fimfic-section-break"] then
        body = body:gsub("{{!hr!}}", metadata["fimfic-section-break"])
    else
        body = body:gsub("{{!hr!}}", "[hr]")
    end

    -- Footnote block tag. Wraps a footnote block.
    if metadata["fimfic-footnote-block-tag"] then
        body = body:gsub("{{!footnote_block_begins!}}", metadata["fimfic-footnote-block-tag"][1])
        body = body:gsub("{{!footnote_block_ends!}}", metadata["fimfic-footnote-block-tag"][2])
    else
        body = body:gsub("{{!footnote_block_begins!}}", "[quote=Footnotes]{{!fnscale!}}")
        body = body:gsub("{{!footnote_block_ends!}}", "{{!fnscale_end!}}[/quote]")
    end
    
    -- Footnote brackets.
    if metadata["fimfic-footnote-marker-style"] then
        body = body:gsub("{{!sfn_sb_pre!}}", metadata["fimfic-footnote-marker-style"][1])
        body = body:gsub("{{!sfn_sb_post!}}", metadata["fimfic-footnote-marker-style"][2])
        body = body:gsub("{{!sfn_sbb_pre!}}", metadata["fimfic-footnote-marker-style"][3])
        body = body:gsub("{{!sfn_sbb_post!}}", metadata["fimfic-footnote-marker-style"][4])
    else
        body = body:gsub("{{!sfn_sb_pre!}}", "[strong][sup]{{!fnscale!}}(")
        body = body:gsub("{{!sfn_sb_post!}}", "){{!fnscale_end!}}[/sup][/strong]")
        body = body:gsub("{{!sfn_sbb_pre!}}", "[strong](")
        body = body:gsub("{{!sfn_sbb_post!}}", ")[/strong] ")
    end

    -- Footnote scale. Defaults to 0.75em
    if metadata["fimfic-footnote-scale"] then
        body = body:gsub("{{!fnscale!}}", "[size=" .. metadata["fimfic-footnote-scale"] .. "]")
    else
        body = body:gsub("{{!fnscale!}}", "[size=0.75em]")
    end
    body = body:gsub("{{!fnscale_end!}}", "[/size]")

    -- Image caption styling.
    if metadata["fimfic-image-caption"] then
        body = body:gsub("{{!figcaption!(.-)!}}",
            metadata["fimfic-image-caption"][1] .. "%1" .. metadata["fimfic-image-caption"][2])
    else
        body = body:gsub("{{!figcaption!(.-)!}}", "[strong]%1[/strong]")
    end

    -- Fake font spans and blocks.
    if metadata["fimfic-disable-unicode-trickery"] then
        body = body:gsub("{{!blackletter!(.-)!}}", "[b]%1[/b]")
        body = body:gsub("{{!cursive!}}(.-){{!cursiveend!}}", "%1")
    else
        body = body:gsub("{{!blackletter!(.-)!}}", Blackletter)
        body = body:gsub("{{!cursive!}}(.-){{!cursiveend!}}", UnicodeCursive)
    end

    -- Faux emoji:
    -- Font awesome.
    body = body:gsub(":fa%-(.-):", "[icon]%1[/icon]")
    -- Page break.
    body = body:gsub(":page_break:", "[page_break]")

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

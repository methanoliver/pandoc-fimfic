pandoc-fimfic
=============

Custom Writer for Pandoc that writes FimFiction.net compatible bbcode.

This script requires Pandoc, a program for converting documents between
several different formats, created by John MacFarlane. Find it at
<http://pandoc.org/>. Please see the Pandoc User's Guide at the
same page for details and options for using Pandoc that are not
covered in this Readme.

This version builds upon the original version first written by HeirOfNorton,
and is primarily different by the inclusion of superscript and subscript
emulation, as well as other customizations and updates to changes in 
Fimfiction bbcode emulation.

For a reference of bbcode tags supported by FimFiction, see
[BBCODE.md](BBCODE.md)

Usage
-----

Use this script like any other output format for Pandoc, eg:

    pandoc -t path/to/fimfic.lua mystory.md -o mystory.bbcode

The output text can then be copied and pasted into the story edit
box on FimFiction, usually unchanged.

Compatibility
-------------

This listing will focus on Markdown, HTML, and MS Word DOCX input
formats, as I believe these will be the most commonly used.

### What Works ###

*   **Paragraphs**: These may be entered as normal for each input
    format (Double spacing for Markdown, \<p> tags for HTML, etc.)
    and will be output correctly. See the next section for how
    to change the paragraph formatting in the output.

*   **Basic Formating**: Bold, italic, underlines, and strike-throughs
    work and are output correctly. Images (linked from an
    external website) should work as well.

*   **Links**: Links to off-site resources will be rendered as usual.
    Links to Fimfiction itself will be rendered using the \[site_url\] tag.
    You can use a link to youtube to produce a centered youtube video tag
    by giving the link a "youtube_inline" title.

*   **Code**: Fimfiction has a [code] tag, which works for block level,
    but does not work for inline, and it still executes the bbcode
    inside it. But this formatter works around this by inserting \[b\]\[/b\]
    after every opening bracket, thus preventing the execution of bbcode
    inside code blocks and producing reasonable-looking fixed width output.

*   **Basic Styles**: Block quotes are output correctly. FimFiction
    does not have proper Headings, but sensible equivalent formatting
    will be used, and the formatting can be customized.

    Use Styles in MS Word. Ie. Use the drop-down menu of styles to choose
    the type of paragraph (Normal, Block Quote, Heading, etc.). This
    should work and be converted if possible. Never apply paragraph
    formatting directly, as this will _not_ be converted.

*   **Footnotes**: Footnotes will be gathered together and inserted after
    the paragraph they appear in, rendered in a marked up quote block.
    Footnotes use unicode characters to imitate superscript, because
    Fimfiction does not have the capability for real superscript.

*   **BBCode**: When all else fails, you can use bbcode directly in
    your document. Pandoc will pass any bbcode found through without
    changing it, while still converting whatever it can.


### What Kind of Works ###

*   **Lists & Tables**: Bullet, Number, and Definition lists are output as
    plain-text versions of the lists using FontAwesome markers for list
    bullets. FimFiction does not support lists in its bbcode, so no better
    options are possible.
    This is also true of tables.
    
*   **Divs**: Fimfiction has no concept of a Pandoc div. However,
    a provision to mark up verse as a div by giving it a class has been coded:

        <div class="verse">

        | There is a mare in Canterlot
        | They call the Rising Sun
        | She loves all ponies in this world
        | Of them I am but one...

        </div>
        
    Unless you change the code, this will render the said div with an extra
    indent and in italics.

*   **Small Caps, Colored text, Size**: This is due to a limitation of
    Pandoc. Pandoc, generally, does not have markup for (or recognize)
    small caps, colored text, or text with a size. As one exception,
    text enclosed in `<span>` tags with an appripriate `style` attribute
    set will be converted. Eg:
    
        <span style="text-size: 2em;">Big Text</span>

    This uses the standard CSS keywords for these features:
    `font-variant: small-caps;`,
    `text-size: 1.5em;`,
    `color: #F2F260;`

    Unfortunately, this only works in HTML (or in Markdown, which allows
    arbitrary HTML to be entered). Changing the color or size of text
    in MS Word does _not_ work. Again, though, simply entering the
    appropriate BBCode directly does work in all major formats.

### What Does Not Work ###

*   **Direct Formating**: Directly applying paragraph formatting in
    MS Word does not work, and likely never will. Most character
    formatting (eg. changed fonts, size and color, drop shadow) does
    not work either.

*   **Centered Text**: Centering a paragraph does not transfer, as Pandoc
    itself does not recognize centered text. The only way to get centered
    text is to use a customized Heading (see next section) or use the
    `[center]` BBCode tags directly.

Customization
-------------

Because FimFiction allows some variation in style, and different authors
like to use different styles, this script has a few options for
customization of the output. It has options for changing the formatting
of normal paragraphs, the BBCode used for Headings, the appearance of
section breaks.

All of these options are changed using the Metadata for the document.
If the input file is in Markdown format, this can be included as a
YAML Metadata block within the document itself. For _all_ formats,
the Metadata can be specified using the Pandoc option
`-M KEY=VALUE` or `--metadata=KEY:VALUE`.

It generally preferable to use a YAML file, however, especially if you're
working on a story with multiple chapters:

    pandoc -t path/to/fimfic.lua config.yaml mystory.md -o mystory.bbcode

Where config.yaml looks something like this:

```
---
fimfic-no-indent: true
fimfic-single-space: false
fimfic-section-break: "`[center][size=1.25em][b]✶              ✶              ✶[/b][/size][/center]`"
...
```

Notice the use of backticks for fimfic-section-break. Pandoc interprets
string literals in embedded metadata variables as Markdown strings, and using
backticks prevents it from compressing the spaces.

All of the options have a `fimfic-` prefix to avoid clashing with any
other Metadata used in the document.

#### fimfic-single-space ####

By default paragraphs are formatted with a blank space in between them,
so they will be double-spaced when published. If you prefer single-spaced
paragraphs, include this option and give it any non-nil value, eg.
`fimfic-single-space: True`. This will remove the extra spaces between
paragraphs. This will still include double spaces around Heading and
section breaks, for clarity.

#### fimfic-no-indent ####

By default paragraphs are formatted with an indent, as this is the most
common formatting currently seen on FimFiction. If you prefer paragraphs
with no indent, include this option with any non-nil value and paragraphs
will not be automatically indented.

#### fimfic-header-1 to fimfic-header-6 ####

FimFiction does not have BBCode especially for Headers, so in order to
create headers they must be formatted directly using relevant BBCode
tags. Each of these options expects a List of two (2) Strings, which will
be output before and after the text of the Heading.

For example, if we define `fimfic-header-2` like this:

    fimfic-header-2:
      - [size=2em][center]
      - [/center][/size]

and in the document we have this Heading (Markdown format):

    Part Two: Twilight's Diary
    --------------------------

then it will be written in the final document like this:

    [size=2em][center]Part Two: Twilight's Diary[/center][/size]

Remember that each definition expects a list of 2 items, to go before
and after the Header text. It is an error not to have both items.
If you wish to only use one, have an empty string `""` for the other.
The lists can also but written in between brackets, like in JSON:
`fimfiction-header-5: ["[b]" , "[/b]"]`

The default definitions of these Headers is below.

    fimfic-header-1: ["[center][size=2em]", "[/size][/center]"]
    fimfic-header-2: ["[center][size=1.5em]", "[/size][/center]"]
    fimfic-headar-3: ["[center][b]", "[/b][/center]"]
    fimfic-header-4: ["[center][b]", "[/b][/center]"]
    fimfic-header-5: ["[center][i]", "[/i][/center]"]
    fimfic-header-6: ["[center]", "[/center]"]

#### fimfic-section-break ####

This option allows you to customize the way section breaks are
formatted in the output. By default, this script simply uses
the standard `[hr]` tag. To change this, define this option as
any string. This string will be used instead, eg.

    fimfic-section-break: [center]* * * * *[/center]

Remember that the contents of this string will be interpreted as
Markdown, so you will need to escape some characters with backslash
(` \\ `) if you do not want them to be converted.

#### fimfic-footnote-block ####

This option allows you to customize the start of the footnote block.
As footnotes are output in quote blocks, a need exists to distinguish them
visually from other quote blocks. They are printed with reduced font size,
and with this string at the beginning of the block. By default, this 
is 40 repetitions of a low horizontal wavy line character, "﹏".

#### fimfic-verse-style ####

By default, every line of a verse block is wrapped with `[i][/i]`. This is
obviously not to everybody's taste, so you can configure the wrapper tag
just like you can configure a header:

    fimfic-verse-style: ["[size=1.1em][i]", "[/i][/size]"]

#### fimfic-verse-indent ####

The aforementioned verse blocks are indented with a number of spaces, 8 by
default. Fimfiction, contrary to the common practices, does not compress spaces
in resulting HTML, preferring to render all spaces beyond the first one with
`&nbsp;` in every run of spaces longer than one, which is a crude but workable
way to set up paragraphs with specific indents.

This option lets you change the number of spaces the verse block will be
indented by.

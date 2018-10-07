pandoc-fimfic
=============

Custom Writer for Pandoc that writes FimFiction.net compatible bbcode.

This script requires Pandoc, a program for converting documents between
several different formats, created by John MacFarlane. Find it
at <http://pandoc.org/>. Please see the Pandoc User's Guide at the same page
for details and options for using Pandoc that are not covered in this Readme.

This version builds upon the original version first written by HeirOfNorton,
and is primarily different by much more extensive support for styling
footnotes, as well as other customizations and updates to changes in
Fimfiction bbcode emulation.

Works with Pandoc v2.0.1 or newer.

Usage
-----

Use this script like any other output format for Pandoc, eg:

    pandoc -t path/to/fimfic.lua mystory.md -o mystory.bbcode

The output text can then be copied and pasted into the story edit
box on FimFiction, usually unchanged.

Compatibility
-------------

This listing will focus on Markdown, as this is the source format I am using,
and I have so far not seen an indication anyone but me is employing this
tool. If you do use it, send me a line!

### What Works ###

*   **Paragraphs**: These may be entered as normal for each input format
    (Double spacing for Markdown, `<p>` tags for HTML, etc.)  and will be
    output correctly. See the next section for how to change the paragraph
    formatting in the output.

*   **Basic Formating**: Bold, italic, underlines, and strike-throughs work
    and are output correctly. Small caps requires the use of a `[Small
    caps]{.smallcaps}` span in Markdown.

*   **Images**: Cannot be embedded into the text, because FimFiction does not
    support data URLs, but can be linked to. In Markdown, an image used as a
    block element will be rendered centered and with a caption below, and so
    will be an image given an explicit `{.centered}` class.

*   **Links**: Links to off-site resources will be rendered as usual.  Links
    to Fimfiction itself will be rendered as relative links.  You can
    use a link to youtube to produce an embedded youtube video tag by giving
    the link a "youtube" class. In Markdown, this is done like this:

        [This will be used as caption](https://www.youtube.com/watch?v=C9H_FDZGkUw){.youtube}

*   **Code**: Fimfiction has code tags. You can specify a language for syntax
    highlighting like this:

        ```{.python}
        # This here will be highlighted as python code.
        ```

    Fimfiction uses Prism to do the syntax highlighting, so you can refer to
    the list of supported languages
    in [Prism manual.](http://prismjs.com/#languages-list)

*   **Basic Styles**: Block quotes are output correctly. While FimFiction does
    have proper Headings these days, their formatting can be customized.

    Use Styles in MS Word. Ie. Use the drop-down menu of styles to choose the
    type of paragraph (Normal, Block Quote, Heading, etc.). This should work
    and be converted if possible. Never apply paragraph formatting directly,
    as this will _not_ be converted.

*   **Footnotes**: There are multiple configuration options relating to how to
    style footnotes. Read on.

*   **Lists**: After the recent update, Fimfiction includes full support for
    all kinds of lists, except definition lists. These will be imitated
    through a series of paragraphs starting with bold.

*   **BBCode**: When all else fails, you can use bbcode directly in your
    document. Pandoc will pass any bbcode found through without changing it,
    while still converting whatever it can. Occasionally, this might cause it
    to recognize bbcode as links, in which case, you can escape the square
    brackets with a backslash. Beware that using an URL in bbcode can cause
    Pandoc to attempt to turn it into a link, dumping a load of bbcode where
    you don't want it -- in which case, it helps to escape the `:` in it, like
    `https\://...`


### What Kind of Works ###

*   **Tables**: Are not being tested and probably do not work. Fimfiction has
    no support for tables, and the only hope of imitating them is using
    pre-formatted text, which, while theoretically possible within the
    confines of a Pandoc formatter, is too cumbersome to bother with. Pull
    requests welcome.

*   **Divs**: Fimfiction has no concept of a Pandoc div or span. However,
    Pandoc divs and spans are used to give the formatter instructions
    regarding FimFiction-specific markup, see below.

*   **Small Caps, Colored text, Size**: This is a limitation of
    Pandoc. Pandoc, generally, does not have markup for (or recognize) small
    caps, colored text, or text with a size. Text enclosed in `<span>` tags
    with an appripriate `style` attribute set will be rendered using
    appropriate FimFiction tags, however. Eg:

        <span style="text-size: 2em;">Big Text</span>

        [Big Text]{style="text-size: 2em;"}

    Either syntax is permitted. This uses the standard CSS keywords for these
    features:

    `font-variant: small-caps;`,  
    `text-size: 1.5em;`,  
    `color: #F2F260;`

    Unfortunately, this only works in HTML or Markdown. Changing the color or
    size of text in MS Word does _not_ work. Again, though, simply entering
    the appropriate BBCode directly does work in all major formats.

*   **Centered, Right text**: Should you feel the need to explicitly center or
    right-align a paragraph, you do this by wrapping it in a `<div>` with
    `right` or `center` class:

        <div class="right">

        This paragraph will be right-aligned in Fimfiction, and you can easily
        style it so that it's right-aligned in html or epub, too.

        </div>
        
    You can also use the new Markdown syntax for divs with a class:
    
        :::{.right}
        
        This will be right-aligned.
        
        :::

### Extra trickery ###

There are times when one wishes to achieve a specific typesetting effect which
is not normally feasible with the constraints of FimFiction BBCode. Some of
this trickery, which would be easy enough using CSS in HTML or EPUB, is
realized here by assigning a class to a div. Whether you want to use them or
not is up to you:

* **Verse**: You can use this to render verse in a way that will not break
  formatting. The formatter uses `[pre-line]` and the results are
  customizable:

        <div class="verse">

        There is a mare in Canterlot\
        They call the Rising Sun\
        She loves all ponies in this world\
        Of them I am but one...

        </div>
        
    Or use Pandoc's new syntax:
    
        :::{.verse}
        
        This works the same\
        Or maybe not\
        Observe the problems\
        It hath wrought...
        
        :::

    Unless you change the code, this will render the said div with an extra
    indent and in italics. Notice the backslashes at the ends of the lines,
    which indicate an explicit line break in Pandoc flavor of Markdown.

* **Letters**: Class `letter` will render something in a `[quote]` block,
  replacing Latin letters with their equivalents from the Mathematical Styled
  Latin codeblock, mandated by MathML standard. This results in a neat letter
  written in cursive, like so: 𝓐𝓑𝓒𝓓𝓔𝓕... The resulting letters render normally
  on most platforms so far seen, except Nvidia Shield, for some bizarre
  reason. I encourage you to publish your own EPUB file if this is a concern,
  where you can employ CSS styling as you see fit -- but this is a good idea in
  any case. One notable limitation of this is that no formatting can occur
  *inside* the letter block -- it will be mangled by the process.

        :::{.letter}
        
        Dear Princess Celestia,
        
        ...
        
        :::

* **Blackletter**: One other notable abuse of extra Unicode symbols that
  appears to work well is
  [Blackletter](https://en.wikipedia.org/wiki/Blackletter), or what is
  colloquially called, "Goth font" or "Fraktur": 𝕲𝖔𝖙𝖍. It has the same
  limitations as the letter block.

        [I don't recommend using it often.]{.blackletter}
        
        <span class="blackletter">But in moderation it can be cool.</span>

### What Does Not Work ###

*   **Direct Formating**: Directly applying paragraph formatting in MS Word
    does not work, and likely never will. Most character formatting
    (eg. changed fonts, size and color, drop shadow) does not work either.

*   **Centered Text**: Centering a paragraph will not transfer, unless you do
    it as described above, i.e. by using a classed `<div>`.

Customization
-------------

Because FimFiction allows some variation in style, and different authors like
to use different styles, this script has a few options for customization of
the output. It has options for changing the formatting of normal paragraphs,
the BBCode used for Headings, the appearance of section breaks.

All of these options are changed using the Metadata for the document.  If the
input file is in Markdown format, this can be included as a YAML Metadata
block within the document itself. For _all_ formats, the Metadata can be
specified using the Pandoc option `-M KEY=VALUE` or `--metadata=KEY:VALUE`.

It generally preferable to use a YAML file, however, especially if you're
working on a story with multiple chapters:

    pandoc -t path/to/fimfic.lua config.yaml mystory.md -o mystory.bbcode

Where config.yaml looks something like this:

```
---
fimfic-no-indent: true
fimfic-single-space: false
fimfic-section-break: "[center][size=1.25em][b]✶     ✶     ✶[/b][/size][/center]"
...
```

Notice the use of special [non-breaking Unicode space character][nbsp] for
fimfic-section-break. Pandoc interprets string literals in embedded metadata
variables as Markdown strings, in which regular spaces would be compressed.

[nbsp]: http://www.fileformat.info/info/unicode/char/00a0/index.htm

All of the options have a `fimfic-` prefix to avoid clashing with any other
Metadata used in the document.

### General styling

#### fimfic-header-1 to fimfic-header-6 ####

FimFiction does have BBCode especially for Headers. However, occasionally this
might not be what you want it to do, -- for example, `h4` is not styled at all
-- so an option to substitute them is provided. Each of these options expects a
List of two (2) Strings, which will be output before and after the text of the
Heading.

For example, if we define `fimfic-header-2` like this:

    fimfic-header-2:
      - [size=2em][center]
      - [/center][/size]

and in the document we have this Heading (Markdown format):

    Part Two: Twilight's Diary
    --------------------------

then it will be written in the final document like this:

    [size=2em][center]Part Two: Twilight's Diary[/center][/size]

Remember that each definition expects a list of 2 items, to go before and
after the Header text. It is an error not to have both items, and Pandoc will
complain. If you wish to only use one, have an empty string `""` for the
other. The lists can also but written in between brackets, like in JSON:
`fimfiction-header-5: ["[b]" , "[/b]"]`

#### fimfic-section-break ####

This option allows you to customize the way section breaks are formatted in
the output. By default, this script simply uses the standard `[hr]` tag. To
change this, define this option as any string. This string will be used
instead, eg.

    fimfic-section-break: [center]* * * * *[/center]

Remember that the contents of this string will be interpreted as Markdown, so
you will need to escape some characters with backslash (` \\ `) if you do not
want them to be processed.

#### fimfic-image-caption ####

When images are rendered captioned, you can configure the style the caption is
rendered with, which is `[b][/b]` by default:

    fimfic-image-caption: ["[b]", "[/b]"]

#### fimfic-verse-wrapper ####

Verse blocks are wrapped with the `[pre-line]` tag. However, you may want to additionally wrap them into something else. The default value is:

    fimfic-verse-style: ["[indent=2][i]", "[/i][/indent]"]
    
Notice the use of `[i]` rather than `[em]`.

#### fimfic-inline-code ####

Fimfiction provides both a `[code]` tag and a `[mono]` tag, which get rendered
differently. Markdown permits you to enter inline code, which, by default,
gets rendered as `[code]`. But sometimes it makes sense to use `[mono]` or
something else entirely. You can configure it like this:

    fimfic-inline-code: ["[mono]", "[/mono]"]

### Footnote

Several options are provided to style footnotes, since there is no way to make
in-document links on Fimfiction, and the readers don't like to scroll all the
way to the end and then back. I tried asking for an anchor tag, which was an
idea enthusiastically discussed for a few minutes and then quietly forgotten,
so we have what we have.

Footnote bodies can be inserted into the end of the entire document, (endnotes) before the paragraph their references occur in (sidenotes) or after that paragraph (inline footnotes). The default is inline footnotes.

#### fimfic-endnotes ####

To get endnotes, you you can set this flag:

    fimfic-endnotes: true

#### fimfic-footnote-pre ####

To get sidenotes:

    fimfic-footnote-pre: true

Actually getting sidenotes you're happy with requires further configuration,
see below. Beware: Fimfiction does not have a clearfix between paragraphs,
which means that an overly long footnote block in a figure tag -- which is how
you get sidenotes -- can interfere with footnote blocks for subsequent
paragraphs and the paragraphs themselves.

#### fimfic-footnote-scale ####

Footnotes are traditionally printed in a smaller font size in most media. By
default, this is equal to 0.75em. Should you wish to use a smaller or larger
font size, set this value:

    fimfic-footnote-scale: 1.1em

Scaling footnotes is accomplished by the use of a pseudo-tag, `{{!fnscale!}}`
and `{{!fnscale_end!}}` which you might need to use to construct your own
`fimfic-footnote-block-tag`.

#### fimfic-footnote-block-tag ####

This option allows you to customize the start and end of the footnote blocks. The default, for inline footnotes, is

    fimfic-footnote-block-tag: ["[quote=Footnotes]{{!fnscale!}}", "{{!fnscale_end!}}[/quote]"]

That is, footnote bodies are collected into a quote block and wrapped with a `[size=...]` tag of a given footnote scale.

#### fimfic-footnote-marker-style ####

While it is not possible to make in-page anchor links on Fimfiction, for the
purposes of in-page search superscript text is equivalent to
non-superscript. It is convenient to put footnote markers in brackets, because
then, searching for `(1)` will allow the reader to quickly jump between the
footnote text and the footnote marker. This configuration option allows you to
control this:

    fimfic-footnote-marker-style:
        - "[strong][sup]{{!fnscale!}}("
        - "){{!fnscale_end!}}[/sup][/strong]"
        - "[strong]("
        - ")[/strong]"

The first two are what the footnote reference will be wrapped into, the second two are what the footnote number will be wrapped into when rendered in footnote bodies.

#### fimfic-disable-unicode-trickery ###

If you wish to use the `.letter` and `.blackletter` classes throughout your
writing, but find that you need to turn it off in some cases you can set this
variable to true. `.letter` will just be rendered as a `[quote]` block, while `.blackletter` will become a simple `[b]`.

### Common configurations

For sidenotes, I use this:

    ---
    fimfic-endnotes: false
    fimfic-footnote-pre: true
    fimfic-footnote-marker-style: ["[strong][sup]{{!fnscale!}}", "{{!fnscale_end!}}[/sup][/strong]", "[strong]", ".[/strong]\ "]
    fimfic-footnote-block-tag: ["[figure=right]\n{{!fnscale!}}", "{{!fnscale_end!}}[/figure]"]
    ...

For endnotes, this:

    ---
    fimfic-endnotes: true
    fimfic-footnote-pre: false
    fimfic-footnote-marker-style: ["[strong][sup]{{!fnscale!}}(", "){{!fnscale_end!}}[/sup][/strong]", "[strong](", ")[/strong] "]
    fimfic-footnote-block-tag: ["[quote=Footnotes]{{!fnscale!}}", "{{!fnscale_end!}}[/quote]"]
    ...

# FimFiction BBcode reference

When trying to figure out how to get the typography you want, it helps to know
just what exactly is FimFiction's BBcode parser capable of. Unfortunately,
it's not really well-documented, and many of the tags in this list were
discovered by trial and error. Despite exhaustive search of available lore and
copious experiments, no further undocumented tags were discovered. If you find
anything else, please send them in!

## Quirks

*   All consecutive runs of more than one space produce a chain of one space
    and the same number of `&nbsp;` entities.
*   If a paragraph starts with a tab character, it will be rendered indented
    by CSS.
*   The only known way to prevent the parser from picking up a tag is to break
    it up with another tag that will keep the textual content of the square
    brackets unchanged: `[[b][/b]code]` will render as `[<b></b>code]` -- which
    the reader will see as simply `[code]`. There are no more generic means to
    escape a square bracket.

## Span level tags

While I say "span level," this is not entirely correct, as bold and italic
will carry over to the next paragraph. However, size and color tags, for
example, will not, due to quirks of implementation, and it is generally better
to treat them all as span level.

*   `[b]bold[/b]` -- **bold**  
    `[i]italic[/i]` -- *italic*  
    `[s]strike[/s]` -- ~~strike~~  
    `[u]underline[/u]` -- underline.

*   `[smcaps][/smcaps]`

    Small caps.

*   `[size=<size>][/size]`

    Text size. While older documentation claims that sizes like "large" and
    "xlarge" work, this is no longer so -- currently, sizes are given in almost
    the same manner they are given in CSS. Giving a pure number will work and
    will be interpreted as pt, with the default text size being 18pt. But I
    recommend using em, with `1em` being the regular text size. You can use
    more or less any decimal fraction of em, but sizes of exactly `10em` and
    higher will be rejected.

*   `[color=<color>][/color]`

    Text color. [Standard HTML color names][color_names] work. So do hex RGB
    values in the form of `#RRGGBB`. RGBA does not.

*   `[spoiler][/spoiler]`

    The traditional spoiler tag, which will substitute black background for
    the regular one and swap it back on mouse hover. Will be affected by
    `[color],` with rather unusual results.

*   `[icon]<icon name>[/icon]`

    Will insert a [FontAwesome][font_awesome] icon by name, i.e. without the
    `fa-` prefix, for example, `[icon]check-circle[/icon]`. Currently uses
    FontAwesome v4.0.3, so be sure to check which version an icon was
    introduced in before using it. The icon remains inline with text and obeys
    size and color tags.

*   `[url=<url>]link text[/url]`  
    `[url]<url>[/url]`

    Your basic URL tag. Unlike most other implementations of BBcode,
    FimFiction won't accept a quoted URL in `[url=<url>]`

*   `[site_url=<url>]link text[/site_url]`

    Your less basic URL tag, specifically for in-site links. Will accept URLs
    with no domain and insert either `http://www.fimfiction.net` or
    `https://www.fimfiction.net` in front, depending on which protocol the
    reader is using, i.e.  `[site_url=/blog/616106/guten-tag]post about
    tags[/site_url]` will render as `<a
    href="https://www.fimfiction.net/blog/616106/guten-tag">post about
    tags</a>` -- or as the "http" equivalent if the reader is browsing the http
    site.

*   `[email]user@example.com[/email]`

    Will render a `mailto:` email link. This tag does *not* work in private
    messages for some stupid reason.

[color_names]: http://www.w3schools.com/colors/colors_names.asp
[font_awesome]: http://fontawesome.io/icons/

## Block level tags

"Block level" is, once again, something of a misnomer. For most of these, if
both the opening and closing tag are on the same line, the resulting block
will not contain paragraphs, unless there are line breaks inside.

*   `[hr]`

    Inserts a `<hr>`, which will resist most other styling and won't follow
    palette choices.

*   `[quote][/quote]`

    Will render to a `<blockquote></blockquote>`. This is styled as a frame
    with rounded corners with a different background color. There is *no*
    `[quote=name][/quote]` version.

*   `[center][/center]`

    Will produce a centered block.

*   `[right][/right]`

    Will produce a right-aligned block. There are no tags to left align
    text because it is always left-aligned by default.

*   `[left_insert][/left_insert]`
    `[right_insert][/right_insert]`

    Will produce specially styled blockquote blocks, which will float to the
    left or to the right of the containing block, taking up half the
    width. The background color on these is hardcoded, and if the user is
    reading with a negative palette, the results can be rather crude, so they
    are best confined to blog posts, but they will work elsewhere. Notice that
    inserts can be nested. A right insert and a left insert used in parallel
    will **not** fit together, and one will push the other out.

*   `[page_break]`

    Will produce a 'Read More' button on a blog post when the post is viewed
    in a list of blog posts. Won't work in other contexts, and notably, will
    remain *visible* in other contexts.

*   `[youtube=<youtube ID>]`

    Will embed a YouTube video. Takes the YouTube ID of a video. Will accept
    some forms of YouTube URL, but not others, so I recommend using just the
    ID, because it always works. Will render as a div with an iframe and will
    obey `[center]` and other positioning tags.

*   `[img]<url>[/img]`

    Will insert an image. Notice that Imgur no longer permits to embed images
    on FimFiction, because they're crazy. Additionally, the sanitizer thinks
    that URLs can only begin with "http" or "https" and data URIs don't work --
    which is a shame, because that would be the perfect way to insert a
    decorative section break.

*   `[code][/code]`

    This is *not* actually a code tag: BBcode inside will still get rendered,
    and quirks related to paragraphs will still apply. However, this renders
    as `<pre class="code"></pre>`, with a fixed width font, and suppresses
    line wrapping.

## Other observations and trickery

* Unicode character U+00A0 works as a non-breaking space, even when you can't
  insert a real `&nbsp;` entity. So does U+2007 (figure space.) There is,
  unfortunately, no way to insert an equivalent of a `<br/>`.

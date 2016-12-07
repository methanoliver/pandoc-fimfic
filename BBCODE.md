# FimFiction bbcode reference

When trying to figure out how to get the typography you want, it helps to know
just what exactly is FimFiction's bbcode parser capable of. Unfortunately, it's
not really well-documented, and many of the tags in this list were discovered
by trial and error.

## Quirks

*   All consecutive runs of more than one space produce a chain of one space 
    and the same number of `&nbsp;` entities.
*   If a paragraph starts with a tab character, it will be rendered
    indented by css.
*   The only known way to prevent the parser from picking up a tag is to break
    it up with another, empty tag: `[[b][/b]code]` will render as 
    `[<b></b>code]` and allow to refer to tags in text.  

## Span level tags

While I say "span level" this is not entirely correct, as bold and italic will
carry over to the next paragraph. However, size and color tags, for example,
will not, due to quirks of implementation, and it is generally better to treat
them all as span level.

*   `[b]bold[/b]`  
    `[i]italic[/i]`  
    `[s]strike[/s]`  
    `[u]underline[/u]`

    **bold**  
    *italic*  
    ~~strike~~  
    and underline
    respectively.
    
*   `[smcaps][/smcaps]`
 
    Small caps.
    
*   `[size=<size>][/size]`

    Text size. While older documentation claims that sizes like "large" and
    "xlarge" work, this is no longer so -- currently, sizes are given in almost
    the same manner they are given in css. Giving a pure number will work and
    will be interpreted as pt, with the default text size being 18pt. But I
    recommend using em, with 1em being the regular text size. You can use
    more or less any decimal fraction of em, but sizes of exactly `10em`
    and higher will be rejected.
    
*   `[color=<color>][/color]`

    Text color.
    [Standard HTML color names](http://www.w3schools.com/colors/colors_names.asp)
    work. So do hex RGB values in the form of `#RRGGBB`. RGBA does not.
    
*   `[spoiler][/spoiler]`

    The traditional spoiler tag, which will substitute black background for
    the regular one and swap it back on mouse hover. Will be affected by
    `[color],` with rather unusual results.

*   `[icon]<icon name>[/icon]`

    Will insert a [FontAwesome](https://fortawesome.github.io/Font-Awesome/)
    icon by name, i.e. without the `fa-` prefix, for example,
    `[icon]check-circle[/icon]`. Currently uses FontAwesome v4.0.3.
    The icon remains inline with text and obeys size and color tags.
    
*   `[url=<url>]link text[/url]`  
    `[url]<url>[/url]`
    
    Your basic URL tag.

*   `[site_url=<url>]link text[/site_url]`
    
    Your less basic URL tag. Will accept URLs with no domain and substitute
    either `http://www.fimfiction.net` or `https://www.fimfiction.net` depending
    on which protocol the reader is using, i.e.
    `[site_url=/blog/616106/guten-tag]post about tags[/site_url]`.
    
*   `[email]user@example.com[/email]`

    Will render a `mailto:` email link. This does not work in private 
    messages for some stupid reason.

## Block level tags

"Block level" is, once again, something of a misnomer. For most of these,
if both the opening and closing tag are on the same line, the resulting
block will not contain paragraphs, but it will if there are line breaks
inside.

*   `[hr]`

    Inserts a `<hr>`, which will resist most other styling and won't follow
    palette choices.

*   `[quote][/quote]`

    Will render to a `<blockquote></blockquote>`. This is styled as a frame
    with rounded corners with a different background color.
    
*   `[center][/center]`

    Will produce a centered block.
    
*   `[right][/right]`

    Will produce a right-aligned block. There are no tags to left align
    text because it is always left-aligned by default.
    
*   `[left_insert][/left_insert]`  
    `[right_insert][/right_insert]` 

    Will produce specially styled blockquote blocks, which will float to the
    left or to the right of the page, taking up half the width. The background
    color on these is hardcoded, and if the user is reading with a negative
    palette, the results can be rather crude, so they are best confined to
    blog posts, but they will work elsewhere.
    
*   `[page_break]`

    Will produce a 'Read More' button on a blog post when the post is viewed
    in a list. Won't work in other contexts.
    
*   `[youtube=<youtube ID>]`

    Will embed a youtube video. Takes a youtube ID of a video, and not an URL.
    Will render as a div with an iframe and will obey `[center]` and
    other positioning tags.

*   `[img]<url>[/img]`

    Will insert an image. Notice that Imgur no longer permits to embed images
    on FimFiction, because they're crazy.
    
*   `[code][/code]`

    Is not actually a code tag: Bbcode inside will still get rendered, and
    quirks related to paragraphs will still apply. However, this renders
    as `<pre class="code"></pre>`, with fixed width font, and suppresses
    line wrapping.

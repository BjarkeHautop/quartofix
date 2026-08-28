# Restore Quarto callout markup in a pkgdown-rendered HTML file

pkgdown renders `.qmd` articles with `theme: "none"` and `minimal: TRUE`
(see `pkgdown:::quarto_format()`), which strips the CSS Quarto callouts
rely on. Under those settings, Quarto's callout Lua filter falls back to
a plain, class-less blockquote:

## Usage

``` r
fix_quarto_callouts(html_path, qmd_path = NULL)
```

## Arguments

- html_path:

  Path to an HTML file to rewrite in place.

- qmd_path:

  Optional path to the `.qmd` source that produced `html_path`, used to
  recover callout types lost to custom titles.

## Value

The number of callouts rewritten, invisibly.

## Details

    <div>
    <blockquote>
    <p><strong>Note</strong></p>
    <p>Hello note</p>
    </blockquote>
    </div>

This function finds that pattern - an attribute-less `<div>` whose only
child is a `<blockquote>` whose first child is a `<p>` containing
nothing but a `<strong>` - and rewrites it into Quarto's native callout
markup (`div.callout.callout-style-default.callout-<type>`), so it can
be styled by the CSS bundled with this package (see
[`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md)).

A hand-written blockquote is never wrapped in a bare `<div>` by Pandoc,
so this signature does not collide with genuine author content.

If a callout used a custom title (`## My Title` instead of the default),
pkgdown's render loses the callout type along with the title text, so
the type can't be read back from the HTML alone. Pass `qmd_path` (the
original `.qmd` source, which pkgdown always ships alongside the built
HTML) and this function recovers the type by reading the
`::: {.callout-*}` fences in document order and matching them
positionally against the degraded callouts - this works regardless of
custom titles. It's used only as a fallback when the count of callouts
in the source doesn't match the count found in the HTML (which would
mean a mismatch is possible), the title text is used to guess the type
instead.

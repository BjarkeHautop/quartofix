# Patch a pkgdown site by splicing genuine Quarto HTML

An alternative to
[`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md).
Instead of reconstructing callout and tabset markup from what pkgdown
left behind, this re-renders each article's `.qmd` source with
[`quarto::quarto_render()`](https://quarto-dev.github.io/quarto-r/reference/quarto_render.html)
and splices the genuine rendered nodes into pkgdown's HTML in place of
the degraded ones. This is more faithful to Quarto's actual output (no
callout-type guessing needed) but costs a second, full Quarto render per
article, which can be slow for expensive vignettes. Kept separate from
[`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md)
while that tradeoff is evaluated.

## Usage

``` r
quartofix2(dst_path = "docs", pkg_path = ".", pattern = "[.]html$")
```

## Arguments

- dst_path:

  Path to the built pkgdown site (`docs/` by default).

- pkg_path:

  Path to the package root, used to locate the `.qmd` source of each
  article (searched under `vignettes/`) so that
  [`fix_quarto_callouts()`](https://bjarkehautop.github.io/quartofix/reference/fix_quarto_callouts.md)
  can recover callout types lost to custom titles. Set to `NULL` to skip
  source lookup entirely.

- pattern:

  Regex selecting which HTML files to inspect. Defaults to every `.html`
  file, which is harmless but slower on large sites; narrow it (e.g.
  `"^articles/"`) if you know where your Quarto articles land.

## Value

Invisibly, the paths of the HTML files that were modified.

## Details

Only articles with a discoverable `.qmd` source (see `pkg_path`) are
spliced; articles without one are left untouched. Code annotations are
not yet spliced by this function - they're handled the same way as
[`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md)
(asset injection only).

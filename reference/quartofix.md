# Patch a pkgdown site's Quarto vignettes by restoring

Walks the HTML files pkgdown generated from `.qmd` articles, restores
callout markup with
[`fix_quarto_callouts()`](https://bjarkehautop.github.io/quartofix/reference/fix_quarto_callouts.md),
undoes pkgdown's corruption of Quarto tabsets with
[`fix_quarto_tabsets()`](https://bjarkehautop.github.io/quartofix/reference/fix_quarto_tabsets.md),
detects code annotations with
[`fix_quarto_annotations()`](https://bjarkehautop.github.io/quartofix/reference/fix_quarto_annotations.md),
and - for any file that contains a tabset or code annotation - links in
the small `quartofix.css`/`quartofix.js` assets that restore their
styling and interactivity (copied once into `<dst_path>/quartofix/`).

## Usage

``` r
quartofix(dst_path = "docs", pkg_path = ".", pattern = "[.]html$")
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

Run this *after*
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
(or `build_articles()`), since it operates on the rendered HTML, not the
`.qmd` source.

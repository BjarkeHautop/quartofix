# quartofix

<!-- badges: start -->
[![R-CMD-check](https://github.com/bjarkehautop/quartofix/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/bjarkehautop/quartofix/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

pkgdown renders Quarto (`.qmd`) files with `theme: "none"` and
`minimal: TRUE` so it can supply its own CSS instead of Quarto's. Thus, currently the following is broken when using `.qmd` files:

- [Callouts blocks](https://quarto.org/docs/authoring/callouts.html) degrade to a plain, untyped blockquote.
- Tabsets get actively mangled.
- Code annotations keep their HTML/classes but lose the JS that makes them interactive.

quartofix fixes these. Two approaches are implemented:

- `quartofix()`:
Rewrites the broken things into Quarto's native
callout markup, and links in a small vendored CSS/JS bundle so tabsets and code annotations work without pulling in Quarto's full asset bundle.

- `quartofix2()`:
Runs `quarto render` on the `.qmd` files with any callout blocks or tabsets. Code annotations are handled the same way as in `quartofix()`, since
their markup already survives pkgdown's render intact, only the vendored JS/CSS bundle needs to be linked in. Then patches
it together with the generated `.html` from pkgdown.
  - TODO:
    - Could move callouts and tabsets (that don't run the code (since it might need previous code)) into a seperate temp `.qmd` file. The cost of rendering this would be essentially 0, so potentially a decent speedup.

## Usage

Simply just call it after you build your site with pkgdown:

```r
pkgdown::build_site()
quartofix::quartofix() # or quartofix2()
```

See the same demo article as
[raw pkgdown output](https://bjarkehautop.github.io/quartofix/articles/demo-none.html),
[patched with `quartofix()`](https://bjarkehautop.github.io/quartofix/articles/demo-quartofix.html),
and [patched with `quartofix2()`](https://bjarkehautop.github.io/quartofix/articles/demo-quartofix2.html).

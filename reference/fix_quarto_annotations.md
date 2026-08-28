# Detect Quarto code annotations in a pkgdown-rendered HTML file

Unlike callouts and tabsets, Quarto's code-annotation markup (the
`code-annotation-anchor` links and their
`dl.code-annotation-container-grid` targets) survives pkgdown's
`minimal: TRUE` render intact - it's only the interactivity
(click-to-highlight, hover) that's lost, because that theme strips the
Bootstrap/Quarto JS the annotations depend on. So there's no markup to
repair here, unlike
[`fix_quarto_callouts()`](https://bjarkehautop.github.io/quartofix/reference/fix_quarto_callouts.md)
and
[`fix_quarto_tabsets()`](https://bjarkehautop.github.io/quartofix/reference/fix_quarto_tabsets.md);
this function just counts the annotations present, which
[`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md)
uses to decide whether to link in the JS/CSS that restores their
behavior.

## Usage

``` r
fix_quarto_annotations(html_path)
```

## Arguments

- html_path:

  Path to an HTML file to inspect.

## Value

The number of code annotations found, invisibly.

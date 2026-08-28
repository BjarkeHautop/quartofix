# Package index

## Build site

Patch a pkgdown site’s HTML output.

- [`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md)
  : Patch a pkgdown site's Quarto vignettes by restoring
- [`quartofix2()`](https://bjarkehautop.github.io/quartofix/reference/quartofix2.md)
  : Patch a pkgdown site by splicing genuine Quarto HTML

## Individual fixers

Helpers that fix a single kind of Quarto markup, used internally by
quartofix() and quartofix2() but also usable on their own.

- [`fix_quarto_annotations()`](https://bjarkehautop.github.io/quartofix/reference/fix_quarto_annotations.md)
  : Detect Quarto code annotations in a pkgdown-rendered HTML file
- [`fix_quarto_callouts()`](https://bjarkehautop.github.io/quartofix/reference/fix_quarto_callouts.md)
  : Restore Quarto callout markup in a pkgdown-rendered HTML file
- [`fix_quarto_tabsets()`](https://bjarkehautop.github.io/quartofix/reference/fix_quarto_tabsets.md)
  : Undo pkgdown's corruption of Quarto tabsets

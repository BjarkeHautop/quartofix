# Undo pkgdown's corruption of Quarto tabsets

pkgdown's own `tweak_tabsets()` (written for R Markdown's
`## Heading {.tabset}` syntax) runs on every `<div>` whose class merely
*contains* the substring "tabset" - which also matches Quarto's
`.panel-tabset` divs, even though their markup shape is completely
different. Quarto's minimal-mode render produces:

## Usage

``` r
fix_quarto_tabsets(html_path)
```

## Arguments

- html_path:

  Path to an HTML file to rewrite in place.

## Value

The number of tabsets repaired, invisibly.

## Details

    <div class="panel-tabset">
      <ul class="panel-tabset-tabby">...</ul>
      <div class="tab-content">
        <div id="tabset-1-1">...</div>
        <div id="tabset-1-2">...</div>
      </div>
    </div>

`tweak_tabset()` looks for *direct `<div>` children* of `.panel-tabset`
to use as "tabs" - it finds exactly one (the `.tab-content` wrapper),
and mistakes it for a single R Markdown tab: the first tab's content is
unwrapped into the new nav `<button>` (as its "title"), and the
remaining tabs are left, still correctly `id`-ed, nested inside one
bogus `id="NA"` pane. The original `<ul class="panel-tabset-tabby">` is
never touched, so it survives as ground truth for tab order and titles.

This function reverses that: it uses the untouched `panel-tabset-tabby`
list to learn how many tabs there should be, pulls tab 1's content back
out of the corrupted nav button, reclaims tabs 2..N from inside the
bogus pane (they're already intact), and rebuilds a clean `.tab-content`
div - the shape
[`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md)'s
CSS/JS expect.

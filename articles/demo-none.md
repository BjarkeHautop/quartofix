# Demo: raw pkgdown output

This article shows what
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
produces on its own, straight from Quarto’s `.qmd` markup, with no
[`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md)/[`quartofix2()`](https://bjarkehautop.github.io/quartofix/reference/quartofix2.md)
cleanup run afterward. Callouts degrade to plain blockquotes, tabsets
get mangled, and code annotations lose the JS that makes them
interactive. Compare with the same article [patched with
`quartofix()`](https://bjarkehautop.github.io/quartofix/articles/quartofix.md)
or [patched with
`quartofix2()`](https://bjarkehautop.github.io/quartofix/articles/quartofix2.md)
instead.

## Callouts

> **Note**
>
> Callouts like this one keep their default title (“Note”) and are
> recovered exactly - type, icon, and color included.

> **This one has a custom title**
>
> pkgdown’s render loses the callout *type* along with a custom title
> like this one -
> [`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md)
> recovers it anyway by reading the `.qmd` source that produced this
> page and matching callouts positionally.

> **Warning**
>
> [`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md)
> only rewrites the *first* paragraph’s default title. A callout title
> spanning multiple lines is not currently supported.

> **Caution**
>
> Running
> [`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md)
> more than once is safe - already-patched files are detected and
> skipped.

> **Important**
>
> [`quartofix()`](https://bjarkehautop.github.io/quartofix/reference/quartofix.md)
> must run after
> [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html),
> not before - it patches the *rendered* HTML, not the `.qmd` source.

## Tabsets

That doesn’t run the code:

- [R](#tabset-1-1)
- [Shell](#tabset-1-2)

&nbsp;

- ``` r

  pkgdown::build_site()
  quartofix::quartofix()
  ```

``` sh
Rscript -e 'pkgdown::build_site(); quartofix::quartofix()'
```

That runs the (R) code:

- [R](#tabset-2-1)
- [Shell](#tabset-2-2)

&nbsp;

- ``` r

  1+1
  ```

      [1] 2

``` sh
Rscript -e 'pkgdown::build_site(); quartofix::quartofix()'
```

## Code annotations

``` r
1pkgdown::build_site()
2quartofix::quartofix()
```

- 1:

  Builds the site as usual - Quarto articles render with callouts,
  tabsets, and annotations all degraded.

- 2:

  Walks `docs/`, restores callout markup, and links in the small
  `quartofix.css`/`quartofix.js` bundle wherever it’s needed.

## A normal blockquote

Here is an ordinary blockquote, to show it’s still intact:

> Premature optimization is the root of all evil.
>
> — Donald Knuth

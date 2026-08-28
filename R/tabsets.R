#' Undo pkgdown's corruption of Quarto tabsets
#'
#' pkgdown's own `tweak_tabsets()` (written for R Markdown's
#' `## Heading {.tabset}` syntax) runs on every `<div>` whose class merely
#' *contains* the substring "tabset" - which also matches Quarto's
#' `.panel-tabset` divs, even though their markup shape is completely
#' different. Quarto's minimal-mode render produces:
#'
#' ```html
#' <div class="panel-tabset">
#'   <ul class="panel-tabset-tabby">...</ul>
#'   <div class="tab-content">
#'     <div id="tabset-1-1">...</div>
#'     <div id="tabset-1-2">...</div>
#'   </div>
#' </div>
#' ```
#'
#' `tweak_tabset()` looks for *direct `<div>` children* of `.panel-tabset` to
#' use as "tabs" - it finds exactly one (the `.tab-content` wrapper), and
#' mistakes it for a single R Markdown tab: the first tab's content is
#' unwrapped into the new nav `<button>` (as its "title"), and the remaining
#' tabs are left, still correctly `id`-ed, nested inside one bogus
#' `id="NA"` pane. The original `<ul class="panel-tabset-tabby">` is never
#' touched, so it survives as ground truth for tab order and titles.
#'
#' This function reverses that: it uses the untouched `panel-tabset-tabby`
#' list to learn how many tabs there should be, pulls tab 1's content back
#' out of the corrupted nav button, reclaims tabs 2..N from inside the
#' bogus pane (they're already intact), and rebuilds a clean
#' `.tab-content` div - the shape [quartofix()]'s CSS/JS expect.
#'
#' @param html_path Path to an HTML file to rewrite in place.
#' @return The number of tabsets repaired, invisibly.
#' @export
fix_quarto_tabsets <- function(html_path) {
  doc <- xml2::read_html(html_path, encoding = "UTF-8")

  panels <- xml2::xml_find_all(
    doc,
    "//div[contains(concat(' ', normalize-space(@class), ' '), ' panel-tabset ')]"
  )
  n_fixed <- 0L

  for (panel in panels) {
    tabby_ul <- xml2::xml_find_first(
      panel,
      "./ul[contains(concat(' ', normalize-space(@class), ' '), ' panel-tabset-tabby ')]"
    )
    nav_broken <- xml2::xml_find_first(
      panel,
      "./ul[contains(concat(' ', normalize-space(@class), ' '), ' nav-tabs ')]"
    )
    content_broken <- xml2::xml_find_first(panel, "./div[contains(@class, 'tab-content')]")

    if (is.na(xml2::xml_name(tabby_ul)) || is.na(xml2::xml_name(nav_broken)) ||
      is.na(xml2::xml_name(content_broken))) {
      next
    }

    links <- xml2::xml_find_all(tabby_ul, "./li/a")
    ids <- sub("^#", "", xml2::xml_attr(links, "href"))
    if (length(ids) == 0) {
      next
    }

    button <- xml2::xml_find_first(nav_broken, ".//button")
    fake_pane <- xml2::xml_find_first(content_broken, "./div")
    if (is.na(xml2::xml_name(button)) || is.na(xml2::xml_name(fake_pane))) {
      next
    }

    new_content <- xml2::xml_new_root("div")
    xml2::xml_set_attr(new_content, "class", "tab-content")

    first_pane <- xml2::xml_add_child(new_content, "div", id = ids[[1]])
    for (child in xml2::xml_contents(button)) {
      xml2::xml_add_child(first_pane, child)
    }

    remaining <- xml2::xml_children(fake_pane)
    for (child in remaining) {
      xml2::xml_add_child(new_content, child)
    }

    xml2::xml_remove(nav_broken)
    xml2::xml_remove(content_broken)
    xml2::xml_add_child(panel, new_content)

    n_fixed <- n_fixed + 1L
  }

  if (n_fixed > 0) {
    xml2::write_html(doc, html_path, options = "format")
  }
  invisible(n_fixed)
}

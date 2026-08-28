#' Detect Quarto code annotations in a pkgdown-rendered HTML file
#'
#' Unlike callouts and tabsets, Quarto's code-annotation markup (the
#' `code-annotation-anchor` links and their `dl.code-annotation-container-grid`
#' targets) survives pkgdown's `minimal: TRUE` render intact - it's only the
#' interactivity (click-to-highlight, hover) that's lost, because that theme
#' strips the Bootstrap/Quarto JS the annotations depend on. So there's no
#' markup to repair here, unlike [fix_quarto_callouts()] and
#' [fix_quarto_tabsets()]; this function just counts the annotations present,
#' which [quartofix()] uses to decide whether to link in the JS/CSS that
#' restores their behavior.
#'
#' @param html_path Path to an HTML file to inspect.
#' @return The number of code annotations found, invisibly.
#' @export
fix_quarto_annotations <- function(html_path) {
  doc <- xml2::read_html(html_path, encoding = "UTF-8")
  n_found <- length(xml2::xml_find_all(
    doc,
    "//*[contains(concat(' ', normalize-space(@class), ' '), ' code-annotation-anchor ')]"
  ))
  invisible(n_found)
}

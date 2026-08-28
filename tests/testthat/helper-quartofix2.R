#' @noRd
extract_callouts <- function(html_path) {
  doc <- xml2::read_html(html_path, encoding = "UTF-8")
  nodes <- xml2::xml_find_all(
    doc,
    "//div[contains(concat(' ', normalize-space(@class), ' '), ' callout ')]"
  )
  lapply(nodes, function(n) {
    class <- xml2::xml_attr(n, "class")
    type <- sub(".*callout-(note|tip|warning|caution|important).*", "\\1", class)
    # Exclude Quarto's `.screen-reader-only` a11y label so a genuine render
    # (which adds one) and quartofix()'s hand-built markup (which doesn't)
    # can still be compared on visible title text.
    title_texts <- xml2::xml_find_all(
      n,
      ".//div[contains(@class,'callout-title-container')]//text()[not(ancestor::*[contains(@class,'screen-reader-only')])]"
    )
    title <- trimws(gsub("\\s+", " ", paste(xml2::xml_text(title_texts), collapse = "")))
    body <- trimws(gsub(
      "\\s+", " ",
      xml2::xml_text(xml2::xml_find_first(n, ".//div[contains(@class,'callout-body')]"))
    ))
    list(type = type, title = title, body = body)
  })
}

#' @noRd
extract_tabsets <- function(html_path) {
  doc <- xml2::read_html(html_path, encoding = "UTF-8")
  panels <- xml2::xml_find_all(
    doc,
    "//div[contains(concat(' ', normalize-space(@class), ' '), ' panel-tabset ')]"
  )
  lapply(panels, function(panel) {
    # Tab labels: quartofix() leaves the original `.panel-tabset-tabby` <a>
    # nav in place, quartofix2() splices in Quarto's native `nav-tabs`
    # <button> nav instead - accept either so label text is comparable.
    labels <- xml2::xml_find_all(panel, ".//li//a | .//li//button")
    panes <- xml2::xml_find_all(
      panel,
      ".//div[contains(concat(' ', normalize-space(@class), ' '), ' tab-content ')]/div"
    )
    list(
      labels = trimws(xml2::xml_text(labels)),
      panes = lapply(panes, function(p) {
        list(
          id = xml2::xml_attr(p, "id"),
          text = trimws(gsub("\\s+", " ", xml2::xml_text(p)))
        )
      })
    )
  })
}

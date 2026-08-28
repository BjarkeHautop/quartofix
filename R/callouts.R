#' Restore Quarto callout markup in a pkgdown-rendered HTML file
#'
#' pkgdown renders `.qmd` articles with `theme: "none"` and `minimal: TRUE`
#' (see `pkgdown:::quarto_format()`), which strips the CSS Quarto callouts
#' rely on. Under those settings, Quarto's callout Lua filter falls back to a
#' plain, class-less blockquote:
#'
#' ```html
#' <div>
#' <blockquote>
#' <p><strong>Note</strong></p>
#' <p>Hello note</p>
#' </blockquote>
#' </div>
#' ```
#'
#' This function finds that pattern - an attribute-less `<div>` whose only
#' child is a `<blockquote>` whose first child is a `<p>` containing nothing
#' but a `<strong>` - and rewrites it into Quarto's native callout markup
#' (`div.callout.callout-style-default.callout-<type>`), so it can be styled
#' by the CSS bundled with this package (see [quartofix()]).
#'
#' A hand-written blockquote is never wrapped in a bare `<div>` by Pandoc, so
#' this signature does not collide with genuine author content.
#'
#' If a callout used a custom title (`## My Title` instead of the default),
#' pkgdown's render loses the callout type along with the title text, so the
#' type can't be read back from the HTML alone. Pass `qmd_path` (the
#' original `.qmd` source, which pkgdown always ships alongside the built
#' HTML) and this function recovers the type by reading the `::: {.callout-*}`
#' fences in document order and matching them positionally against the
#' degraded callouts - this works regardless of custom titles. It's used only
#' as a fallback when the count of callouts in the source doesn't match the
#' count found in the HTML (which would mean a mismatch is possible), the
#' title text is used to guess the type instead.
#'
#' @param html_path Path to an HTML file to rewrite in place.
#' @param qmd_path Optional path to the `.qmd` source that produced
#'   `html_path`, used to recover callout types lost to custom titles.
#' @return The number of callouts rewritten, invisibly.
#' @export
fix_quarto_callouts <- function(html_path, qmd_path = NULL) {
  doc <- xml2::read_html(html_path, encoding = "UTF-8")

  divs <- xml2::xml_find_all(doc, "//div[not(@*)]")
  candidates <- list()
  for (div in divs) {
    children <- xml2::xml_children(div)
    if (length(children) != 1 || xml2::xml_name(children) != "blockquote") {
      next
    }
    bq_children <- xml2::xml_children(children)
    if (length(bq_children) < 1 || xml2::xml_name(bq_children[[1]]) != "p") {
      next
    }
    first_p <- bq_children[[1]]
    if (length(xml2::xml_children(first_p)) != 1) {
      next
    }
    strong <- xml2::xml_find_first(first_p, "./strong")
    if (is.na(xml2::xml_name(strong))) {
      next
    }
    candidates[[length(candidates) + 1L]] <- list(
      div = div, strong = strong, bq_children = bq_children
    )
  }

  source_types <- if (!is.null(qmd_path) && file.exists(qmd_path)) {
    callout_types_from_qmd(qmd_path)
  } else {
    character()
  }
  use_source_types <- length(source_types) == length(candidates) && length(candidates) > 0

  for (i in seq_along(candidates)) {
    cand <- candidates[[i]]
    known_type <- if (use_source_types) source_types[[i]] else NA_character_
    xml2::xml_replace(
      cand$div,
      callout_node(cand$strong, cand$bq_children, known_type)
    )
  }

  n_fixed <- length(candidates)
  if (n_fixed > 0) {
    xml2::write_html(doc, html_path, options = "format")
  }
  invisible(n_fixed)
}

callout_types <- c("note", "tip", "warning", "caution", "important")

#' @noRd
callout_types_from_qmd <- function(qmd_path) {
  lines <- paste(readLines(qmd_path, warn = FALSE), collapse = "\n")
  matches <- gregexpr(
    ":::+\\s*\\{[^}]*\\.callout-(note|tip|warning|caution|important)[^}]*\\}",
    lines,
    perl = TRUE
  )[[1]]
  if (matches[[1]] == -1) {
    return(character())
  }
  full <- regmatches(lines, gregexpr(
    ":::+\\s*\\{[^}]*\\.callout-(note|tip|warning|caution|important)[^}]*\\}",
    lines,
    perl = TRUE
  ))[[1]]
  sub(".*\\.callout-(note|tip|warning|caution|important).*", "\\1", full)
}

callout_node <- function(strong, bq_children, known_type = NA_character_) {
  title <- trimws(xml2::xml_text(strong))
  type <- if (!is.na(known_type) && known_type %in% callout_types) {
    known_type
  } else {
    guess <- tolower(title)
    if (guess %in% callout_types) guess else "note"
  }

  body_nodes <- bq_children[-1]
  body_html <- paste(
    vapply(body_nodes, as.character, character(1)),
    collapse = "\n"
  )

  callout_html <- sprintf(
    '<div class="callout callout-style-default callout-%s callout-titled">
<div class="callout-header d-flex align-content-center">
<div class="callout-icon-container"><i class="callout-icon"></i></div>
<div class="callout-title-container flex-fill">%s</div>
</div>
<div class="callout-body-container callout-body">
%s
</div>
</div>',
    type, title, body_html
  )

  frag <- xml2::read_html(paste0("<html><body>", callout_html, "</body></html>"))
  xml2::xml_find_first(frag, "//body/div")
}

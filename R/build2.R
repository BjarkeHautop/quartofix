#' Patch a pkgdown site by splicing genuine Quarto HTML
#'
#' An alternative to [quartofix()]. Instead of reconstructing callout and
#' tabset markup from what pkgdown left behind, this re-renders each
#' article's `.qmd` source with `quarto::quarto_render()` and splices the
#' genuine rendered nodes into pkgdown's HTML in place of the degraded ones.
#' This is more faithful to Quarto's actual output (no callout-type
#' guessing needed) but costs a second, full Quarto render per article,
#' which can be slow for expensive vignettes. Kept separate from
#' [quartofix()] while that tradeoff is evaluated.
#'
#' Only articles with a discoverable `.qmd` source (see `pkg_path`) are
#' spliced; articles without one are left untouched. Code annotations are
#' not yet spliced by this function - they're handled the same way as
#' [quartofix()] (asset injection only).
#'
#' @inheritParams quartofix
#' @return Invisibly, the paths of the HTML files that were modified.
#' @export
quartofix2 <- function(
  dst_path = "docs",
  pkg_path = ".",
  pattern = "[.]html$"
) {
  if (!requireNamespace("quarto", quietly = TRUE)) {
    cli::cli_abort("quartofix2() requires the {.pkg quarto} package.")
  }

  html_files <- fs::dir_ls(
    dst_path,
    recurse = TRUE,
    regexp = pattern,
    type = "file"
  )
  changed <- character()

  for (f in html_files) {
    raw <- paste(readLines(f, warn = FALSE), collapse = "\n")
    has_callout_candidate <- grepl("<blockquote>", raw, fixed = TRUE)
    has_tabset <- grepl("panel-tabset-tabby", raw, fixed = TRUE)
    has_annotation <- grepl("code-annotation-anchor", raw, fixed = TRUE)

    if (!has_callout_candidate && !has_tabset && !has_annotation) {
      next
    }

    # has_callout_candidate/has_tabset/has_annotation are coarse substring
    # pre-filters, so re-check structurally before deciding whether a
    # missing .qmd source is worth warning about - a reference page whose
    # docs merely *mention* "panel-tabset-tabby" or "code-annotation-anchor"
    # as text (e.g. the man pages for fix_quarto_tabsets()/
    # fix_quarto_annotations() themselves) would otherwise trigger a false
    # "no source found" warning despite having nothing to splice.
    doc <- xml2::read_html(f, encoding = "UTF-8")
    n_callout_candidates <- length(find_callout_targets(doc))
    n_tabset_candidates <- if (has_tabset) count_panel_tabsets(f) else 0L
    n_annotation_candidates <- if (has_annotation) {
      fix_quarto_annotations(f)
    } else {
      0L
    }

    if (
      n_callout_candidates == 0 &&
        n_tabset_candidates == 0 &&
        n_annotation_candidates == 0
    ) {
      next
    }

    qmd_path <- find_qmd_source(pkg_path, f)
    if (is.null(qmd_path)) {
      cli::cli_warn(c(
        "!" = "No .qmd source found for {.file {f}} - skipping.",
        "i" = "quartofix2() needs the source to re-render with Quarto."
      ))
      next
    }

    rendered_path <- render_qmd_to_html(qmd_path)
    if (is.null(rendered_path)) {
      next
    }

    n_callouts <- splice_callouts(f, rendered_path)
    n_tabsets <- if (n_tabset_candidates > 0) {
      splice_tabsets(f, rendered_path)
    } else {
      0L
    }
    n_annotations <- n_annotation_candidates

    if (n_callouts > 0 || n_tabsets > 0 || n_annotations > 0) {
      inject_assets(
        f,
        dst_path,
        already_has_assets = grepl("quartofix/quartofix.css", raw, fixed = TRUE)
      )
      changed <- c(changed, f)
    }
  }

  if (length(changed) > 0) {
    ensure_assets(dst_path)
    cli::cli_inform(c("v" = "quartofix2 patched {length(changed)} file{?s}."))
  } else {
    cli::cli_inform(
      "No Quarto callouts, tabsets, or annotations found - nothing to patch."
    )
  }

  invisible(changed)
}

#' @noRd
render_qmd_to_html <- function(qmd_path) {
  work_dir <- fs::file_temp("quartofix2-")
  fs::dir_copy(fs::path_dir(qmd_path), work_dir)
  qmd_copy <- fs::path(work_dir, fs::path_file(qmd_path))

  tryCatch(
    {
      quarto::quarto_render(
        input = qmd_copy,
        output_format = "html",
        quiet = TRUE,
        as_job = FALSE
      )
      produced <- fs::path_ext_set(qmd_copy, "html")
      if (!fs::file_exists(produced)) NULL else produced
    },
    error = function(e) {
      cli::cli_warn(
        "Quarto render failed for {.file {qmd_path}}: {conditionMessage(e)}"
      )
      NULL
    }
  )
}

#' @noRd
find_callout_targets <- function(doc) {
  divs <- xml2::xml_find_all(doc, "//div[not(@*)]")
  targets <- list()
  for (div in divs) {
    children <- xml2::xml_children(div)
    if (length(children) != 1 || xml2::xml_name(children) != "blockquote") {
      next
    }
    bq_children <- xml2::xml_children(children[[1]])
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
    targets[[length(targets) + 1L]] <- div
  }
  targets
}

#' @noRd
splice_callouts <- function(html_path, rendered_path) {
  doc <- xml2::read_html(html_path, encoding = "UTF-8")
  rendered <- xml2::read_html(rendered_path, encoding = "UTF-8")

  targets <- find_callout_targets(doc)
  sources <- xml2::xml_find_all(
    rendered,
    "//div[contains(concat(' ', normalize-space(@class), ' '), ' callout ')]"
  )

  if (length(targets) == 0 || length(targets) != length(sources)) {
    return(0L)
  }

  for (i in seq_along(targets)) {
    xml2::xml_replace(targets[[i]], clone_node(sources[[i]]))
  }

  xml2::write_html(doc, html_path, options = "format")
  length(targets)
}

#' @noRd
splice_tabsets <- function(html_path, rendered_path) {
  doc <- xml2::read_html(html_path, encoding = "UTF-8")
  rendered <- xml2::read_html(rendered_path, encoding = "UTF-8")

  xpath <- "//div[contains(concat(' ', normalize-space(@class), ' '), ' panel-tabset ')]"
  targets <- xml2::xml_find_all(doc, xpath)
  sources <- xml2::xml_find_all(rendered, xpath)

  if (length(targets) == 0 || length(targets) != length(sources)) {
    return(0L)
  }

  for (i in seq_along(targets)) {
    xml2::xml_replace(targets[[i]], clone_node(sources[[i]]))
  }

  xml2::write_html(doc, html_path, options = "format")
  length(targets)
}

#' @noRd
parse_node_copy <- function(node) {
  frag <- xml2::read_html(paste0(
    "<html><body>",
    as.character(node),
    "</body></html>"
  ))
  xml2::xml_find_first(frag, "//body/*[1]")
}

#' @noRd
clone_node <- function(node) {
  copy <- parse_node_copy(node)
  strip_copy_button_scaffold(copy)
  copy
}

#' @noRd
strip_copy_button_scaffold <- function(root) {
  # Quarto wraps each code cell's copy-to-clipboard button in a
  # `.code-copy-outer-scaffold` div. That button needs Quarto's own CSS
  # (absolute positioning) and the Bootstrap Icons font, neither of which
  # pkgdown ships, so it renders as a collapsed, malformed box. pkgdown
  # already adds its own working copy button to every `div.sourceCode` via
  # its bundled clipboard.js, so drop Quarto's redundant one and let
  # pkgdown's take over, as it already does for the rest of the page.
  scaffolds <- xml2::xml_find_all(
    root,
    ".//div[contains(concat(' ', normalize-space(@class), ' '), ' code-copy-outer-scaffold ')]"
  )
  for (scaffold in scaffolds) {
    source_code <- xml2::xml_find_first(
      scaffold,
      "./div[contains(concat(' ', normalize-space(@class), ' '), ' sourceCode ')]"
    )
    if (is.na(xml2::xml_name(source_code))) {
      next
    }
    xml2::xml_replace(scaffold, parse_node_copy(source_code))
  }
}

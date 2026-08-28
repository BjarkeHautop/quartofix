#' Patch a pkgdown site's Quarto vignettes by restoring
#'
#' Walks the HTML files pkgdown generated from `.qmd` articles, restores
#' callout markup with [fix_quarto_callouts()], undoes pkgdown's corruption
#' of Quarto tabsets with [fix_quarto_tabsets()], detects code annotations
#' with [fix_quarto_annotations()], and - for any file that contains a
#' tabset or code annotation - links in the small
#' `quartofix.css`/`quartofix.js` assets that restore their styling and
#' interactivity (copied once into `<dst_path>/quartofix/`).
#'
#' Run this *after* `pkgdown::build_site()` (or `build_articles()`), since it
#' operates on the rendered HTML, not the `.qmd` source.
#'
#' @param dst_path Path to the built pkgdown site (`docs/` by default).
#' @param pkg_path Path to the package root, used to locate the `.qmd`
#'   source of each article (searched under `vignettes/`) so that
#'   [fix_quarto_callouts()] can recover callout types lost to custom
#'   titles. Set to `NULL` to skip source lookup entirely.
#' @param pattern Regex selecting which HTML files to inspect. Defaults to
#'   every `.html` file, which is harmless but slower on large sites; narrow
#'   it (e.g. `"^articles/"`) if you know where your Quarto articles land.
#' @return Invisibly, the paths of the HTML files that were modified.
#' @export
quartofix <- function(dst_path = "docs", pkg_path = ".", pattern = "[.]html$") {
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

    qmd_path <- if (!is.null(pkg_path)) find_qmd_source(pkg_path, f) else NULL
    n_callouts_fixed <- fix_quarto_callouts(f, qmd_path = qmd_path)
    n_tabsets_fixed <- if (has_tabset) fix_quarto_tabsets(f) else 0L
    n_tabsets_present <- if (has_tabset) count_panel_tabsets(f) else 0L
    n_annotations <- if (has_annotation) fix_quarto_annotations(f) else 0L

    if (n_callouts_fixed > 0 || n_tabsets_present > 0 || n_annotations > 0) {
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
    cli::cli_inform(c("v" = "quartofix patched {length(changed)} file{?s}."))
  } else {
    cli::cli_inform(
      "No Quarto callouts, tabsets, or annotations found - nothing to patch."
    )
  }

  invisible(changed)
}

count_panel_tabsets <- function(html_path) {
  doc <- xml2::read_html(html_path, encoding = "UTF-8")
  length(xml2::xml_find_all(
    doc,
    "//div[contains(concat(' ', normalize-space(@class), ' '), ' panel-tabset ')]"
  ))
}

find_qmd_source <- function(pkg_path, html_path) {
  vig_dir <- fs::path(pkg_path, "vignettes")
  if (!fs::dir_exists(vig_dir)) {
    return(NULL)
  }
  target <- paste0(fs::path_ext_remove(fs::path_file(html_path)), ".qmd")
  matches <- fs::dir_ls(
    vig_dir,
    recurse = TRUE,
    regexp = paste0("/", target, "$")
  )
  if (length(matches) == 1) matches[[1]] else NULL
}

ensure_assets <- function(dst_path) {
  asset_dir <- fs::path(dst_path, "quartofix")
  fs::dir_create(asset_dir)
  src_dir <- system.file("assets", package = "quartofix")
  fs::file_copy(
    fs::path(src_dir, c("quartofix.css", "quartofix.js")),
    fs::path(asset_dir, c("quartofix.css", "quartofix.js")),
    overwrite = TRUE
  )
}

inject_assets <- function(html_path, dst_path, already_has_assets = FALSE) {
  if (already_has_assets) {
    return(invisible(html_path))
  }

  depth <- length(fs::path_split(fs::path_rel(html_path, dst_path))[[1]]) - 1L
  prefix <- if (depth > 0) paste(rep("../", depth), collapse = "") else ""

  doc <- xml2::read_html(html_path, encoding = "UTF-8")
  head <- xml2::xml_find_first(doc, "//head")

  xml2::xml_add_child(
    head,
    "link",
    rel = "stylesheet",
    href = paste0(prefix, "quartofix/quartofix.css")
  )
  xml2::xml_add_child(
    head,
    "script",
    src = paste0(prefix, "quartofix/quartofix.js")
  )

  xml2::write_html(doc, html_path, options = "format")
  invisible(html_path)
}

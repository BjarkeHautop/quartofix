test_that("quartofix() and quartofix2() agree on the demo vignette", {
  local_on_cran()
  skip_on_cran()
  skip_if_not_installed("pkgdown")
  skip_if_not_installed("quarto")
  skip_if(
    is.null(tryCatch(quarto::quarto_path(), error = function(e) NULL)),
    "Quarto CLI not found"
  )

  pkg_root <- testthat::test_path("..", "..")
  site_dir <- withr::local_tempdir("quartofix-site-")
  suppressMessages(invisible(utils::capture.output(
    pkgdown::build_site(
      pkg = pkg_root,
      override = list(destination = site_dir),
      preview = FALSE,
      quiet = TRUE
    ),
    type = "output"
  )))

  dir1 <- fs::path(withr::local_tempdir("quartofix1-parent-"), "site")
  dir2 <- fs::path(withr::local_tempdir("quartofix2-parent-"), "site")
  fs::dir_copy(site_dir, dir1)
  fs::dir_copy(site_dir, dir2)

  suppressMessages(quartofix(
    dst_path = dir1,
    pkg_path = pkg_root,
    pattern = "articles/"
  ))
  suppressMessages(quartofix2(
    dst_path = dir2,
    pkg_path = pkg_root,
    pattern = "articles/"
  ))

  html1 <- fs::path(dir1, "articles", "demo-quartofix.html")
  html2 <- fs::path(dir2, "articles", "demo-quartofix2.html")
  expect_true(fs::file_exists(html1))
  expect_true(fs::file_exists(html2))

  # Compared on visible content (type/title/body text, tab labels + pane
  # content), not raw markup - quartofix2() splices genuine Quarto HTML,
  # which legitimately differs in markup shape (e.g. an extra a11y label on
  # callout titles, real Bootstrap nav-tabs instead of the `.panel-tabset-
  # tabby` nav quartofix() leaves in place) even when the visible result is
  # the same.
  expect_equal(extract_callouts(html1), extract_callouts(html2))
  expect_equal(extract_tabsets(html1), extract_tabsets(html2))
})

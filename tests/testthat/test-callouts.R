test_that("fix_quarto_callouts rewrites degraded default-titled callouts", {
  tmp <- withr::local_tempfile(fileext = ".html")
  writeLines(
    c(
      "<html><body>",
      "<div><blockquote><p><strong>Note</strong></p><p>Hello note</p></blockquote></div>",
      "</body></html>"
    ),
    tmp
  )

  n <- fix_quarto_callouts(tmp)
  expect_equal(n, 1L)

  doc <- xml2::read_html(tmp)
  callout <- xml2::xml_find_first(doc, "//div[contains(concat(' ', normalize-space(@class), ' '), ' callout ')]")
  expect_false(is.na(xml2::xml_name(callout)))
  expect_true(grepl("callout-note", xml2::xml_attr(callout, "class")))
  expect_equal(
    trimws(xml2::xml_text(xml2::xml_find_first(callout, ".//p"))),
    "Hello note"
  )
})

test_that("fix_quarto_callouts leaves genuine blockquotes untouched", {
  tmp <- withr::local_tempfile(fileext = ".html")
  writeLines(
    c(
      "<html><body>",
      "<blockquote><p>This is a genuine quote.</p></blockquote>",
      "</body></html>"
    ),
    tmp
  )

  n <- fix_quarto_callouts(tmp)
  expect_equal(n, 0L)

  doc <- xml2::read_html(tmp)
  expect_true(is.na(xml2::xml_name(xml2::xml_find_first(doc, "//div[contains(concat(' ', normalize-space(@class), ' '), ' callout ')]"))))
  expect_false(is.na(xml2::xml_name(xml2::xml_find_first(doc, "//blockquote"))))
})

test_that("fix_quarto_callouts falls back to note styling for custom titles", {
  tmp <- withr::local_tempfile(fileext = ".html")
  writeLines(
    c(
      "<html><body>",
      "<div><blockquote><p><strong>Custom title</strong></p><p>Body.</p></blockquote></div>",
      "</body></html>"
    ),
    tmp
  )

  fix_quarto_callouts(tmp)
  doc <- xml2::read_html(tmp)
  callout <- xml2::xml_find_first(doc, "//div[contains(concat(' ', normalize-space(@class), ' '), ' callout ')]")
  expect_true(grepl("callout-note", xml2::xml_attr(callout, "class")))
  expect_true(grepl(
    "Custom title",
    xml2::xml_text(xml2::xml_find_first(callout, ".//div[contains(@class,'callout-title-container')]"))
  ))
})

test_that("fix_quarto_callouts handles the real pkgdown/Quarto fixture", {
  fixture <- test_path("fixtures", "degraded.html")
  tmp <- withr::local_tempfile(fileext = ".html")
  file.copy(fixture, tmp, overwrite = TRUE)

  n <- fix_quarto_callouts(tmp)
  expect_equal(n, 2L)

  doc <- xml2::read_html(tmp)
  callouts <- xml2::xml_find_all(doc, "//div[contains(concat(' ', normalize-space(@class), ' '), ' callout ')]")
  expect_length(callouts, 2)

  # The real blockquote in the fixture must survive untouched.
  bq <- xml2::xml_find_all(doc, "//blockquote")
  expect_length(bq, 1)
  expect_true(grepl("genuine quote", xml2::xml_text(bq[[1]])))
})

test_that("get_prm_rules shape + a few canonical entries", {
  rules <- get_prm_rules()
  expect_s3_class(rules, "tbl_df")
  expect_true(all(c("family","min","max","units") %in% names(rules)))
  expect_gt(nrow(rules), 10)
  expect_false(anyNA(rules$family))
  expect_equal(nrow(rules), length(unique(rules$family)))

  swc <- subset(rules, family == "^SWC($|_)")
  expect_equal(nrow(swc), 1)
  expect_equal(unname(swc$min), 0)      # <- unname to ignore any names attr
  expect_equal(unname(swc$max), 100)
  expect_match(swc$units, "%", fixed = TRUE)

  co2c13 <- subset(rules, family == "^CO2C13($|_)")
  expect_equal(nrow(co2c13), 1)
  expect_true(is.na(co2c13$min))
  expect_equal(unname(co2c13$max), -6)
})

test_that("summarize = FALSE returns data.frame", {
  df <- tibble::tibble(SWC_1_1_1 = c(10, 101, 50))
  d_only <- apply_prm(df, summarize = FALSE, note = FALSE)

  # It's a data.frame/tibble…
  expect_s3_class(d_only, "data.frame")

  # …and definitely NOT the list(data=..., summary=...) shape
  expect_false(all(c("data","summary") %in% names(d_only)))
})




test_that("apply_prm basic clamping + QC untouched", {
  df <- tibble::tibble(
    TIMESTAMP_START = seq.POSIXt(as.POSIXct("2024-01-01", tz = "UTC"),
                                 length.out = 6, by = "30 min"),
    SWC_1_1_1 = c(10, 101, -3, 50, NA, 0.5),  # 101, -3 -> NA
    P         = c(0, 60, 10, NA, -1, 3),      # 60, -1 -> NA
    RH_1_1_1  = c(10, 110, 50, NA, 0, 101),   # 110, 101 -> NA
    SWC_QC    = c(0,1,2,0,1,2)                # should be ignored
  )
  res <- apply_prm(df, note = FALSE)
  expect_true(is.list(res) && all(c("data","summary") %in% names(res)))

  d <- res$data
  expect_true(is.data.frame(d))
  # SWC
  expect_true(is.na(d$SWC_1_1_1[2]))
  expect_true(is.na(d$SWC_1_1_1[3]))
  expect_false(is.na(d$SWC_1_1_1[1]))
  # P
  expect_true(is.na(d$P[2]))
  expect_true(is.na(d$P[5]))
  # RH
  expect_true(is.na(d$RH_1_1_1[2]))
  expect_true(is.na(d$RH_1_1_1[6]))
  # QC untouched
  expect_identical(d$SWC_QC, df$SWC_QC)
})

test_that("include= filters families", {
  df <- tibble::tibble(
    SWC_1_1_1 = c(10, 101),
    P         = c(0, 60)
  )
  res <- apply_prm(df, include = "SWC", note = FALSE)
  d <- res$data
  # SWC clamped
  expect_true(is.na(d$SWC_1_1_1[2]))
  # P unaffected
  expect_identical(d$P, df$P)
})

test_that("NA bound semantics (only lower or only upper)", {
  # N2O lower bound 0, no upper => negatives NA, large positives OK
  # CO2C13 only UPPER = -6 => > -6 is NA, <= -6 OK
  df <- tibble::tibble(
    N2O = c(-1, 0, 1000),
    CO2C13 = c(-8, -6, -4)
  )
  res <- apply_prm(df, note = FALSE)
  d <- res$data

  # N2O
  expect_true(is.na(d$N2O[1]))
  expect_identical(d$N2O[2], 0)
  expect_identical(d$N2O[3], 1000)

  # CO2C13
  expect_identical(d$CO2C13[1], -8)  # below the max OK
  expect_identical(d$CO2C13[2], -6)  # at the max OK
  expect_true(is.na(d$CO2C13[3]))    # above the max -> NA
})

test_that("summarize = FALSE returns data.frame", {
  df <- tibble::tibble(SWC_1_1_1 = c(10, 101, 50))
  d_only <- apply_prm(df, summarize = FALSE, note = FALSE)

  # It's a data.frame/tibble…
  expect_s3_class(d_only, "data.frame")

  # …and definitely NOT the list(data=..., summary=...) shape
  expect_false(all(c("data","summary") %in% names(d_only)))
})


test_that("message includes units and PRM range", {
  df <- tibble::tibble(
    SWC_1_1_1 = c(10, 101, 50, -3),
    P         = c(0, 60, 10, -1)
  )

  # 1) Capture messages
  msgs <- testthat::capture_messages(apply_prm(df, note = TRUE))
  msg  <- paste(msgs, collapse = "\n")

  # 2) Get return value in a separate call
  out <- apply_prm(df, note = TRUE)

  expect_match(msg, "expected units: %, PRM range: 0 to 100", fixed = TRUE)
  expect_match(msg, "expected units: mm, PRM range: 0 to 50", fixed = TRUE)
  expect_s3_class(out$summary, "tbl_df")   # sanity check return shape
})

test_that("no replacements -> informative message & empty summary", {
  df <- tibble::tibble(SWC_1_1_1 = c(0, 1, 50))

  # 1) Capture messages
  msgs <- testthat::capture_messages(apply_prm(df, note = TRUE))
  msg  <- paste(msgs, collapse = "\n")

  # 2) Get return value in a separate call
  out <- apply_prm(df, note = TRUE)

  expect_true(grepl("no replacements made", msg, fixed = TRUE))
  expect_s3_class(out$summary, "tbl_df")
  expect_equal(nrow(out$summary), 0)
})



test_that("no replacements -> informative message & empty summary", {
  df  <- tibble::tibble(SWC_1_1_1 = c(0, 1, 50))

  out <- NULL
  msgs <- testthat::capture_messages({
    out <<- apply_prm(df, note = TRUE)
  })
  msg <- paste(msgs, collapse = "\n")

  expect_true(grepl("no replacements made", msg, fixed = TRUE))
  expect_s3_class(out$summary, "tbl_df")
  expect_equal(nrow(out$summary), 0)
})




test_that("non data.frame input errors clearly", {
  expect_error(apply_prm(1:5), "is.data.frame\\(.data\\) is not TRUE")
})


test_that("skips _QC and _SSITC_TEST columns by default", {
  df <- tibble::tibble(
    SWC_1_1_1      = c(-3, 10, 101),   # should clamp -3, 101
    SWC_QC         = c(0, 1, 2),       # should be ignored
    FC             = c(-200, 0, 50),   # should clamp -200
    FC_SSITC_TEST  = c(0, 1, 2)        # should be ignored
  )

  out <- apply_prm(df, note = FALSE)   # default skip_qc = TRUE
  expect_true(is.na(out$data$SWC_1_1_1[1]))
  expect_true(is.na(out$data$SWC_1_1_1[3]))
  expect_identical(out$data$SWC_QC, df$SWC_QC)               # unchanged
  expect_true(is.na(out$data$FC[1]))                         # clamped
  expect_identical(out$data$FC_SSITC_TEST, df$FC_SSITC_TEST) # unchanged

  # And ensure summary doesn’t include the skipped cols
  expect_false(any(out$summary$column %in% c("SWC_QC","FC_SSITC_TEST")))
})


test_that("units/desc cover all families", {
  fam <- names(.prm_rules())
  expect_true(all(fam %in% names(.prm_units())))
  expect_true(all(fam %in% names(.prm_desc())))
})


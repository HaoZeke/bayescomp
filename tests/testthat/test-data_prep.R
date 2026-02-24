test_that("bc_read_benchmark reads wide format CSV", {
  path <- system.file("extdata", "baker_bench.csv", package = "bayescomp")
  skip_if(!file.exists(path), "Example data not found")

  data <- bc_read_benchmark(
    path,
    format = "wide",
    method_suffixes = c("CINEB", "MMF"),
    count_col = "Calls",
    time_col = "Time",
    success_col = "Term"
  )

  expect_s3_class(data, "tbl_df")
  expect_true("System" %in% names(data))
  expect_true("Calls_CINEB" %in% names(data))
  expect_true("Calls_MMF" %in% names(data))
  expect_equal(attr(data, "bc_format"), "wide")
  expect_true(is.factor(data$System))
})

test_that("bc_pivot_long pivots wide data to long format", {
  # Create minimal wide data
  wide <- data.frame(
    System = c("sys_a", "sys_b"),
    Calls_A = c(100, 200),
    Calls_B = c(50, 150),
    Time_A = c(1.0, 2.0),
    Time_B = c(0.5, 1.5),
    Term_A = c("GOOD", "GOOD"),
    Term_B = c("GOOD", "BAD_MAX_ITERATIONS"),
    stringsAsFactors = FALSE
  )
  attr(wide, "bc_system_col") <- "System"
  attr(wide, "bc_count_col") <- "Calls"
  attr(wide, "bc_time_col") <- "Time"
  attr(wide, "bc_success_col") <- "Term"
  attr(wide, "bc_format") <- "wide"

  long <- bc_pivot_long(
    wide,
    method_pattern = "_(A|B)$",
    method_levels = c("A", "B")
  )

  expect_equal(nrow(long), 4)
  expect_true("count" %in% names(long))
  expect_true("method" %in% names(long))
  expect_true("system_id" %in% names(long))
  expect_true("success" %in% names(long))
  expect_true(is.factor(long$method))
  expect_equal(levels(long$method), c("A", "B"))

  # Check success flag
  expect_true(all(long$success[long$method == "A"]))
  expect_false(long$success[long$system_id == "sys_b" & long$method == "B"])
})

test_that("bc_validate catches missing columns", {
  bad_data <- data.frame(x = 1:10)
  expect_error(bc_validate(bad_data), "Missing required column")
})

test_that("bc_validate catches non-numeric count", {
  bad_data <- data.frame(
    count = letters[1:4],
    method = factor(rep(c("A", "B"), 2)),
    system_id = factor(rep(c("s1", "s2"), each = 2))
  )
  expect_error(bc_validate(bad_data), "must be numeric")
})

test_that("bc_validate catches single method", {
  bad_data <- data.frame(
    count = 1:4,
    method = factor(rep("A", 4)),
    system_id = factor(rep(c("s1", "s2"), each = 2))
  )
  expect_error(bc_validate(bad_data), "at least 2 methods")
})

test_that("bc_validate passes for valid data", {
  good_data <- data.frame(
    count = c(100, 50, 200, 150),
    method = factor(rep(c("A", "B"), 2)),
    system_id = factor(rep(c("s1", "s2"), each = 2))
  )
  expect_invisible(bc_validate(good_data))
})

test_that("bc_validate catches NA values", {
  bad_data <- data.frame(
    count = c(100, NA, 200, 150),
    method = factor(rep(c("A", "B"), 2)),
    system_id = factor(rep(c("s1", "s2"), each = 2))
  )
  expect_error(bc_validate(bad_data), "NA")
})

test_that("bc_validate catches NaN values", {
  bad_data <- data.frame(
    count = c(100, NaN, 200, 150),
    method = factor(rep(c("A", "B"), 2)),
    system_id = factor(rep(c("s1", "s2"), each = 2))
  )
  expect_error(bc_validate(bad_data), "NaN")
})

test_that("bc_validate catches Inf values", {
  bad_data <- data.frame(
    count = c(100, Inf, 200, 150),
    method = factor(rep(c("A", "B"), 2)),
    system_id = factor(rep(c("s1", "s2"), each = 2))
  )
  expect_error(bc_validate(bad_data), "Inf")
})

test_that("bc_validate rejects negatives by default", {
  bad_data <- data.frame(
    count = c(100, -5, 200, 150),
    method = factor(rep(c("A", "B"), 2)),
    system_id = factor(rep(c("s1", "s2"), each = 2))
  )
  expect_error(bc_validate(bad_data), "negative")
})

test_that("bc_validate allows negatives with allow_negative=TRUE", {
  data_with_neg <- data.frame(
    count = c(1.5, -0.3, 2.1, -1.0),
    method = factor(rep(c("A", "B"), 2)),
    system_id = factor(rep(c("s1", "s2"), each = 2))
  )
  expect_invisible(bc_validate(data_with_neg, allow_negative = TRUE))
})

test_that("bc_pivot_long creates censoring column", {
  wide <- data.frame(
    System = c("sys_a", "sys_b"),
    Calls_A = c(100, 200),
    Calls_B = c(50, 150),
    Term_A = c("GOOD", "GOOD"),
    Term_B = c("GOOD", "BAD_MAX_ITERATIONS"),
    stringsAsFactors = FALSE
  )
  attr(wide, "bc_system_col") <- "System"
  attr(wide, "bc_count_col") <- "Calls"
  attr(wide, "bc_success_col") <- "Term"
  attr(wide, "bc_format") <- "wide"

  long <- bc_pivot_long(
    wide,
    method_pattern = "_(A|B)$",
    method_levels = c("A", "B"),
    cens_value = "BAD_MAX_ITERATIONS"
  )

  expect_true("censored" %in% names(long))
  expect_true("success" %in% names(long))
  expect_type(long$censored, "integer")
  # sys_b method B should be censored
  expect_equal(
    long$censored[long$system_id == "sys_b" & long$method == "B"],
    1L
  )
  # sys_a method A should not be censored
  expect_equal(
    long$censored[long$system_id == "sys_a" & long$method == "A"],
    0L
  )
})

# Test-located srr standards
#
# Standards that are best demonstrated by test code are documented here.
# This file ensures standards span multiple directories (R/, tests/).

# @srrstats {G5.2b} Tests below demonstrate conditions triggering every
#   cli_abort/cli_warn message, comparing with expected values.
# @srrstats {G5.4b} test-recovery.R: recovery tests compare against
#   known DGP parameters (bc_simulate_benchmark), serving as reference.
# @srrstats {G5.4c} Not applicable: bayescomp is a new methodology
#   without published reference implementations to compare against.
# @srrstats {G5.7} test-recovery.R: parameter recovery improves with
#   more data (n_systems = 20 recovers within 90% CrI).
# @srrstats {G5.9a} test-edge-cases.R: trivial noise at
#   .Machine$double.eps scale does not change bc_validate results.
# @srrstats {G5.9b} test-recovery.R: multiple seeds (42-49) across
#   8 recovery tests all recover the true parameter.
# @srrstats {RE7.1} test-recovery.R: correctness tests against known
#   DGP (bc_simulate_benchmark) for NB, Gamma, Bernoulli, Student-t.
# @srrstats {RE7.1a} test-recovery.R uses 8 different simulated datasets
#   with known properties (different families, censoring, seeds).
# @srrstats {RE7.4} test-edge-cases.R and test-data_prep.R: edge cases
#   including zero-length data, single-method, all-NA fields.
# @srrstats {BS7.1} test-recovery.R with n_systems=0 or uninformative
#   data recovers prior distribution (brms property).
# @srrstats {BS7.3} test-recovery.R: 8 tests across 4 families with
#   n_systems=20 demonstrate scaling. Extended tests use larger n.
# @srrstats {BS7.4a} test-recovery.R: bc_simulate_benchmark with
#   different intercept/system_sd values tests scale assumptions.

test_that("srr: trivial noise does not affect validation", {
  data <- bc_simulate_benchmark(n_systems = 5, n_methods = 2, seed = 99)
  # Add trivial noise at machine epsilon scale
  data$count <- data$count + .Machine$double.eps * 0.1
  # Should still pass validation (count is still numeric and positive)
  expect_silent(bc_validate(data))
})

test_that("srr: different seeds produce structurally consistent output", {
  d1 <- bc_simulate_benchmark(n_systems = 5, seed = 100)
  d2 <- bc_simulate_benchmark(n_systems = 5, seed = 200)
  # Structure identical, values differ

  expect_equal(names(d1), names(d2))
  expect_equal(nrow(d1), nrow(d2))
  expect_equal(levels(d1$method), levels(d2$method))
  # Values are different (stochastic)
  expect_false(all(d1$count == d2$count))
})

test_that("srr: zero-length data errors informatively", {
  # Zero rows with no factor levels -> single implicit level -> error
  empty <- data.frame(
    count = numeric(0),
    method = factor(),
    system_id = factor()
  )
  expect_error(bc_validate(empty), "at least 2 methods")
})

test_that("srr: all-NA response errors informatively", {
  data <- bc_simulate_benchmark(n_systems = 5, seed = 101)
  data$count <- NA_real_
  expect_error(bc_validate(data), "NA")
})

test_that("srr: single method errors informatively", {
  data <- data.frame(
    count = c(10, 20, 30),
    method = factor(rep("A", 3)),
    system_id = factor(c("s1", "s2", "s3"))
  )
  expect_error(bc_validate(data), "at least 2 methods")
})

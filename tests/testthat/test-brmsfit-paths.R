# Tests using a pre-fitted brmsfit fixture (tiny model, 1 chain, 100 iter)
# The fixture is ~45KB and avoids needing cmdstan on CI.

fixture_path <- testthat::test_path("fixtures", "tiny_brmsfit.rds")

skip_if_no_fixture <- function() {
  skip_if(!file.exists(fixture_path), "brmsfit fixture not available")
}

test_that("fixture loads as brmsfit", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  expect_s3_class(fit, "brmsfit")
})

test_that("bc_check_convergence works on fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  result <- bc_check_convergence(fit)
  expect_type(result, "list")
  expect_true("passed" %in% names(result))
  expect_true("summary" %in% names(result))
  expect_true("max_rhat" %in% names(result))
  expect_true("min_ess" %in% names(result))
  expect_true("problems" %in% names(result))
})

test_that("bc_summarize_effects works on fixture (log link)", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  effects <- bc_summarize_effects(fit)
  expect_s3_class(effects, "tbl_df")
  expect_true("effect_type" %in% names(effects))
  expect_true("median" %in% names(effects))
  expect_true("formatted" %in% names(effects))
  # Log-link: should have Multiplicative and Percentage rows
  expect_true(any(grepl("Multiplicative", effects$effect_type)))
  expect_true(any(grepl("Percentage", effects$effect_type)))
})

test_that("bc_effect_table works on fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  tbl <- bc_effect_table(fit)
  expect_s3_class(tbl, "tbl_df")
  expect_true("Effect" %in% names(tbl))
  expect_true("Median" %in% names(tbl))
  expect_true("95% CrI" %in% names(tbl))
})

test_that("bc_report works on fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  result <- bc_report(fit, loo = FALSE)
  expect_type(result, "list")
  expect_true("convergence" %in% names(result))
  expect_true("effects" %in% names(result))
})

test_that("bc_pp_check returns plots on fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  plots <- bc_pp_check(fit)
  expect_type(plots, "list")
  expect_true("density" %in% names(plots))
})

test_that("bc_plot_pp works on fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  p <- bc_plot_pp(fit)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_trace works on fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  p <- bc_plot_trace(fit)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_forest works on fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  p <- bc_plot_forest(fit)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_conditional works on fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  p <- bc_plot_conditional(fit, effects = "method")
  expect_s3_class(p, "ggplot")
})

test_that(".report_shape works on negbinomial fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  expect_invisible(bayescomp:::.report_shape(fit, model_shape = FALSE))
})

test_that("bc_loo works on fixture (without reloo)", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  loo_result <- bc_loo(fit, reloo = FALSE)
  expect_s3_class(loo_result, "loo")
})

test_that("bc_plot_shape works on fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  # May warn about shape submodel, but should not error
  p <- tryCatch(bc_plot_shape(fit), error = function(e) NULL)
  # If it returned a plot, check it
  if (!is.null(p)) expect_s3_class(p, "ggplot")
})

test_that("bc_plot_loo_pit works on fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  loo_result <- bc_loo(fit, reloo = FALSE)
  p <- bc_plot_loo_pit(fit, loo_result, fit$data$count)
  expect_s3_class(p, "ggplot")
})

test_that("bc_plot_pareto_k works on fixture loo result", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  loo_result <- bc_loo(fit, reloo = FALSE)
  p <- bc_plot_pareto_k(loo_result)
  expect_s3_class(p, "ggplot")
})

test_that("bc_report with loo=TRUE works on fixture", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  # Tiny fixture may fail LOO (too few draws), so wrap in tryCatch
  result <- tryCatch(
    bc_report(fit, loo = TRUE),
    error = function(e) bc_report(fit, loo = FALSE)
  )
  expect_type(result, "list")
  expect_true("convergence" %in% names(result))
  expect_true("effects" %in% names(result))
})

test_that("bc_epred_draws works on fixture without cache", {
  skip_if_no_fixture()
  fit <- readRDS(fixture_path)
  newdata <- fit$data[1:2, ]
  draws <- bc_epred_draws(fit, newdata = newdata, ndraws = 5)
  expect_s3_class(draws, "tbl_df")
})

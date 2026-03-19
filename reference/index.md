# Package index

## Data Preparation

Read, reshape, validate, and filter benchmark data.

- [`bc_read_benchmark()`](https://haozeke.github.io/bayescomp/reference/bc_read_benchmark.md)
  : Read and validate benchmark data
- [`bc_pivot_long()`](https://haozeke.github.io/bayescomp/reference/bc_pivot_long.md)
  : Pivot wide-format benchmark data to long
- [`bc_validate()`](https://haozeke.github.io/bayescomp/reference/bc_validate.md)
  : Validate benchmark data structure
- [`bc_filter_matching()`](https://haozeke.github.io/bayescomp/reference/bc_filter_matching.md)
  : Filter to systems where all methods found the same result

## Family and Prior Selection

Auto-detect response families and set weakly informative priors.

- [`bc_suggest_family()`](https://haozeke.github.io/bayescomp/reference/bc_suggest_family.md)
  : Suggest appropriate brms family based on response variable
- [`bc_default_priors()`](https://haozeke.github.io/bayescomp/reference/bc_default_priors.md)
  : Default weakly informative priors for benchmark models

## Model Fitting

Fit Bayesian hierarchical models for benchmark comparison.

- [`bc_fit()`](https://haozeke.github.io/bayescomp/reference/bc_fit.md)
  : Fit a Bayesian benchmark comparison model
- [`bc_fit_design()`](https://haozeke.github.io/bayescomp/reference/bc_fit_design.md)
  : Fit a Bayesian benchmark model with a custom formula
- [`bc_fit_suite()`](https://haozeke.github.io/bayescomp/reference/bc_fit_suite.md)
  : Fit a suite of models on the same benchmark data

## Diagnostics

Convergence checks, LOO-CV, posterior predictive validation.

- [`bc_check_convergence()`](https://haozeke.github.io/bayescomp/reference/bc_check_convergence.md)
  : Check convergence diagnostics for a brmsfit
- [`bc_loo()`](https://haozeke.github.io/bayescomp/reference/bc_loo.md)
  : Compute LOO-CV with optional reloo
- [`bc_loo_compare()`](https://haozeke.github.io/bayescomp/reference/bc_loo_compare.md)
  : Compare models via LOO-CV
- [`bc_pp_check()`](https://haozeke.github.io/bayescomp/reference/bc_pp_check.md)
  : Run posterior predictive check suite
- [`bc_dharma_check()`](https://haozeke.github.io/bayescomp/reference/bc_dharma_check.md)
  : DHARMa residual diagnostics for brms models
- [`bc_report()`](https://haozeke.github.io/bayescomp/reference/bc_report.md)
  : Generate a complete analysis report

## Effect Extraction

Summarize method effects with credible intervals.

- [`bc_summarize_effects()`](https://haozeke.github.io/bayescomp/reference/bc_summarize_effects.md)
  : Summarize treatment effects on the response scale
- [`bc_effect_table()`](https://haozeke.github.io/bayescomp/reference/bc_effect_table.md)
  : Generate a publication-ready effect summary table
- [`bc_pairwise_contrasts()`](https://haozeke.github.io/bayescomp/reference/bc_pairwise_contrasts.md)
  : Pairwise method contrasts

## Predictions

Cached posterior expected predictions.

- [`bc_epred_draws()`](https://haozeke.github.io/bayescomp/reference/bc_epred_draws.md)
  : Cached posterior expected predictions

## Simulation

Generate synthetic benchmark data for power analysis.

- [`bc_simulate_benchmark()`](https://haozeke.github.io/bayescomp/reference/bc_simulate_benchmark.md)
  : Simulate benchmark comparison data

## Visualization

Publication-quality plots for benchmark comparison.

- [`bc_plot_conditional()`](https://haozeke.github.io/bayescomp/reference/bc_plot_conditional.md)
  : Conditional effects plot with raw data overlay
- [`bc_plot_pp()`](https://haozeke.github.io/bayescomp/reference/bc_plot_pp.md)
  : Posterior predictive check plot
- [`bc_plot_shape()`](https://haozeke.github.io/bayescomp/reference/bc_plot_shape.md)
  : Shape parameter posterior density comparison
- [`bc_plot_loo_pit()`](https://haozeke.github.io/bayescomp/reference/bc_plot_loo_pit.md)
  : LOO-PIT QQ plot
- [`bc_plot_forest()`](https://haozeke.github.io/bayescomp/reference/bc_plot_forest.md)
  : Forest plot of method effects
- [`bc_plot_contrasts()`](https://haozeke.github.io/bayescomp/reference/bc_plot_contrasts.md)
  : Plot pairwise method contrasts
- [`bc_plot_pareto_k()`](https://haozeke.github.io/bayescomp/reference/bc_plot_pareto_k.md)
  : Pareto-k diagnostic plot
- [`bc_plot_trace()`](https://haozeke.github.io/bayescomp/reference/bc_plot_trace.md)
  : Trace plots for MCMC diagnostics
- [`bc_plot_cactus()`](https://haozeke.github.io/bayescomp/reference/bc_plot_cactus.md)
  : Cactus plot (cumulative performance profile)
- [`bc_plot_performance_profile()`](https://haozeke.github.io/bayescomp/reference/bc_plot_performance_profile.md)
  : Performance profile (ratio-based)
- [`bc_plot_dumbbell()`](https://haozeke.github.io/bayescomp/reference/bc_plot_dumbbell.md)
  : Dumbbell plot for paired method comparison
- [`bc_plot_violin()`](https://haozeke.github.io/bayescomp/reference/bc_plot_violin.md)
  : Violin plot for method comparison
- [`bc_plot_method_diff()`](https://haozeke.github.io/bayescomp/reference/bc_plot_method_diff.md)
  : Signed method difference plot
- [`bc_plot_scatter_comparison()`](https://haozeke.github.io/bayescomp/reference/bc_plot_scatter_comparison.md)
  : Scatter comparison of two methods (1:1 plot)

## Theme and Colors

ggplot2 theme and color palettes.

- [`theme_bayescomp()`](https://haozeke.github.io/bayescomp/reference/theme_bayescomp.md)
  : Publication theme for bayescomp
- [`scale_color_bayescomp()`](https://haozeke.github.io/bayescomp/reference/scale_color_bayescomp.md)
  [`scale_colour_bayescomp()`](https://haozeke.github.io/bayescomp/reference/scale_color_bayescomp.md)
  : Discrete color scale for bayescomp
- [`scale_fill_bayescomp()`](https://haozeke.github.io/bayescomp/reference/scale_fill_bayescomp.md)
  : Fill scale for bayescomp
- [`bc_colors`](https://haozeke.github.io/bayescomp/reference/bayescomp_colors.md)
  [`bc_colors_discrete`](https://haozeke.github.io/bayescomp/reference/bayescomp_colors.md)
  : bayescomp color palettes

## Targets Integration

Build reproducible pipelines with targets.

- [`bc_tar_pipeline()`](https://haozeke.github.io/bayescomp/reference/bc_tar_pipeline.md)
  : Create a targets-compatible benchmark analysis pipeline

library(targets)
library(bayescomp)

tar_option_set(packages = c(
  "bayescomp", "dplyr", "ggplot2", "brms", "tidybayes"
))

list(
  # -- Data loading and pivoting --
  tar_target(bench_raw, bc_read_benchmark(
    system.file("extdata", "baker_bench.csv", package = "bayescomp"),
    format = "wide",
    method_suffixes = c("CINEB", "MMF"),
    system_col = "System",
    count_col = "Calls",
    time_col = "Time",
    success_col = "Term"
  )),

  tar_target(bench_long, bc_pivot_long(
    bench_raw,
    method_pattern = "_(CINEB|MMF)$",
    method_levels = c("CINEB", "MMF")
  )),

  # -- Model fitting --
  tar_target(model_counts, bc_fit(
    bench_long,
    response = "count",
    spline_by_method = "RMSD_Init_Final",
    model_shape = TRUE,
    chains = 4,
    iter = 4000,
    warmup = 1000,
    cores = 4,
    adapt_delta = 0.999,
    max_treedepth = 15,
    file = "data/models/bayescomp_counts"
  )),

  # -- Diagnostics --
  tar_target(convergence, bc_check_convergence(model_counts)),
  tar_target(loo_result, bc_loo(model_counts)),

  # -- Effects --
  tar_target(effect_summary, bc_summarize_effects(model_counts)),
  tar_target(effect_table, bc_effect_table(model_counts)),

  # -- Plots --
  tar_target(fig_pp_density, {
    p <- bc_plot_pp(model_counts)
    ggsave("figures/pp_density.png", p, width = 8, height = 6, dpi = 300)
    "figures/pp_density.png"
  }),

  tar_target(fig_shape, {
    p <- bc_plot_shape(model_counts)
    ggsave("figures/shape_posterior.png", p, width = 8, height = 6, dpi = 300)
    "figures/shape_posterior.png"
  }),

  tar_target(fig_conditional, {
    p <- bc_plot_conditional(
      model_counts,
      effects = "RMSD_Init_Final:method",
      data = bench_long,
      response_col = "count",
      colors = c("CINEB" = "#FF655D", "MMF" = "#004D40")
    )
    ggsave("figures/conditional_effects.png", p, width = 8, height = 6, dpi = 300)
    "figures/conditional_effects.png"
  }),

  tar_target(fig_loo_pit, {
    p <- bc_plot_loo_pit(model_counts, loo_result, bench_long$count)
    ggsave("figures/loo_pit.png", p, width = 8, height = 6, dpi = 300)
    "figures/loo_pit.png"
  })
)

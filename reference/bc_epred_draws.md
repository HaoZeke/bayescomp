# Cached posterior expected predictions

Computes or loads cached posterior expected predictions using
[`tidybayes::add_epred_draws()`](https://mjskay.github.io/tidybayes/reference/add_predicted_draws.html).
Results are saved to a zstd-compressed RDS file for fast reloading.

## Usage

``` r
bc_epred_draws(model, newdata, file = NULL, ndraws = NULL, ...)
```

## Arguments

- model:

  A `brmsfit` object.

- newdata:

  Data frame for predictions.

- file:

  Cache file path (should end in `.rds`). If `NULL`, no caching.

- ndraws:

  Number of posterior draws (default `NULL` for all).

- ...:

  Additional arguments passed to
  [`tidybayes::add_epred_draws()`](https://mjskay.github.io/tidybayes/reference/add_predicted_draws.html).

## Value

A grouped data frame from
[`tidybayes::add_epred_draws()`](https://mjskay.github.io/tidybayes/reference/add_predicted_draws.html).

## Examples

``` r
if (FALSE) { # \dontrun{
data <- bc_simulate_benchmark(n_systems = 20)
model <- bc_fit(data, response = "count")
draws <- bc_epred_draws(model, newdata = data)
} # }
```

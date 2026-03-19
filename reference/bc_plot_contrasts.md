# Plot pairwise method contrasts

Horizontal pointrange plot of all pairwise contrasts with a zero-line.

## Usage

``` r
bc_plot_contrasts(contrasts, colors = NULL)
```

## Arguments

- contrasts:

  A tibble from
  [`bc_pairwise_contrasts()`](https://haozeke.github.io/bayescomp/reference/bc_pairwise_contrasts.md)
  with columns: contrast, estimate, lower, upper.

- colors:

  Character vector of colors for each contrast (optional).

## Value

A ggplot object.

## Examples

``` r
if (FALSE) { # \dontrun{
model <- bc_fit(bc_simulate_benchmark(), response = "count")
contrasts <- bc_pairwise_contrasts(model)
bc_plot_contrasts(contrasts)
} # }
```

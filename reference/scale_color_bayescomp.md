# Discrete color scale for bayescomp

Discrete color scale for bayescomp

## Usage

``` r
scale_color_bayescomp(..., reverse = FALSE)

scale_colour_bayescomp(..., reverse = FALSE)
```

## Arguments

- ...:

  Arguments passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

- reverse:

  Logical. Reverse palette order?

## Value

A ggplot2 scale.

## Examples

``` r
library(ggplot2)
data <- bc_simulate_benchmark(n_systems = 10, n_methods = 3)
ggplot(data, aes(system_id, count, color = method)) +
  geom_point() + scale_color_bayescomp()
```

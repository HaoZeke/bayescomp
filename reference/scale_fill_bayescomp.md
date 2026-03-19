# Fill scale for bayescomp

Fill scale for bayescomp

## Usage

``` r
scale_fill_bayescomp(..., reverse = FALSE)
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
ggplot(data, aes(method, count, fill = method)) +
  geom_boxplot() + scale_fill_bayescomp()
```

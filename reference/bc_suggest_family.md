# Suggest appropriate brms family based on response variable

Examines the response vector and suggests the most appropriate brms
family. Provides opinionated guidance: count data gets negative binomial
(not Gaussian), positive continuous gets Gamma, binary gets Bernoulli,
real-valued (with negatives) gets Student-t. Warns against Gaussian for
count or positive-only data, since Gaussian assumptions produce
misleading results in these cases (see Goswami 2025, arXiv:2505.13621).

## Usage

``` r
bc_suggest_family(
  y,
  type = c("auto", "count", "time", "success", "real", "gaussian")
)
```

## Arguments

- y:

  Response vector.

- type:

  One of `"auto"`, `"count"`, `"time"`, `"success"`, `"real"`, or
  `"gaussian"`. When `"auto"`, the type is inferred from `y`. `"real"`
  selects Student-t for signed real-valued data (energy errors, barrier
  differences). `"gaussian"` forces Gaussian but warns if data looks
  like counts or positive-only.

## Value

A brms family object.

## Examples

``` r
bc_suggest_family(c(100, 200, 50, 300))
#> ℹ Count data detected. Using negative binomial (log link).
#> ℹ Gaussian models produce misleading results for count data.
#> ℹ Variance = 12291.7, mean = 162.5.
#> 
#> Family: negbinomial 
#> Link function: log 
#> 
bc_suggest_family(c(1.5, 2.3, 0.8), type = "time")
#> ℹ Positive continuous data detected. Using Gamma (log link).
#> ℹ Gaussian assumes symmetric errors around zero.
#> 
#> Family: gamma 
#> Link function: log 
#> 
```

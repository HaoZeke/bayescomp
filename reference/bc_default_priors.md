# Default weakly informative priors for benchmark models

Returns a set of weakly informative priors appropriate for benchmark
comparison models. These are designed to regularize estimation in
small-sample settings (N=20-100 systems) without dominating the data.

## Usage

``` r
bc_default_priors(
  family = brms::negbinomial(),
  has_shape_submodel = FALSE,
  has_spline = FALSE
)
```

## Arguments

- family:

  A brms family object. Used to select appropriate priors.

- has_shape_submodel:

  Logical. If `TRUE`, adds priors for the shape submodel (relevant for
  negative binomial).

- has_spline:

  Logical. If `TRUE`, adds priors for smoothing spline hyperparameters
  (`sds` class). Only relevant when the formula includes `s()` terms.

## Value

A `brmsprior` object.

## Examples

``` r
bc_default_priors()
#>                 prior     class coef group resp dpar nlpar   lb   ub tag source
#>          normal(0, 1)         b                            <NA> <NA>       user
#>        exponential(1)        sd                            <NA> <NA>       user
#>  student_t(3, 0, 2.5) Intercept                            <NA> <NA>       user
bc_default_priors(family = brms::brmsfamily("Gamma", link = "log"))
#>                 prior     class coef group resp dpar nlpar   lb   ub tag source
#>          normal(0, 1)         b                            <NA> <NA>       user
#>        exponential(1)        sd                            <NA> <NA>       user
#>  student_t(3, 0, 2.5) Intercept                            <NA> <NA>       user
#>     gamma(0.01, 0.01)     shape                            <NA> <NA>       user
```

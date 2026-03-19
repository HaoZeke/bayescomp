# Publication theme for bayescomp

A clean ggplot2 theme based on ggthemes::theme_foundation with Atkinson
Hyperlegible font (when available).

## Usage

``` r
theme_bayescomp(base_size = 14, base_family = "sans")
```

## Arguments

- base_size:

  Base font size (default 14).

- base_family:

  Font family (default `"Atkinson Hyperlegible"`). Falls back to
  `"sans"` if not available.

## Value

A ggplot2 theme.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_bayescomp()
```

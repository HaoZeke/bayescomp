# Dumbbell plot for paired method comparison

Shows paired values for two methods connected by segments, with the
difference labeled. Systems are sorted by the reference method's cost.
This is the primary comparison visualization in the OCI-NEB paper.

## Usage

``` r
bc_plot_dumbbell(
  data,
  response = "count",
  method_col = "method",
  system_col = "system_id",
  colors = NULL,
  show_labels = TRUE,
  cap_value = NULL
)
```

## Arguments

- data:

  Long-format benchmark data.

- response:

  Name of the response column (default `"count"`).

- method_col:

  Name of the method column (default `"method"`).

- system_col:

  Name of the system column (default `"system_id"`).

- colors:

  Named character vector of two method colors. If `NULL`, uses coral
  (reference) and teal (treatment).

- show_labels:

  Logical. Show speedup ratio labels? (default `TRUE`).

- cap_value:

  Maximum value to display (for capping failed runs). `NULL` for no
  capping.

## Value

A ggplot object.

## Examples

``` r
data <- bc_simulate_benchmark(n_systems = 10, n_methods = 2)
bc_plot_dumbbell(data)
```

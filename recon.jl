"""
This script performs reconciliation of base forecasts and evaluation of the results.
It should be run with a single argument, which specifies the covariance estimator to use for reconciliation:
```
julia --project recon.jl {estimator}
```
where {estimator} is `LedWol`, `SchStr` or `WLS`.
"""

include(joinpath("src", "thief.jl"))

start_date = 20210101
end_date = 20241231
cov_estimator = Symbol(ARGS[1])

run_integrity()
run_reconciliation(cov_estimator)
run_evaluation(start_date, end_date, cov_estimator)

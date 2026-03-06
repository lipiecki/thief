"""
This script performs reconciliation of base forecasts and evaluation of the results.
"""

using Pkg
include(joinpath("src", "thief.jl"))

start_date = 20210101
end_date = 20241231

cov_estimator = Symbol(ARGS[1])

run_integrity()
run_reconciliation(cov_estimator)
run_evaluation(start_date, end_date, cov_estimator)

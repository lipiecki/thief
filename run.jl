"""
This script performs reconciliation of base forecasts and evaluation of the results.
"""

using Pkg
include(joinpath("src", "thief.jl"))

start_date = parse(Int, ARGS[1])
end_date = parse(Int, ARGS[2])
cov_estimator = Symbol(ARGS[3])

run_integrity()
run_reconciliation(cov_estimator)
run_evaluation(start_date, end_date, cov_estimator)

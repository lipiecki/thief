using JLD2, Statistics, Distributions, LinearAlgebra

include("shrunkcov.jl")
include("reconcile.jl")
include("dieboldmariano.jl")
include("integrity.jl")

"""
    run_integrity()
Run data integrity checks on all markets and models.
"""
function run_integrity()
    for market in ["epex", "omie"]
        integrity(models=["arx", "narx", "xgb", "mitra"], market=market)
    end
end

"""
    run_reconciliation(;cov_estimator::Symbol)
Run the reconciliation of base forecasts on all markets and models.
"""
function run_reconciliation(cov_estimator::Symbol)
    mkpath("results")
    for market in ["epex", "omie"]
        for model in ["arx", "narx", "xgb", "mitra"]
            reconcile(model=model, market=market, cov_estimator=cov_estimator)
        end
    end
end

"""
    run_evaluation(start_date::Int, end_date::Int, cov_estimator::Symbol)
Run the evaluation of base and reconcilied forecasts between the provided dates (YYYYMMDD format), print the relevant metrics (MAE, RMSE and p-value of the Diebold-Mariano test) to console.
"""
function run_evaluation(start_date::Int, end_date::Int, cov_estimator::Symbol)
    println("\nTesting on the $start_date - $end_date period")
    hline = 80
    println("-"^hline)
    blocks = [1, 2, 3, 4, 6, 8, 12, 24]
    no_block_forecasts = zeros(Int, length(blocks))
    for b in eachindex(blocks)
        no_block_forecasts[b] = Int(24 / blocks[b])
    end

    for market in ["epex", "omie"]
        println(uppercase(market))
        println("-"^hline)
        println("BLOCK\tMODEL\tMAE\tMAE-r\tgain(%)\tRMSE\tRMSE-r\tgain(%)\tDM(%)")
        println("-"^hline)

        for b in eachindex(blocks)
            block_indices = b > 1 ? (sum(no_block_forecasts[1:b-1])+1:sum(no_block_forecasts[1:b])) : 1:24

            for model in ["arx", "narx", "xgb", "mitra"]
                f = load(joinpath("results", "$model-$market-$cov_estimator.jld2"))
                observations, forecasts, forecasts_thief, dates =
                    f["observations"], f["forecasts"], f["forecasts_thief"], f["dates"]

                start = findfirst(dates .== start_date)
                stop = findfirst(dates .== end_date)

                block_forecasts = forecasts[start:stop, block_indices]
                block_forecasts_thief = forecasts_thief[start:stop, block_indices]
                block_observations = observations[start:stop, block_indices]
                mae = mean(abs.(block_forecasts .- block_observations))
                rmse = sqrt(mean(abs2.(block_forecasts .- block_observations)))
                mae_thief = mean(abs.(block_forecasts_thief .- block_observations))
                rmse_thief = sqrt(mean(abs2.(block_forecasts_thief .- block_observations)))
                pvalue = 100*dieboldmariano(block_observations, block_forecasts, block_forecasts_thief)
                print("$(blocks[b])H\t$(uppercase(model))\t") # pretty printing
                print("$(round(mae, digits=2))\t$(round(mae_thief, digits=2))\t$(round(100*(mae-mae_thief)/mae, digits=1))\t") # mae-based 
                print("$(round(rmse, digits=2))\t$(round(rmse_thief, digits=2))\t$(round(100*(rmse-rmse_thief)/rmse, digits=1))\t") # rmse-based
                if pvalue < 1
                    print("$(round(pvalue, digits=1))")
                elseif pvalue < 5
                    printstyled("$(round(pvalue, digits=1))", color=:yellow)
                else
                    printstyled("$(round(pvalue, digits=1))", color=:red)
                end
                print("\n")
            end
            println("-"^hline)
        end
        println("-"^hline)
    end
end

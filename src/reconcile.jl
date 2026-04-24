"""
    reconcile(;model::AbstractString, market::AbstractString, cov_estimator::Symbol)
Perform reconciliation for a given `market` and `model`. The base forecasts are sourced from the files stored in the `base-forecasts` directory. 
"""
function reconcile(;model::AbstractString, market::AbstractString, cov_estimator::Symbol)
    f = load(joinpath("base-forecasts", "$model-$market.jld2"))
    observations, forecasts, dates, in_sample_errors = 
        Float64.(f["observations"]), Float64.(f["forecasts"]), Int.(f["dates"]), Float64.(f["in_sample_errors"])

    T = eltype(observations)
    
    blocks = Int.([1, 2, 3, 4, 6, 8, 12, 24])
    no_block_forecasts = zeros(Int, length(blocks))
    for b in eachindex(blocks)
        no_block_forecasts[b] = Int(24/blocks[b])
    end

    B = Int(sum(no_block_forecasts))
    
    Σ = zeros(T, B, B)
    W = zeros(T, 24, B)
    S = zeros(T, B, 24)
    
    n = length(dates)
    forecasts_thief = zeros(T, n, B)
   
    bi = 0
    for b in eachindex(blocks)
        for l in 1:no_block_forecasts[b]
            bi += 1
            hours = Int.((l-1)*blocks[b]+1:l*blocks[b])
            for hour in hours
                S[bi, hour] = 1/blocks[b]
            end
        end
    end
    St = transpose(S)

    for t in 1:n
        shrunkcov!(Σ, in_sample_errors[:, t, :], target=cov_estimator)
        W .= ((St*(Σ\S))\St)/Σ
        @views forecasts_thief[t, :] .= S*W*forecasts[t, :]
    end
    save(joinpath("results", "$model-$market-$cov_estimator.jld2"), "forecasts_thief", forecasts_thief, "forecasts", forecasts, "observations", observations, "dates", dates)
end

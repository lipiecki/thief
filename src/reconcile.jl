"""
    reconcile(;model, market, cov_estimator=:LedWol)
Perform reconciliation for a given `market` and `model`. The base forecasts are sourced from the files stored in the `base-forecasts` directory. 
"""
function reconcile(;model::AbstractString, market::AbstractString, cov_estimator::Symbol=:LedWol)
    f = load(joinpath("base-forecasts", "$model-$market.jld2"))
    observations, forecasts, dates, in_sample_errors = 
        f["observations"], f["forecasts"], f["dates"], f["in_sample_errors"]
    T = eltype(observations)
    
    blocks = Int.([1, 2, 3, 4, 6, 8, 12, 24])
    no_block_forecasts = zeros(Int, length(blocks))
    for b in eachindex(blocks)
        no_block_forecasts[b] = Int(24/blocks[b])
    end

    B = Int(sum(no_block_forecasts))
    
    Σ = zeros(T, B, B)
    W = zeros(T, 24, B)
    
    SM = zeros(T, B, 24)
    T = length(dates)
    forecasts_thief = zeros(T, B)
   
    bi = 0
    for b in eachindex(blocks)
        for l in 1:no_block_forecasts[b]
            bi += 1
            hours = Int.((l-1)*blocks[b]+1:l*blocks[b])
            for hour in hours
                SM[bi, hour] = 1/blocks[b]
            end
        end
    end
    
    for t in 1:T
        shrunkcov!(Σ, in_sample_errors[:, t, :], target=cov_estimator)
        W .= inv(transpose(SM)*inv(Σ)*SM)*transpose(SM)*inv(Σ)
        forecasts_thief[t, :] .= SM*W*forecasts[t, :]
    end
    save(joinpath("results", "$model-$market.jld2"), "forecasts_thief", forecasts_thief, "forecasts", forecasts, "observations", observations, "dates", dates)
end

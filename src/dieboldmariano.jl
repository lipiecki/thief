"""
    dieboldmariano(obs::AbstractVecOrMat{<:Real}, benchmark::AbstractVecOrMat{<:Real}, forecasts::AbstractVecOrMat{<:Real})
    Multivariate version of the Diebold-Mariano test based on the L2 norm of forecast errors. Tests for the significance of the superior unconditional predictive ability of `forecasts` over `benchmark`.
"""
function dieboldmariano(obs::AbstractVecOrMat{<:Real},
            benchmark::AbstractVecOrMat{<:Real}, 
            forecasts::AbstractVecOrMat{<:Real})
    
    n = size(obs, 1)
    @assert n == size(benchmark, 1)
    @assert n == size(forecasts, 1)
    Δ = zeros(n)
    for i in eachindex(Δ)
        Δ[i] = norm(@view(obs[i, :]).-@view(benchmark[i, :]), 2) .- norm(@view(obs[i, :]).-@view(forecasts[i, :]), 2)
    end
    μ = mean(Δ)
    σ = std(Δ)
    return 1-cdf(Normal(0, 1), sqrt(length(Δ))*μ/σ)
end

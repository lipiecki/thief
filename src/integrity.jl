"""
    integrity(;models, market)
Perform data integrity check on a given `market` across specified `models`.
"""
function integrity(;models::AbstractVector{<:AbstractString}, market::AbstractString)
    f = load(joinpath("base-forecasts", "$(models[begin])-$market.jld2"))
    observations, dates = f["observations"], f["dates"]

    for i in eachindex(models)[2:end]
        f = load(joinpath("base-forecasts", "$(models[i])-$market.jld2"))
        all(round.(observations, digits=8) .≈ round.(f["observations"], digits=8)) || error("observations do not match")
        all(dates .≈ f["dates"]) || error("dates do not match")
    end
end

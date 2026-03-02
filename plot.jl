using Plots, JLD2, Measures

let
    mkpath("figures")

    blocks = Int.([1, 2, 3, 4, 6, 8, 12, 24])
    no_block_forecasts = zeros(Int, length(blocks))
    for b in eachindex(blocks)
        no_block_forecasts[b] = Int(24/blocks[b])
    end

    colors = ["#d31f11", "#f47a00", "#62c8d3", "#007191"]
    xlims = Dict("epex" => (-15, 15), "omie" => (-10, 10))
    models = ["arx", "narx", "xgb", "mitra"]
    modelnames = Dict("arx" => "ARX", "narx" => "NARX", "xgb" => "XGB", "mitra" => "Mitra")
    
    plots = Dict()
    for year in [2021, 2022, 2023, 2024]
        results = Dict()
        for model in models
            results[model] = Dict()
            results[model]["base"] = zeros(length(blocks), 2)
            results[model]["thief"] = zeros(length(blocks), 2)
            results[model]["skill-score"] = zeros(length(blocks), 2)
        end
        errors = zeros(2)
        for (m, market) in enumerate(["epex", "omie"])
            for model in models
                f = load(joinpath("results", "$model-$market-LedWol.jld2"))
                observations, forecasts, forecasts_thief, dates =
                    f["observations"], f["forecasts"], f["forecasts_thief"], f["dates"]
                for (ibx, block) in enumerate(blocks)
                    errors .= 0.0
                    start = findfirst(dates .== year*10_000+0101)
                    stop = findfirst(dates .== year*10_000+1231)
                    for t in start:stop
                        bi = 1
                        for b in eachindex(blocks)
                            if blocks[b] == block
                                errors[1] += sum(abs2, forecasts[t, bi:bi+no_block_forecasts[b]-1] .- observations[t, bi:bi+no_block_forecasts[b]-1])/no_block_forecasts[b]
                                errors[2] += sum(abs2, forecasts_thief[t, bi:bi+no_block_forecasts[b]-1] .- observations[t, bi:bi+no_block_forecasts[b]-1])/no_block_forecasts[b]
                            end
                            bi = bi + no_block_forecasts[b]
                        end
                    end
                    results[model]["base"][ibx, m] = sqrt(errors[1]/(stop-start+1))
                    results[model]["thief"][ibx, m] = sqrt(errors[2]/(stop-start+1))
                    results[model]["skill-score"][ibx, m] = 100.0 * (results[model]["base"][ibx, m] - results[model]["thief"][ibx, m]) / results[model]["base"][ibx, m]
                end
            end
        end

        for model in models
            bar((1-0.1:length(blocks)-0.1), results[model]["skill-score"][:, 1]; lw=0, color=colors[4], label="EPEX", bar_width=0.4)
            bar!((1+0.1:length(blocks)+0.1), results[model]["skill-score"][:, 2]; lw=0, color=colors[3], label="OMIE", bar_width=0.4)
            bar!(xticks=(1:length(blocks), ["$(block)" for block in blocks]))

            plot!(
                framestyle=:grid,
                size=(500, 600),
                ylims = (-5, 15.5),
                foreground_color_legend=nothing,
                background_color_legend=nothing,
                legend=false)
            
            if model == "arx"
                if year == 2021
                    plot!(legend=:topleft)
                end
                plot!(ylabel = "Gain (%)")
            else
                plot!(yformatter = x -> "")
            end
            if model == "mitra"
                plot!(ylabel = string(year), yguide_position=:right)
            end
            if year == 2021
                plot!(title=modelnames[model])
            elseif year == 2024
                plot!(xlabel = "Block size (hours)")
            end
            plots[(model, year)] = plot!()
        end
    end
    keys = [
        ("arx", 2021), ("narx", 2021), ("xgb", 2021), ("mitra", 2021),
        ("arx", 2022), ("narx", 2022), ("xgb", 2022), ("mitra", 2022),
        ("arx", 2023), ("narx", 2023), ("xgb", 2023), ("mitra", 2023),
        ("arx", 2024), ("narx", 2024), ("xgb", 2024), ("mitra", 2024),
    ]
    plot([plots[k] for k in keys]..., layout = grid(4,4), size=(1200, 1200), left_margin=[5mm -3mm -3mm -3mm], right_margin=[-3mm -3mm -3mm 5mm])
    plot!(dpi=500)
    savefig("figures/fig4.png")
end
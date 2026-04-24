"""
This script generates the figures from the paper. It should be run with a single argument, which specifies the number of the figure to generate:
```
julia --project plot.jl {X}
```
where {X} is `1`, `2` or `4`.
"""

using Plots, JLD2, Measures, LaTeXStrings, ColorSchemes

function fig1()
    f = load(joinpath("results", "xgb-epex-LedWol.jld2"))
    observations, forecasts, forecasts_thief, dates = 
        permutedims(f["observations"]), permutedims(f["forecasts"]), permutedims(f["forecasts_thief"]), f["dates"]
    
    date = 20210702
    D = 5
    lag = 4
    start = findfirst(dates .== date)-D+1
    stop = findfirst(dates .== date)
    blocks = [1, 4, 8, 24]
    first_index = [1, 24+12+8+1, 24+12+8+6+4+1, 24+12+8+6+4+3+2+1]

    xticks = [
        (0:(24+3), [""; ""; ""; ""; ""; "2"; ""; "4"; ""; "6"; ""; "8"; ""; "10"; ""; "12"; ""; "14"; ""; "16"; ""; "18"; ""; "20"; ""; "22"; ""; "24"]),
        (0:(6+3), [""; ""; ""; ""; "1-4"; "5-8"; "9-12"; "13-16"; "17-20"; "21-24"]),
        (0:(3+3), [""; ""; ""; ""; "1-8"; "9-16"; "17-24"]),
        (0:(1+3), [""; ""; ""; ""; "1-24"])
    ]

    plts = []
    for b in 1:length(blocks)
        plt = plot(xlabelfontsize = 12, ylabelfontsize=12, ytickfontsize=10, xtickfontsize=10)
        B = blocks[b]
        R = Int(24/B)
        r = first_index[b]

        base = zeros(R*D)
        thief = zeros(R*D)
        obs = zeros(R*D)

        for d in 1:D
            base[1+(d-1)*R:d*R] .= forecasts[r:r+R-1, start:stop][:, d]
            thief[1+(d-1)*R:d*R] .= forecasts_thief[r:r+R-1, start:stop][:, d]
            obs[1+(d-1)*R:d*R] .= observations[r:r+R-1, start:stop][:, d]
        end

        base = base[end-R-lag+1:end]
        thief = thief[end-R-lag+1:end]
        obs = obs[end-R-lag+1:end]

        obscolor =  "#023858FF"
        forecolor = "#d31f11"
    
        bar!(plt, (0:R+lag-1)[1:4], obs[1:4], label = nothing, color = :grey, alpha=0.5, bar_width=1, linewidth=0.5, linealpha=1)
        bar!(plt, (0:R+lag-1)[5:end], obs[5:end], label = nothing, color = obscolor, alpha=0.2, bar_width=1, linewidth=0.5, linecolor=:black, linealpha=1)
        plot!(plt, lag:R+lag-1, thief[lag+1:end],label = nothing, lw=2, ls=:dot, color = forecolor)
        plot!(plt, lag:R+lag-1, base[lag+1:end], label = nothing, color=forecolor, lw=2)
        plot!(plt, lag:R+lag-1, thief[lag+1:end], label = "THieF-XGB",  st=:scatter, color=forecolor, markerstrokewidth=0, markersize=9)
        plot!(plt, lag:R+lag-1, base[lag+1:end], label = "Base-XGB", st=:scatter, color = :white, markerstrokecolor=forecolor, markerstrokewidth=1, markersize=9)
        plot!(plt, framestyle=:box, ylims=(65, 125), yticks=(70:10:120), xlabel="$(B)-hour blocks", xticks=xticks[b], xformatter=_->"", legend=:topleft)
        if b == 1 || b == 3
            plot!(plt, ylabel="Price (EUR/MWh)")
        else
            plot!(plt, yformatter=_->"")
        end
        if b != 4
            plot!(plt, legend=false)
        end
        push!(plts, plt)
    end
    plot(plts[1], plts[2], plts[3], plts[4], layout = (2, 2), size=(1200, 600), left_margin=5mm, bottom_margin=5mm)
    plot!(dpi=500)
    savefig(joinpath("figures", "fig1.png"))
end

function fig2()
   blocks = Int.([1, 2, 3, 4, 6, 8, 12, 24])
    no_block_forecasts = zeros(length(blocks))
    for b in eachindex(blocks)
        no_block_forecasts[b] = Int(24/blocks[b])
    end

    B = Int(sum(no_block_forecasts))
    SM = zeros(B, 24)
    SM .= NaN

    bi = 0
    for b in eachindex(blocks)
        for l in 1:no_block_forecasts[b]
            bi += 1
            hours = Int.((l-1)*blocks[b]+1:l*blocks[b])
            for hour in hours
                SM[bi, hour] = length(blocks)+1-b
            end
        end
    end 

    start_color = ColorSchemes.Blues_9[4]
    end_color = ColorSchemes.Blues_9[9]
    n_colors = 8
    colormap = cgrad([start_color, end_color], n_colors, categorical=true)

    heatmap(SM, size=(500, 500*55/24), yflip = false, xflip=true, colorbar=false, categorical=true, cmap=colormap, framestyle=:grid)
    function xformat(x)
        vec = 1:1:24
        if abs(x)%2 == 1
            return string(vec[end-findfirst(vec .== abs(Int(x)))+1])
        else
            return ""
        end
    end

    plot!(xticks=(24:-1:1), x_formatter=xformat, yticks=1:60, tick_direction=:in, y_formatter=_->"", xlabel = "Hour", framestyle=:box, left_margin=10Plots.mm)
    hline!([24.5, 36.5, 44.5, 50.5, 54.5, 57.5, 59.5], lw=1, lc=:grey20, label=nothing, clip=false, grid=false)

    annotate!(26, (1 + 24)/2, text(L"\mathbf{S}_{1}", 14, :center))
    annotate!(2.8, 23.4, text(L"s_{1} = 1", 14, :center))
    annotate!(26, (25 + 36)/2, text(L"\mathbf{S}_{2}", 14, :center))
    annotate!(2.8, 35.4, text(L"s_{2} = \dfrac{1}{2}", 14, :center))
    annotate!(26, (37 + 44)/2, text(L"\mathbf{S}_{3}", 14, :center))
    annotate!(2.8, 43.4, text(L"s_{3} = \dfrac{1}{3}", 14, :center))
    annotate!(26, (45 + 50)/2, text(L"\mathbf{S}_{4}", 14, :center))
    annotate!(2.8, 49.4, text(L"s_{4} = \dfrac{1}{4}", 14, :center))
    annotate!(26, (51 + 54)/2, text(L"\mathbf{S}_{6}", 14, :center))
    annotate!(2.8, 53.4, text(L"s_{6} = \dfrac{1}{6}", 14, :center))
    annotate!(26, (55 + 57)/2, text(L"\mathbf{S}_{8}", 14, :center))
    annotate!(2.8, 56.4, text(L"s_{8} = \dfrac{1}{8}", 14, :center))
    annotate!(26, (58 + 59)/2, text(L"\mathbf{S}_{12}", 14, :center))
    annotate!(26, (60 + 61)/2, text(L"\mathbf{S}_{24}", 14, :center))

    plot!(dpi=500)
    savefig(joinpath("figures", "fig2.png"))
end

function fig4()
    blocks = Int.([1, 2, 3, 4, 6, 8, 12, 24])
    no_block_forecasts = zeros(Int, length(blocks))
    for b in eachindex(blocks)
        no_block_forecasts[b] = Int(24/blocks[b])
    end

    colors = ["#62c8d3", "#007191"]
    models = ["arx", "narx", "xgb", "mitra"]
    modelnames = Dict("arx" => "ARX", "narx" => "NARX", "xgb" => "XGB", "mitra" => "Mitra")
    
    plts = Dict()
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
            bar((1-0.1:length(blocks)-0.1), results[model]["skill-score"][:, 1]; lw=0, color=colors[2], label="EPEX", bar_width=0.4)
            bar!((1+0.1:length(blocks)+0.1), results[model]["skill-score"][:, 2]; lw=0, color=colors[1], label="OMIE", bar_width=0.4)
            bar!(xticks=(1:length(blocks), ["$(block)" for block in blocks]))
            plot!(framestyle=:grid, size=(500, 600), ylims = (-5, 15.5), foreground_color_legend=nothing, background_color_legend=nothing, legend=false)
            if model == "arx"
                if year == 2021
                    plot!(legend=:topleft)
                end
                plot!(ylabel="Gain (%)")
            else
                plot!(yformatter=x -> "")
            end
            if model == "mitra"
                plot!(ylabel=string(year), yguide_position=:right)
            end
            if year == 2021
                plot!(title=modelnames[model])
            elseif year == 2024
                plot!(xlabel="Block size (hours)")
            end
            plts[(model, year)] = plot!()
        end
    end
    keys = [
        ("arx", 2021), ("narx", 2021), ("xgb", 2021), ("mitra", 2021),
        ("arx", 2022), ("narx", 2022), ("xgb", 2022), ("mitra", 2022),
        ("arx", 2023), ("narx", 2023), ("xgb", 2023), ("mitra", 2023),
        ("arx", 2024), ("narx", 2024), ("xgb", 2024), ("mitra", 2024),
    ]
    plot([plts[k] for k in keys]..., layout = grid(4,4), size=(1200, 1200), left_margin=[5mm -3mm -3mm -3mm], right_margin=[-3mm -3mm -3mm 5mm])
    plot!(dpi=500)
    savefig(joinpath("figures", "fig4.png"))
end

mkpath("figures")
fig = parse(Int, ARGS[1])
if fig == 1
    fig1()
elseif fig == 2
    fig2()
elseif fig == 4
    fig4()
else
    error("provided figure number is not valid")
end

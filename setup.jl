using Pkg
Pkg.instantiate()

using HuggingFaceApi
let
    mkpath("base-forecasts")
    for market in ["epex", "omie"]
        for model in ["arx", "narx", "xgb", "mitra"]
            filename = "$model-$market.jld2"
            if !isfile(joinpath("base-forecasts", filename))
                path = hf_hub_download("datasets/lipiecki/thief", "base-forecasts/$model-$market.jld2", cache=false)
                cp(path, joinpath("base-forecasts", "$model-$market.jld2"))
            end
        end
    end
end
# THieF
This repository hosts replication code for the paper *Stealing Accuracy: Predicting Day-ahead Electricity Prices with Temporal Hierarchy Forecasting (THieF)*, A. Lipiecki, K. Bilińska, N. Kourentzes & R. Weron (2025) [arXiv:2508.11372](https://arxiv.org/abs/2508.11372)

## Install Julia
This repository is written in Julia programming language. The recommended way to install Julia is via [juliaup](https://julialang.org/install/).

## Computing environment
The results were obtained in Julia 1.12.4 on a macOS machine running on the Apple M2 Pro chip with 16GM of RAM. The exact versions of all depndencies used for producing the results are included in the `Manifest.toml` file.

## Base forecasts dataset
The dataset of base forecasts required to run the reproducibility package is available at [huggingface.co/datasets/lipiecki/thief](https://huggingface.co/datasets/lipiecki/thief). The dataset is automatically downloaded by the `setup.jl` script.
The dataset consits of 8 files `{model}-{market}.jld2` (`model` $\in$ {`arx`, `mitra`, `narx`, `xgb`}, `market` $\in$ {`epex`, `omie`}). Each file is a HDF5 dataset storing:
- actual day-ahead prices for all 60 hierarchy levels under "observations"
- forecasts of day-ahead prices for all 60 hierarchy levels under "forecasts"
- corresponding dates in the YYYYMMDD format under "dates"
- in-sample forecat errors from each rolling window under "in_sample_errors"

This dataset (https://huggingface.co/datasets/lipiecki/thief) is shared under the CC-BY-ND-4.0 license.

## Structure
- `src`: directory with function definitions used for reconciliation and evaluation
- `base-forecasts`: directory with base forecasts (automatically created by the `setup.jl` script)
- `results`: directory with reconciliation results (automatically created by the `run.jl` script)
- `figures`: directory with plots (automatically created by the `plot.jl` script)
- `setup.jl`: script for instantiating the project and downloading the dataset of base forecasts from [huggingface.co/datasets/lipiecki/thief](https://huggingface.co/datasets/lipiecki/thief)
- `run.jl`: script for forecast reconciliation and evaluation
- `run.jl`: script for reproducing the figures

## Reproducing results

### Setup
Install all the required dependecies and download base forecasts data with:
```
julia --project setup.jl
```

### Tables
After setting up the project, reproduce the main reconciliation results by running:
```
julia --project run.jl LedWol
```
The processed forecasts are saved to the `results` directory. The script then performs evaluation on the testing period between 2021-01-01 and 2024-12-31 and prints the relevant metrics to console. In the above example, the reconciliation is performed with shrinkage estimator by [Ledoit & Wolf (2004)](https://doi.org/10.3905/jpm.2004.110) (Table 1). You can specify other covariance matrix estimators: change the last command-line argument to `SchStr` for the shrinkage by [Schäfer & Strimmer (2005)](https://doi.org/10.2202/1544-6115.1175) (Table A.2), or `WLS` for the variance scaling approach by [Athanasopoulos et al. (2017)](https://doi.org/10.1016/j.ejor.2017.02.046) (Table A.3).

| Output | Script |  Time |
|-----|-----|-----|
| Table 1 |  `julia --project run.jl LedWol` | ~ 60s |
| Table A.2 |  `julia --project run.jl SchStr` | ~ 20s |
| Table A.3 |  `julia --project run.jl WLS` | ~ 10s |

### Plots
After generating the results with `julia --project run.jl LedWol`, you can reproduce the figures with:
```
julia --project plot.jl {X}
```
where {X} is the number of the figure.

| Output | Script |
|-----|-----|
| Figure 1 |  `julia --project plot.jl 1` |
| Figure 2 |  `julia --project plot.jl 2` |
| Figure 4 |  `julia --project plot.jl 4` |

The resulting file will be stored in the `figures` directory. Figure 3 **(market data - prices, loads, wind generation)** is not reproduced in this package as it does not present any **results obtained** and **includes** data that cannot be shared in this repository due to the policy of the provider ([transparency.entsoe.eu](https://transparency.entsoe.eu)).

## Authors and license
The reproducibility package was assembled on 5 Mar 2026 by Arkadiusz Lipiecki. Don't hesitate to contact me at `arkadiusz.lipiecki@pwr.edu.pl` with any questions.

This repository is shared under the MIT license.

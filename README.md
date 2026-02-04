# THieF
This repository hosts replication code for the paper *Stealing Accuracy: Predicting Day-ahead Electricity Prices with Temporal Hierarchy Forecasting (THieF)*, A. Lipiecki, K. Bilińska, N. Kourentzes & R. Weron (2025) [arXiv:2508.11372](https://arxiv.org/abs/2508.11372)

## Install Julia
Don't have Julia on your machine yet? The recommended way to install Julia is via [juliaup](https://julialang.org/install/).

## Install packages and download base forecasts
The base forecasts are available at [huggingface.co/datasets/lipiecki/thief](https://huggingface.co/datasets/lipiecki/thief), run:
```
julia --project setup.jl
```
to install all the required dependecies and download base forecasts data.

## Reconcile and evaluate
After setting up the repo, run:
```
julia --project run.jl 20210101 20241231
```
to perform forecast reconciliation. The processed forecasts are saved to the `results` directory. The script then performs evaluation on the testing period between 2021-01-01 and 2024-12-31 and prints the relevant metrics to console. 

By default the reconciliation is performed with shrinkage estimator by [Ledoit & Wolf (2004)](https://doi.org/10.3905/jpm.2004.110). Provide an additional command-line argument to specify the estimator for the covariance matrix: `SchStr` to use the shrinkage by [Schäfer & Strimmer (2005)](https://doi.org/10.2202/1544-6115.1175), or `WLS` for the variance scaling approach by [Athanasopoulos et al. (2017)](https://doi.org/10.1016/j.ejor.2017.02.046). For example:
```
julia --project run.jl 20210101 20241231 SchStr
```

The source code used for reconicliation and evaluation live in the `src` directory.

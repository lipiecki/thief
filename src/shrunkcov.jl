"""
    shrunkcov!(Σ::Matrix{T}, ε::Matrix{T}; target::Symbol) where T<:AbstractFloat
Compute the covariance matrix of forecat errors `ε` (n by m), where n is the sample size and m is the dimensionality of the time series.
The covariance matrix is estimated using the shrinkage operator specified by `target`. Note that this is an in-place method that sores the output covariance matrix in `Σ`.

`target` takes the following values:
- `:LedWol`: constant correlation shrinkage target proposed by Ledoit & Wolf (2004)
- `:SchStr`: diagonal shrinkage target with correlation-based optimal shrinakge intensity, proposed by Schäfer & Strimmer (2005)
- `:WLS`: diagonal covariance matrix
"""
function shrunkcov!(Σ::Matrix{T}, ε::Matrix{T}; target::Symbol) where T<:AbstractFloat
    n, m = size(ε)
    size(Σ) == (m, m) || error("mismatched dimensions")
    Σ .= zero(T)
    Σ .= transpose(ε)*ε
    Σ ./= n
    
    if target == :LedWol
        shrinkLedWol!(Σ, ε)
    elseif target == :SchStr
        shrinkSchStr!(Σ, ε)
    elseif target == :WLS
        shrinkWLS!(Σ)
    else
        error("unknown shrinkage target $(target)")
    end
    return nothing
end

function shrinkLedWol!(Σ::Matrix{T}, ε::Matrix{T}) where T<:AbstractFloat
    n, m = size(ε)
    F = zeros(T, m, m)
    r = zero(T)
    for i in 1:(m-1)
        for j in i+1:m
            r += (Σ[i, j])/sqrt(Σ[i, i]*Σ[j, j])
        end
    end
    r = 2r/(m*(m-1))
    for i in 1:m
        F[i, i] = Σ[i, i]
        for j in i+1:m
            F[i, j] = r*sqrt(Σ[i, i]*Σ[j, j])
            F[j, i] = F[i, j]
        end
    end
    π̂ = zero(T)
    ρ̂ = zero(T)
    for i in 1:m
        for j in i+1:m
            π̂ += 2*sum(abs2, @view(ε[:, i]).*@view(ε[:, j]) .- Σ[i, j])
            vi = sum((abs2.(@view(ε[:, i])) .- Σ[i, i]).*(@view(ε[:, i]).*@view(ε[:, j]) .- Σ[i, j]))
            vj = sum((abs2.(@view(ε[:, j])) .- Σ[j, j]).*(@view(ε[:, i]).*@view(ε[:, j]) .- Σ[i, j]))
            ρ̂ += r*(sqrt(Σ[j, j]/Σ[i, i])*vi + sqrt(Σ[i, i]/Σ[j, j])*vj)
        end
    end
    π̂ /= n
    ρ̂ /= n
    γ̂ = .0
    for i in 1:m
        γ̂ += abs2(F[i, i] - Σ[i, i])
        for j in i+1:m
            γ̂ += 2*abs2(F[i, j] - Σ[i, j])
        end
    end
    κ = (π̂ - ρ̂)/γ̂
    δ = max(.0, min(κ/n, 1))
    Σ .= δ.*F .+ (1-δ).*Σ
    return nothing
end

function shrinkSchStr!(Σ::Matrix{T}, ε::Matrix{T}) where T<:AbstractFloat
    n, m = size(ε)
    F = zeros(T, m, m)
    for i in 1:m
        F[i, i] = Σ[i, i]
    end
    π̂ = zero(T)
    for i in 1:m
        for j in i+1:m
            π̂ += 2*sum(abs2, (@view(ε[:, i]).*@view(ε[:, j]) .- Σ[i, j])./sqrt(Σ[i, i]*Σ[j, j]))
        end
    end
    π̂ /= n
    γ̂ = zero(T)
    for i in 1:m
        for j in i+1:m
            γ̂ += 2*abs2(Σ[i, j]/sqrt(Σ[i, i]*Σ[j, j]))
        end
    end
    κ = π̂/γ̂
    δ = max(0, min(κ/n, 1))
    Σ .= δ.*F .+ (1-δ).*Σ
    return nothing
end

function shrinkWLS!(Σ::Matrix{T}) where T<:AbstractFloat
    m = size(Σ, 1)
    for i in 1:m
        for j in i+1:m
            Σ[i, j] = zero(T)
            Σ[j, i] = zero(T)
        end
    end
    return nothing
end

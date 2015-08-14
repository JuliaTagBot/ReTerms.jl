"""
`ReTerm` - a random effects term

The term consists of the grouping factor, `f`, the transposed dense model
matrix `z` and the parameterized lower triangular matrix `λ`.  The size
of `λ` must be `size(z,1)`. `size(z,2)` must be `length(f)`.  
"""
type ReTerm{T}
    f::PooledDataVector                 # grouping factor
    z::Matrix{T}
    λ::ParamLowerTriangular{T}
    ## function ReTerm(p::PooledDataVector,z::Matrix{T},λ::ParamLowerTriangular{T})
    ##     length(p) == size(z,2) && size(λ,1) == size(z,1) || throw(DimensionMismatch())
    ##     new(p,z,λ)
    ## end
end

function ReTerm(p::PooledDataVector,z::Matrix)
    length(p) == size(z,2) || throw(DimensionMismatch())
    ReTerm(p,z,ColMajorLowerTriangular(LowerTriangular(eye(eltype(z),size(z,1)))))
end

ReTerm(p::PooledDataVector,v::Vector) = ReTerm(p,v')

ReTerm(p::PooledDataVector) = ReTerm(p,ones(1,length(p)))

ReTerm{T<:Integer}(v::Vector{T}) = ReTerm(compact(pool(v)))

Base.size(A::ReTerm) = (length(A.f),(size(A.z,1)*length(A.f.pool)))

Base.size(A::ReTerm,i::Integer) =
    i < 1 ? throw(BoundsError()) :
    i == 1 ? length(A.f) :
    i == 2 ? (length(A.f.pool)*size(A.z,1)) : 1

function Base.Ac_mul_B!{T}(R::DenseVecOrMat{T},A::ReTerm{T},B::DenseVecOrMat{T})
    n,q = size(A)
    k = size(B,2)
    size(R,1) == q && size(B,1) == n && size(R,2) == k || throw(DimensionMismatch(""))
    fill!(R,zero(T))
    rr = A.f.refs
    zz = A.z
    l = size(zz,1)
    rt = reshape(R,(l,div(q,l),k))
    for j in 1:k, i in 1:n
            Base.axpy!(B[i,j],sub(zz,:,i),sub(rt,:,Int(rr[i]),j))
    end
    R
end

function Base.Ac_mul_B{T}(A::ReTerm{T},B::DenseVecOrMat{T})
    k = size(A,2)
    Ac_mul_B!(Array(Float64, isa(B,Vector) ? (k,) : (k, size(B,2))), A, B)
end

function Base.Ac_mul_B{T}(A::ReTerm{T}, B::ReTerm{T})
    if is(A,B)
        k = size(A.z,1)
        nl = length(A.f.pool)
        crprd = zeros(T,(k,k,nl))
        z = A.z
        rr = A.f.refs
        for i in eachindex(rr)
            BLAS.syr!('L',one(T),sub(z,:,i),sub(crprd,:,:,Int(rr[i])))
        end
        for j in 1:nl
            Base.LinAlg.copytri!(sub(crprd,:,:,j),'L')
        end
        return crprd
    end
    Az = A.z
    k,l = size(Az)
    Bz = B.z
    m,n = size(Bz)
    l == n || throw(DimensionMisMatch())
    (r,s) = promote(A.f.refs,B.f.refs)
    sparse(r,s,[sub(Az,:,i)*sub(Bz,:,i)' for i in 1:n])
end

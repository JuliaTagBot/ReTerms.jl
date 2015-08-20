VERSION >= v"0.4.0-dev+6521" && __precompile__()

module ReTerms

using DataArrays, DataFrames, HDF5, NLopt, StatsBase

export ReMat

export g2dict, lowerbd, objective, reterm

using Base.LinAlg.BlasInt

import Base: ==

include("utils.jl")
include("blockmats.jl")
include("remat.jl")
include("paramlowertriangular.jl")
include("pls.jl")

end # module

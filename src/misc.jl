
# verbose flag
const VERBOSE = Ref(false)

"""
    set_verbose(::Bool)

For debugging - set flag to print macro expansions
"""
function set_verbose(verbose::Bool)
    VERBOSE[] = verbose
end

# some standard methods which were introduced in v1.2
if VERSION < v"1.2.0"
    valtype(::Type{<:AbstractDict{K,V}}) where {K,V} = V
    valtype(::T) where T<:AbstractDict = valtype(T)
    Base.get!(f, d::IdDict, key) = haskey(d, key) ? d[key] : f()
end


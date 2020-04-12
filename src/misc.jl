"""
    Assignable

`Assignable` represents any data type that can be associated with traits.
It essentially covers all data types including parametric types e.g. `AbstractArray`
"""
const Assignable = Union{UnionAll, DataType}


struct SyntaxError <: Exception
    msg
end

# verbose flag

const VERBOSE = Ref(false)

function set_verbose(b::Bool)
    VERBOSE[] = b
end

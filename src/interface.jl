# Inteface implementation

"""
The `Assignable` type represents any data type that can be associated
with traits.  The reason why it includes `UnionAll` is to support
parametric types that are not fully qualified e.g. `AbstractArray`.
"""
const Assignable = Union{UnionAll, DataType}

const TYPE_PLACEHOLDER = "::<Type>"


# Keep track of each module's interfaces in a global variable.
# By module, we can get a list of trait type (<name>Trait)
# By trait, we can get a list of contracts.

"""
The `traits_map` is a two-layer Dict.  First layer is to look up the traits
Dict by module.  The second layer is to look up trait types from a data type.
The trait type is expected to be the abstract type for trait e.g. <T>Trait.
"""
const traits_map = Dict{Module,Dict{Assignable,Set{DataType}}}()

"""
    traits(m::Module, T::Assignable)

Returns a set of trait types that the data type `T` was assigned.
See also [`@assign`](@ref).
"""
function traits(m::Module, T::Assignable)
    trait_dict = get!(traits_map, m, Dict{Assignable,Set{DataType}}())
    return get!(trait_dict, T, Set{DataType}())
end

"""
    assign(m::Module, T::Assignable)

Assign data type `T` with the specified `trait`.
"""
function assign(m::Module, T::Assignable, trait::DataType)
    trait_dict = get!(traits_map, m, Dict{Assignable,Set{DataType}}())
    return get!(trait_dict, T, Set{DataType}([trait]))
end

"""
    Contract

A contract refers to a function defintion `func` that is required to satisfy
a trait type `trait`. The function `func` must accepts `args` and returns `ret`.
"""
struct Contract{T <: DataType, F <: Function, N}
    trait::T
    func::F
    args::NTuple{N, DataType}
    ret::Union{DataType,Nothing}
end

function Base.show(io::IO, c::Contract)
    type = Symbol(TYPE_PLACEHOLDER)
    args = "(" * join([type, c.args...], ", ::") * ")"
    print(io, "$(c.trait) ⇢ $(c.func)$(args)")
    c.ret !== nothing && print(io, "::$(c.ret)")
end

"""
The `interface_map` is a Dict that maps a module to another Dict
that maps a data type to a set of Contracts.
"""
const interface_map = Dict{Module,Dict{DataType,Set{Contract}}}()

"""
    register(m::Module, trait::DataType, func::Function,
             args::NTuple{N,DataType}, ret::DataType)

Register a function `func` with the specified `trait`.
The `func` is expected to take arguments `args` and return
a value of type `ret`.
"""
function register(m::Module,
                  trait::DataType,
                  func::Function,
                  args::NTuple{N,DataType},
                  ret::Union{DataType,Nothing} = nothing) where N
    interface_dict = get!(interface_map, m, Dict{DataType,Set{Contract}}())
    contracts = get!(interface_dict, trait, Set{Contract}())
    push!(contracts, Contract(trait, func, args, ret))
    return nothing
end

"""
    contracts(m::Module, trait::DataType)

Returns a set of Contracts that are required to be implemented
for `trait`.
"""
function contracts(m::Module, trait::DataType)
    interface_dict = get!(interface_map, m, Dict{DataType,Set{Contract}}())
    return get(interface_dict, trait, Set{Contract}())
end

"""
    fully_implemented(m::Module, T::Assignable)

Check if the data type `T` defined in module `m` has fully implemented
all trait functions that it was previously assigned.  See also: [`@assign`](@ref).
"""
function fully_implemented(m::Module, T::Assignable)
    all_good = true
    missing_contracts = Contract[]
    for trait in traits(m, T)
        for c in contracts(m, trait)
            tuple_type = Tuple{T, c.args...}
            method_exists = hasmethod(c.func, tuple_type)
            if !method_exists
                sig = replace("$c", TYPE_PLACEHOLDER => "::$T")
                # @warn "Missing implementation: $sig"
                all_good = false
                push!(missing_contracts, c)
            end
        end
    end
    return (fully_implemented = all_good, missing_contracts = missing_contracts)
end

"""
    @check <Type>

Check whether the data type `T` fully implements all of its
assigned traits.  Return a named tuple with the following attributes:
- `fully_implemented`: Bool
- `missing_contracts`: Contract[]
"""
macro check(T)
    return esc(quote
        BinaryTraits.fully_implemented($__module__, $T)
    end)
end

"""
    @implement <Trait> by <FunctionSignature>

Register function signature for the specified trait.
"""
macro implement(trait, by, sig)

    func_name, func_arg_names, func_arg_types, return_type =
        parse_implement(trait, by, sig)
    # @info "sig" func_name func_arg_names func_arg_types

    # generate code
    name = trait_type_name(trait)
    expr = quote
        function $func_name end
        BinaryTraits.register($__module__, $name, $func_name,
            ($(func_arg_types...),), $return_type)
    end
    display_expanded_code(expr)
    return esc(expr)
end

# Parsing function for @implement macro
function parse_implement(trait, by, sig)
    usage = "Invalid @implement usage."
    if !(trait isa Symbol) || by !== :by || !(sig isa Expr)
        throw(SyntaxError(usage))
    end

    # Is return type specified?
    has_return_type = sig.head == Symbol("::")
    if has_return_type
        return_type = sig.args[2]
        sig = sig.args[1]
    else
        return_type = :Any
    end

    # TODO should we use @assert here?
    @assert sig isa Expr
    @assert sig.head === :call

    # parse signature
    func_name = sig.args[1]   # must be Symbol
    func_arg_names = Symbol[]
    func_arg_types = Symbol[]
    for (idx, x) in enumerate(sig.args[2:end])  # x must be Expr of 1 or 2 symbols
        @assert x isa Expr
        @assert x.head == Symbol("::")
        @assert x.args |> length in [1,2]
        if length(x.args) == 1
            push!(func_arg_names, Symbol("x$idx"))
            push!(func_arg_types, x.args[1])
        else
            push!(func_arg_names, x.args[1])
            push!(func_arg_types, x.args[2])
        end
    end

    return (func_name, func_arg_names, func_arg_types, return_type)
end

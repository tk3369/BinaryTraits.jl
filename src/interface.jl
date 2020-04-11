
"""
The `Assignable` type represents any data type that can be associated
with traits.  For example, a `Duck` type is `Assignable` and so it may be
assigned with traits `CanFly` and `CanSwim`.

The reason why it includes `UnionAll` is to support parametric types that
are not fully qualified e.g. `AbstractArray`.
"""
const Assignable = Union{UnionAll, DataType}

const TYPE_PLACEHOLDER = "::<Type>"

"""
The `traits_map` is a two-layer Dict.  First layer is to map from a module to
data types that have been assigned with traits.  The second layer maps a
data type to the Can-type of the asigned traits.

For example, a user module `ZooKeeper` may define `Duck` and `Dog` types and
then assign them with `Fly` and `Swim` traits.  The map would look like this:

```julia
julia> BinaryTraits.traits_map[ZooKeeper]
Dict{Union{DataType, UnionAll},Set{DataType}} with 2 entries:
  Dog  => Set(DataType[CanSwim])
  Duck => Set(DataType[CanSwim, CanFly])
```
"""
const traits_map = Dict{Module,Dict{Assignable,Set{DataType}}}()

"""
    traits(m::Module, T::Assignable)

Returns a set of Can-types that the data type `T` exhibits.
See also [`@assign`](@ref).
"""
function traits(m::Module, T::Assignable)
    trait_dict = get!(traits_map, m, Dict{Assignable,Set{DataType}}())
    return get!(trait_dict, T, Set{DataType}())
end

"""
    assign(m::Module, T::Assignable, can_type::DataType)

Assign data type `T` with the specified Can-type of a trait.
"""
function assign(m::Module, T::Assignable, can_type::DataType)
    type_dict = get!(traits_map, m, Dict{Assignable,Set{DataType}}())
    traits_set = get!(type_dict, T, Set{DataType}())
    push!(traits_set, can_type)
    return nothing
end

# Managing interface contracts

"""
    Contract

A contract refers to a function defintion `func` that is required to satisfy
the Can-type of a trait. The function `func` must accepts `args` and returns `ret`.
"""
struct Contract{T <: DataType, F <: Function, N}
    can_type::T
    func::F
    args::NTuple{N, DataType}
    ret::Union{DataType,Nothing}
end

function Base.show(io::IO, c::Contract)
    type = Symbol(TYPE_PLACEHOLDER)
    args = "(" * join([type, c.args...], ", ::") * ")"
    print(io, "$(c.can_type) ⇢ $(c.func)$(args)")
    c.ret !== nothing && print(io, "::$(c.ret)")
end

"""
    interface_map

The `interface_map` is a two-layer Dict data structure. It maps
a module to another Dict that maps a data type to a set of Contracts.

For example, a `Duck`
"""
const interface_map = Dict{Module,Dict{DataType,Set{Contract}}}()

"""
    register(m::Module, can_type::DataType, func::Function,
             args::NTuple{N,DataType}, ret::DataType)

Register a function `func` with the specified `can_type` type.
The `func` is expected to take arguments `args` and return
a value of type `ret`.
"""
function register(m::Module,
                  can_type::DataType,
                  func::Function,
                  args::NTuple{N,DataType},
                  ret::Union{DataType,Nothing} = nothing) where N
    interface_dict = get!(interface_map, m, Dict{DataType,Set{Contract}}())
    contracts = get!(interface_dict, can_type, Set{Contract}())
    push!(contracts, Contract(can_type, func, args, ret))
    return nothing
end

"""
    contracts(m::Module, can_type::DataType)

Returns a set of Contracts that are required to be implemented
for `can_type`.
"""
function contracts(m::Module, can_type::DataType)
    interface_dict = get!(interface_map, m, Dict{DataType,Set{Contract}}())
    return get(interface_dict, can_type, Set{Contract}())
end

"""
    InterfaceReview

An InterfaceReview object contains the validation results of
an interface.

Fields:
- `type`: the type being checked
- `result`: true if the type fully implements all required contracts
- `implemented`: an array of implemented contracts
- `misses`: an array of unimplemented contracts
"""
@Base.kwdef struct InterfaceReview
    type::Assignable
    result::Bool
    implemented::Vector{Contract}
    misses::Vector{Contract}
end

function Base.show(io::IO, ir::T) where {T <: InterfaceReview}
    if length(ir.implemented) == length(ir.misses) == 0
        print(io, "$T($(ir.type)) is not associated to any contracts.")
        return nothing
    end
    if ir.result
        println(io, "$T($(ir.type)) has fully implemented these contracts:")
        for (i, c) in enumerate(ir.implemented)
            println(io, "$(i). $c")
        end
    else
        println(io, "$T($(ir.type)) missing the following implementations:")
        for (i, c) in enumerate(ir.misses)
            println(io, "$(i). $c")
        end
    end
end

"""
    fully_implemented(m::Module, T::Assignable)

Check if the data type `T` defined in module `m` has fully implemented
all trait functions that it was previously assigned.  See also: [`@assign`](@ref).
"""
function fully_implemented(m::Module, T::Assignable)
    all_good = true
    implemented_contracts = Contract[]
    missing_contracts = Contract[]
    for can_type in traits(m, T)
        for c in contracts(m, can_type)
            tuple_type = Tuple{T, c.args...}
            method_exists = hasmethod(c.func, tuple_type)
            sig = replace("$c", TYPE_PLACEHOLDER => "::$T")
            if method_exists
                push!(implemented_contracts, c)
            else
                VERBOSE[] && @warn "Missing implementation: $sig" c.func tuple_type
                all_good = false
                push!(missing_contracts, c)
            end
        end
    end
    return InterfaceReview(type = T, result = all_good,
                implemented = implemented_contracts,
                misses = missing_contracts)
end

"""
    @check <T>

Check whether the data type `T` fully implements all of its
assigned traits.  Return an [`InterfaceReview`](@ref) object.
"""
macro check(T)
    return esc(quote
        BinaryTraits.fully_implemented($__module__, $T)
    end)
end

"""
    @implement <CanType> by <FunctionSignature>

Register function signature for the specified `CanType` of a trait.
You can use the [`@check`](@ref) macro to verify your implementation
after these interface contracts are registered.  The function
signature only needs to specify required arguments other than
the object itself.  Also, return type is optional and in that case
it will be ignored by the interface checker.

For examples:
```julia
@implement CanFly by fly(direction::Direction, speed::Float64)
@implement CanFly by has_wings()::Bool
```

The data types that exhibit those `CanFly` traits must implement
the function signature with the addition of an object as first
argument i.e.

```julia
fly(duck::Duck, direction::Direction, speed::Float64)
has_wings(duck::Duck)::Bool
```
"""
macro implement(can_type, by, sig)

    func_name, func_arg_names, func_arg_types, return_type =
        parse_implement(can_type, by, sig)
    # @info "sig" func_name func_arg_names func_arg_types

    # generate code
    expr = quote
        function $func_name end
        BinaryTraits.register($__module__, $can_type, $func_name,
            ($(func_arg_types...),), $return_type)
    end
    display_expanded_code(expr)
    return esc(expr)
end

# Parsing function for @implement macro
function parse_implement(can_type, by, sig)
    usage = "Invalid @implement usage."
    if !(can_type isa Symbol) || by !== :by || !(sig isa Expr)
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

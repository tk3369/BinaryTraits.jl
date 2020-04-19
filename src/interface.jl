# used for display purpose only
const TYPE_PLACEHOLDER = "::<Type>"

"""
    traits_map

The `traits_map` maps a data type to the Can-type of the asigned traits.

For example, the `Duck` and `Dog` types and then assign them with `Fly`
and `Swim` traits.  The map would look like this:

```julia
julia> BinaryTraits.traits_map
Dict{Union{DataType, UnionAll},Set{DataType}} with 2 entries:
  Dog  => Set(DataType[CanSwim])
  Duck => Set(DataType[CanSwim, CanFly])
```
"""
const traits_map = Dict{Assignable,Set{DataType}}()

"""
    traits(T::Assignable)

Returns a set of Can-types that the data type `T` exhibits.
See also [`@assign`](@ref).
"""
function traits(T::Assignable)
    base = get!(traits_map, T) do; Set{DataType}() end
    for (Tmap, s) in pairs(traits_map)
        if T !== Tmap && T <: Tmap
            union!(base, s)
        end
    end
    return base
end

"""
    assign(T::Assignable, can_type::DataType)

Assign data type `T` with the specified Can-type of a trait.
"""
function assign(T::Assignable, can_type::DataType)
    traits_set = get!(traits_map, T) do; Set{DataType}() end
    push!(traits_set, can_type)
    return nothing
end

# Managing interface contracts

"""
    Contract{T <: DataType, F <: Function, N}

A contract refers to a function defintion `func` that is required to satisfy
the Can-type of a trait. The function `func` must accepts `args` and returns `ret`.

# Fields
- `can_type`: can-type of a trait e.g. `CanFly`
- `func`: function that must be implemented to satisfy this trait
- `args`: argument types of the function `func`
- `kwargs`: keyword argument names of the function `func`
- `ret`: return type of the function `func`
"""
struct Contract{T <: DataType, F <: Function}
    can_type::T
    func::F
    args::Tuple
    kwargs::Tuple
    ret::Union{DataType,Nothing}
end

function Base.show(io::IO, c::Contract)
    typ = Symbol(TYPE_PLACEHOLDER)
    args = string("(", join([typ, c.args...], ", ::"))
    if length(c.kwargs) > 0
        args = string(args, "; ", join(c.kwargs, ", "))
    end
    args = string(args, ")")
    trait = supertype(c.can_type)
    print(io, "$(trait): $(c.can_type) ⇢ $(c.func)$(args)")
    c.ret !== nothing && print(io, "::$(c.ret)")
end

"""
    interface_map

The `interface_map` maps a data type to a set of Contracts.
"""
const interface_map = Dict{DataType,Set{Contract}}()

"""
    register(can_type::DataType, func::Function, args::NTuple{N,DataType}, ret::DataType) where N

Register a function `func` with the specified `can_type` type.
The `func` is expected to take arguments `args` and return
a value of type `ret`.
"""
function register(can_type::DataType,
                  func::Function,
                  args::Tuple,
                  kwargs::NTuple{N,Symbol},
                  ret::Union{DataType,Nothing} = nothing) where N
    contracts = get!(interface_map, can_type) do; Set{Contract}() end
    push!(contracts, Contract(can_type, func, args, kwargs, ret))
    return nothing
end

"""
    contracts(can_type::DataType)

Returns a set of Contracts that are required to be implemented
for `can_type`.
"""
function contracts(can_type::DataType)
    current_contracts = get(interface_map, can_type, Set{Contract}())
    if haskey(composite_traits, can_type)
        contracts_array = contracts.(composite_traits[can_type])
        @debug "after recusion" contracts_array
        underlying_contracts = union(contracts_array...)
        @debug "combining" current_contracts underlying_contracts
        return union(current_contracts, underlying_contracts)
    else
        @debug "returning" current_contracts
        return current_contracts
    end
end

"""
    InterfaceReview

An InterfaceReview object contains the validation results of an interface.

# Fields
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

function Base.show(io::IO, ir::InterfaceReview)
    T = InterfaceReview
    irtype = ir.type
    if length(ir.implemented) == length(ir.misses) == 0
        print(io, "✅ $(irtype) has no interface contract requirements.")
    end
    if length(ir.implemented) > 0
        println(io, "✅ $(irtype) has implemented:")
        for (i, c) in enumerate(ir.implemented)
            println(io, "$(i). $c")
        end
    end
    if length(ir.misses) > 0
        println(io, "❌ $(irtype) is missing these implementations:")
        for (i, c) in enumerate(ir.misses)
            println(io, "$(i). $c")
        end
    end
end

"""
    check(T::Assignable)

Check if the data type `T` has fully implemented all trait functions that it was
previously assigned.  See also: [`@assign`](@ref).
"""
function check(T::Assignable)
    all_good = true
    implemented_contracts = Contract[]
    missing_contracts = Contract[]
    for can_type in traits(T)
        for c in contracts(can_type)
            tuple_type = Tuple{T, c.args...}
            method_exists = has_method(c.func, tuple_type, c.kwargs)
            sig = replace("$c", TYPE_PLACEHOLDER => "::$T")
            if method_exists
                push!(implemented_contracts, c)
            else
                @warn "Missing implementation: $sig"
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
    required_contracts(T::Assignable)

Return a set of contracts that is required to be implemented for
the provided type `T`.
"""
function required_contracts(T::Assignable)
    c = [contracts(t) for t in traits(T)]  # returns array of set of contracts
    return union(c...)
end

"""
    @implement <CanType> by <FunctionSignature>

Register function signature for the specified `CanType` of a trait.
You can use the [`check`](@ref) macro to verify your implementation
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

    func_name, func_arg_names, func_arg_types, kwarg_names, return_type =
        parse_implement(can_type, by, sig)
    # @info "sig" func_name func_arg_names func_arg_types
    
    kwtuple = tuple(kwarg_names...)
    # generate code
    expr = quote
        function $func_name end
        BinaryTraits.register($can_type, $func_name,
                              ($(func_arg_types...),), $kwtuple, $return_type)
    end
    display_expanded_code(expr)
    return esc(expr)
end

# Parsing function for @implement macro
function parse_implement(can_type, by, sig)
    usage = "usage: @implement <Type> by <function specification::<ReturnType>"
    can_type isa Symbol && sig isa Expr && by === :by || throw(SyntaxError(usage))

    # Is return type specified?
    if sig.head === Symbol("::") 
        return_type = sig.args[2]
        sig = sig.args[1]
    else
        return_type = :Any
    end

    sig isa Expr && sig.head === :call || throw(SyntaxError(usage))

    # parse signature
    func_name = sig.args[1]   # must be Symbol
    func_arg_names = Symbol[]
    func_arg_types = Any[]
    func_kwarg_names = Symbol[]
    firstarg = 2
    if length(sig.args) >= 2 && sig.args[2] isa Expr && sig.args[2].head == :parameters
        # this is the optional list of keyword arguments
        for x in sig.args[2].args
            push!(func_kwarg_names, extract_name(x, nothing))
        end
        firstarg += 1
    end
    # further arguments after the keyword argument list
    for (idx, x) in enumerate(sig.args[firstarg:end])  # x must be Expr of 1 or 2 symbols
        push!(func_arg_names, extract_name(x, Symbol("x$idx")))
        push!(func_arg_types, extract_type(x, :(Base.Bottom)))
    end

    return (func_name, func_arg_names, func_arg_types, func_kwarg_names, return_type)
end

extract_name(x::Symbol, default) = x
function extract_name(x::Expr, default)
    n = length(x.args)
    if x.head == Symbol("::")
        # form: '<name> :: <type-spec>' or ':: <type-spec>'
        # we accept <name> if present or deliver default name
        n > 1 ? x.args[1] : default
    elseif n >= 1
        # form: <something> <op> <rest>
        # we assume <something> has one of the previous forms - <op> <rest> is ignored
        extract_name(x.args[1], default)
    else
        # all other forms deliver default name
        return default
    end
end

# if only an argument name, deliver the default type
extract_type(::Symbol, default) = default
function extract_type(x::Expr, default)
    n = length(x.args)
    if x.head == Symbol("::")
        # form: '<name> :: <type-spec>' or ':: <type-spec>'
        # we accept <type-spec>
        n > 1 ? x.args[2] : x.args[1]
    elseif n >= 1
        # form: '<something> <op> <rest>'
        # we assume <something> has one of the previous forms
        extract_type(x.args[1], default)
    else
        # all other forms deliver default type
        default
    end
end

"""
    has_method(f, Tuple{argument_types...}, (keyword_argument_names...,))

Check existence of a method with same name as `f`, same number of argument types, each
of which is `>:` to the given `argument_types`, and with all `keyword_argument_names`
supported.

This is an improvement over `Base.hasmethod` as it treats the `Base.Bottom` case correctly.
"""
function has_method(@nospecialize(f), @nospecialize(t), kwnames::Tuple{Vararg{Symbol}}=())
    _hasmethod(f, t, kwnames) && return true # assume hasmethod has no false positives
    t = Base.to_tuple_type(t)
    t = Base.signature_type(f, t)
    for m in methods(f)
        check_method(m, t, kwnames) && return true
    end
    false
end

function _hasmethod(@nospecialize(f), @nospecialize(t), kwnames::Tuple{Vararg{Symbol}}=())
    VERSION >= v"1.2" && !isempty(kwnames) ? hasmethod(f, t, kwnames) : hasmethod(f, t)
end

function check_method(@nospecialize(m::Method), @nospecialize(sig::Type{T}), kwnames::Tuple{Vararg{Symbol}}=tuple()) where T<:Tuple
    ssig = sig.parameters
    n = length(ssig)
    msig = m.sig.parameters
    n != length(msig) && return false
    for i = 1:n
        ssig[i] <: msig[i] || return false
    end
    isempty(kwnames) && return true
    VERSION >= v"1.2" || return false
    par = VERSION >= v"1.4" ? nothing : Core.kwftype(m.sig.parameters[1])
    kws = Base.kwarg_decl(m, par)
    for kw in kws
        endswith(String(kw), "...") && return true
    end
    return issubset(kwnames, kws)
end


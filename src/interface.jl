"""
    register(m::Module, can_type::DataType, func::Function, args::NTuple{N,DataType},
             kwargs::NTuple{N,Symbol}, ret::DataType) where N

Register a function `func` with the specified `can_type` type.
The `func` is expected to take arguments `args` and keyword arguments `kwargs`
and return a value of type `ret`.
"""
function register(m::Module,
                  can_type::DataType,
                  func::Function,
                  args::Tuple,
                  kwargs::NTuple{N,Symbol},
                  ret::Union{DataType,Nothing} = nothing) where N

    push_interface_map!(m, can_type, Contract(can_type, func, args, kwargs, ret))
    return nothing
end

"""
    contracts(module::Module, can_type::DataType)

Returns a set of [`Contracts`](@ref) that are required to be implemented
for objects that exihibits the specific `can_type` trait.
"""
function contracts(m::Module, can_type::DataType)
    current_contracts = get_interface_values(m, can_type)
    subcan_types = get_composite_values(m, can_type)
    if !isempty(subcan_types)
        contracts_array = contracts.(Ref(m), subcan_types)
        underlying_contracts = union(contracts_array...)
        return union(current_contracts, underlying_contracts)
    else
        return current_contracts
    end
end

"""
    @check(T::Assignable)
    check(module::Module, T::Assignable)

Check if the data type `T` has fully implemented all trait functions that it was
previously assigned. See also: [`@assign`](@ref).
"""
macro check(T)
    m = __module__
    esc(:(check($m, $T)))
end
function check(m::Module, T::Assignable)
    all_good = true
    implemented_contracts = Contract[]
    missing_contracts = Contract[]
    for contract in required_contracts(m, T)
        tuple_type = make_tuple_type(T, contract)
        method_exists = has_method(contract.func, tuple_type, contract.kwargs)
        if method_exists
            push!(implemented_contracts, contract)
        else
            @warn "Missing implementation" contract
            all_good = false
            push!(missing_contracts, contract)
        end
    end
    return InterfaceReview(data_type = T,
                           result = all_good,
                           implemented = implemented_contracts,
                           misses = missing_contracts)
end

"""
    make_tuple_type(T::Assignable, c::Contract)

Make a tuple type such that the placeholder (can-type) is replaced
with the type `T` that is being checked.
"""
function make_tuple_type(T::Assignable, c::Contract)
    args = [t == c.can_type ? T : t for t in c.args]
    return Tuple{args...}
end

"""
    required_contracts(module::Module, T::Assignable)

Return a set of contracts that is required to be implemented for
the provided type `T`.
"""
function required_contracts(m::Module, T::Assignable)
    c = [contracts(m, t) for t in traits(m, T)]  # returns array of set of contracts
    return isempty(c) ? valtype(storage().interface_map)() : union(c...)
end

"""
    @implement <CanType> by <FunctionSignature>

Register function signature for the specified `CanType` of a trait.
You can use the [`@check`](@ref) function to verify your implementation
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
    mod = __module__

    # generate code
    expr = quote
        function $func_name end
        BinaryTraits.register($mod, $can_type, $func_name,
                              ($(func_arg_types...),), $kwtuple, $return_type)
    end
    display_expanded_code(expr)
    return esc(expr)
end

# Parsing function for @implement macro
function parse_implement(can_type, by, sig)
    usage = "usage: @implement <Type> by <function specification>[::<ReturnType>]"
    can_type isa Symbol && sig isa Expr && by === :by || throw(SyntaxError(usage))

    # Is return type specified?
    if sig.head === :(::)
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
        push!(func_arg_types, extract_type(x, can_type, :(Base.Bottom)))
    end

    # Check that at least one of the arguments is the can-type
    if findfirst(x -> x === can_type, func_arg_types) === nothing
        throw(SyntaxError("The function signature must have at least 1 underscore."))
    end

    return (func_name, func_arg_names, func_arg_types, func_kwarg_names, return_type)
end

extract_name(x::Symbol, default) = x
function extract_name(x::Expr, default)
    n = length(x.args)
    if x.head == :(::)
        # form: '<name> :: <type-spec>' or ':: <type-spec>'
        # we accept <name> if present or deliver default name
        n > 1 ? x.args[1] : default
    elseif n >= 1 && x.head == :kw
        # form: <something> <op> <rest>
        # we assume <something> has one of the previous forms - <op> <rest> is ignored
        extract_name(x.args[1], default)
    else
        # all other forms deliver default name
        text = "@implement argument is $x but needs syntax: [<name>][::<type>][=<expr>]"
        throw(SyntaxError(text))
    end
end

# If the symbol is an underscore, replace with the can-type.
# Otherwise, just return the default type.
function extract_type(s::Symbol, can_type, default)
    return s === :_ ? can_type : default
end

function extract_type(x::Expr, can_type, default)
    n = length(x.args)
    if x.head == :(::)
        # form: '<name> :: <type-spec>' or ':: <type-spec>'
        # we accept <type-spec>
        n > 1 ? x.args[2] : x.args[1]
    elseif n >= 1 && x.head == :kw
        # form: '<something> = <rest>'
        # we assume <something> has one of the previous forms and ignore rest
        extract_type(x.args[1], can_type, default)
    else
        throw(SyntaxError("@implement")) # will never be called, because extract_name throws
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


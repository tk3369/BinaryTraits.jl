# used for display purpose only
const TYPE_PLACEHOLDER = "::<Type>"
const EMPTY_INTERFACE_MAP = Base.ImmutableDict{DataType,Set{Contract}}()

"Create a new interface map"
make_interface_map() = InterfaceMap()


"Get a reference to the module's interface map."
function get_interface_map(m::Module)
    if isdefined(m, :__binarytraits_interface_map)
        m.__binarytraits_interface_map
    else
        EMPTY_INTERFACE_MAP
    end
end

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
    interface_map = get_interface_map(m)
    contracts = get!(interface_map, can_type) do; Set{Contract}() end
    push!(contracts, Contract(can_type, func, args, kwargs, ret))
    return nothing
end

"""
    contracts(can_type::DataType)

Returns a set of [`Contracts`](@ref) that are required to be implemented
for objects that exihibits the specific `can_type` trait.
"""
function contracts(can_type::DataType)
    m = parentmodule(can_type)
    interface_map = get_interface_map(m)
    composite_traits = get_composite_trait_map(m)
    current_contracts = get(interface_map, can_type) do; Set{Contract}() end
    if haskey(composite_traits, can_type)
        contracts_array = contracts.(composite_traits[can_type])
        underlying_contracts = union(contracts_array...)
        return union(current_contracts, underlying_contracts)
    else
        return current_contracts
    end
end

# Convenience macro so the client does not need to provide module argument
"""
    @check(T::Assignable)

Check if the data type `T` has fully implemented all trait functions that it was
previously assigned.  See also: [`@assign`](@ref).
"""
macro check(T)
    mod = __module__
    return esc(quote
        BinaryTraits.check($T)
    end)
end

function check(T::Assignable)
    m = parentmodule(T)
    all_good = true
    implemented_contracts = Contract[]
    missing_contracts = Contract[]
    for can_type in traits(m, T)
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
    return InterfaceReview(data_type = T, result = all_good,
                implemented = implemented_contracts,
                misses = missing_contracts)
end

"""
    required_contracts(T::Assignable)

Return a set of contracts that is required to be implemented for
the provided type `T`.
"""
function required_contracts(T::Assignable)
    m = parentmodule(T)
    c = [contracts(t) for t in traits(m, T)]  # returns array of set of contracts
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
    mod = __module__

    # generate code
    expr = quote
        function $func_name end

        # Keep copy of interface map in client module
        global __binarytraits_interface_map
        if !@isdefined(__binarytraits_interface_map)
            __binarytraits_interface_map = BinaryTraits.make_interface_map()
        end

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
        push!(func_arg_types, extract_type(x, :(Base.Bottom)))
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

# if only an argument name, deliver the default type
extract_type(::Symbol, default) = default
function extract_type(x::Expr, default)
    n = length(x.args)
    if x.head == :(::)
        # form: '<name> :: <type-spec>' or ':: <type-spec>'
        # we accept <type-spec>
        n > 1 ? x.args[2] : x.args[1]
    elseif n >= 1 && x.head == :kw
        # form: '<something> = <rest>'
        # we assume <something> has one of the previous forms and ignore rest
        extract_type(x.args[1], default)
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


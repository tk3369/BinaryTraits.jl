"""
    istrait(x)

Return `true` if x is a trait type e.g. `FlyTrait` is a trait type when
it is defined by a statement like `@trait Fly`.
"""
istrait(x::DataType) = false

"""
    trait_type_name(t)

Return the name of trait type given a trait `t`.
For example, it would be `FlyTrait` for a `Fly` trait.
The trait is expected to be in TitleCase, but this
function automatically convert the first character to
upper case regardless.
"""
trait_type_name(t) = Symbol(uppercasefirst(string(t)) * "Trait")

"""
    trait_func_name(t)

Return the name of the trait instropectin function given a trait `t`.
For example, it would be `flytrait` for a `Fly` trait.
"""
trait_func_name(t) = Symbol(lowercase(string(t)) * "trait")

function trait_func_name(mod, t)
    sup = supertype(mod.eval(t))
    tn = Symbol(lowercase(string(nameof(sup))))
    modn = fullname(parentmodule(sup))
    foldl((a,b) -> Expr(:(.), a, QuoteNode(b)), (modn..., tn))
end

"""
Check if `x` is an expression of a tuple of symbols.
If `n` is specified then also check whether the tuple
has `n` elements. The `op` argument is used to customize
the check against `n`. Use `>=` or `<=` to check min/max
constraints.
"""
function is_tuple_of_symbols(x; n = nothing, op = isequal)
    x isa Expr &&
    x.head == :tuple &&
    all(x -> x isa Symbol, x.args) &&
    (n === nothing || op(length(x.args), n))
end

"""
    display_expanded_code(expr::Expr)

Display the expanded code from a macro for debugging purpose.
Only works when the verbose flag is set using `set_verbose`.
"""
function display_expanded_code(expr::Expr)
    if VERBOSE[]
        code = MacroTools.postwalk(rmlines, expr)
        @info "Generated code" code
    end
    return nothing
end

# some standard methods which were introduced in v1.2
if VERSION < v"1.2.0"
    valtype(::Type{<:AbstractDict{K,V}}) where {K,V} = V
    valtype(::T) where T<:AbstractDict = valtype(T)
    Base.get!(f, d::IdDict, key) = haskey(d, key) ? d[key] : f()
end

define_const!(mod::Module, name::Symbol, val) = mod.eval( :(const $name = $val) )
define_var!(mod::Module, name::Symbol, val) = mod.eval( :($name = $val) )

# Storage management

const TRAITS_STORAGE = TraitsStorage() # the singleton global storage
storage() = TRAITS_STORAGE

"""
    make_local_storage(module)

Create a temporary variable with a `TraitsStorage` object in given module.
"""
function make_local_storage(mod::Module)
    if !isdefined(mod, :__binarytraits_storage)
        mod.eval( :( const __binarytraits_storage = BinaryTraits.TraitsStorage()) )
    end
    mod.__binarytraits_storage
end

function get_local_storage(mod::Module)
    isdefined(mod, :__binarytraits_storage) ? mod.__binarytraits_storage : nothing
end

"""
    getvalues(module, :table, key)

Get the set of values associated with the `key` in field `table`.
Try first local (module-) table, if key not found use global table
"""
function getvalues(mod::Module, sym::Symbol, key)
    st = get_local_storage(mod)
    if st != nothing
        tab = getproperty(st, sym)
        haskey(tab, key) && return tab[key]
    end
    tab = getproperty(storage(), sym)
    return haskey(tab, key) ? tab[key] : valtype(tab)()
end
get_traits_values(m::Module, key::Assignable) = getvalues(m, :traits_map, key)
get_interface_values(m::Module, key::DataType) = getvalues(m, :interface_map, key)
get_composite_values(m::Module, key::DataType) = getvalues(m, :composite_map, key)

function get_traits_map(mod::Module)
    lst = make_local_storage(mod)
    gst = storage()
    return lst === nothing ? gst.traits_map : merge(union, gst.traits_map, lst.traits_map)
end

"""
    pushdict!(module, :table, key, value)

Insert value into set associated with `key` in the local (module-) `table`.
Create set if not pre-existent.
"""
function pushdict!(mod::Module, sym::Symbol, key, val)
    st = make_local_storage(mod)
    tab = getproperty(st, sym)
    s = get!(valtype(tab), tab, key)
    push_or_union!(s, val)
    return
end
push_traits_map!(m::Module, a::Assignable, val) = pushdict!(m, :traits_map, a, val)
push_interface_map!(m::Module, a::DataType, val) = pushdict!(m, :interface_map, a, val)
push_composite_map!(m::Module, a::DataType, val) = pushdict!(m, :composite_map, a, val)

push_or_union!(s::Set, val) = push!(s, val)
push_or_union!(s::Set, val::Set) = union!(s, val)

"""
    move_to_global!(module)

Move all sets collected in local storage to global storage.
Afterwared the local storage is emty.
"""
function move_to_global!(mod::Module)
    st = get_local_storage(mod)
    if st !== nothing
        for sym in (:traits_map, :interface_map, :composite_map)
            dtab = getproperty(storage(), sym)
            stab = getproperty(st, sym)
            for (key, vset) in stab
                dset = get!(valtype(stab), dtab, key)
                union!(dset, vset)
            end
            empty!(stab)
        end
    end
    return
end

"""
    inittraits(module)

This function should be called like `inittraits(@__MODULE__)` inside the
`__init__()' method of each module using `BinaryTraits`.
"""
function inittraits(mod::Module)
    move_to_global!(mod)
end


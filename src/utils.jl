"""
    is_trait(x)

Return `true` if x is a trait type.
"""
is_trait(x::DataType) = false

"""
Check if `x` is an expression of a tuple of something.
If `n` is specified then also check whether the tuple
has `n` elements. The `op` argument is used to customize
the check against `n`. Use `>=` or `<=` to check min/max
constraints.
"""
function is_tuple_of_something(x, checker; n = nothing, op = isequal)
    return x isa Expr &&
           x.head == :tuple &&
           all(checker, x.args) &&
           (n === nothing || op(length(x.args), n))
end

function is_tuple_of_curly_expressions(x; kwargs...)
    return is_tuple_of_something(x, x -> x isa Expr && x.head == :curly; kwargs...)
end

function is_tuple_of_symbols(x; kwargs...)
    return is_tuple_of_something(x, x -> x isa Symbol; kwargs...)
end

"""
    display_expanded_code(expr::Expr)

Display the expanded code from a macro for debugging purpose.
Only works when the verbose flag is set using `set_verbose!`.
"""
function display_expanded_code(expr::Expr)
    if VERBOSE[]
        code = postwalk(rmlines, expr)
        @info "Generated code" code
    end
    return nothing
end

function define_const!(mod::Module, name::Symbol, val)
    if !isdefined(mod, name)
        mod.eval( :(const $name = $val) )
    else
        mod.eval(name)
    end
end

# Utility to test the depth in the type tree of a given type. Root of the tree has depth 0
function _depth(::Type{T}) where {T}
    if T === Any 
        return 0
    else
        return 1 + _depth(supertype(T))
    end
end

# -----------------------------------------------------------------------------------------
# Storage management
# -----------------------------------------------------------------------------------------

const LOCAL_STORAGE_NAME = :__binarytraits_storage
const TRAITS_STORAGE = TraitsStorage() # the singleton global storage
storage() = TRAITS_STORAGE

"""
    make_local_storage(module::Module)

Create a temporary variable with a `TraitsStorage` object in given module.
"""
function make_local_storage(mod::Module)
    define_const!(mod, LOCAL_STORAGE_NAME, TraitsStorage())
end

function get_local_storage(mod::Module)
    isdefined(mod, LOCAL_STORAGE_NAME) ? mod.__binarytraits_storage : nothing
end

"""
    getvalues(module::Module, sym::Symbol, key)

Get the set of values associated with the `key` in the dictionary
from the storage as identified by `sym` (e.g. `:interface_map`).
Try first local (module-) table, if key not found use global table.
"""
function getvalues(mod::Module, sym::Symbol, key)
    st = get_local_storage(mod)
    if st !== nothing
        tab = getproperty(st, sym)
        haskey(tab, key) && return tab[key]
    end
    tab = getproperty(storage(), sym)
    return haskey(tab, key) ? tab[key] : valtype(tab)()
end
# get_traits_values(m::Module, key::Assignable) = getvalues(m, :traits_map, key)
get_interface_values(m::Module, key::DataType) = getvalues(m, :interface_map, key)
get_composite_values(m::Module, key::DataType) = getvalues(m, :composite_map, key)

function get_traits_map(mod::Module)
    lst = get_local_storage(mod)
    gst = storage()
    return lst === nothing ? gst.traits_map : merge(union, gst.traits_map, lst.traits_map)
end

"""
    pushdict!(module::Module, sym::Symbol, key, value)

Insert value into set associated with `key` in the dictionary as identified
by `sym` (e.g. `:interface_map`) from the local storage.
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

import Base.rehash!

"""
    move_to_global!(module::Module)

Move all sets collected in local storage to global storage.
Afterwareds, the local storage is empty.
"""
function move_to_global!(mod::Module)
    st = get_local_storage(mod)
    rehash!(st)
    if st !== nothing && !isempty(st)
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
    init_traits(module::Module)

This function should be called like `init_traits(@__MODULE__)` inside the
`__init__()' method of each module using `BinaryTraits`.

Alternatively it can be called outside the module this way:
`using Module; init_traits(Module)`, if `Module` missed to call it
within its `__init__` function.

This is required only if the traits/interfaces are expected to be shared
across modules.
"""
function init_traits(mod::Module)
    move_to_global!(mod)
end

function rehash!(st::TraitsStorage)
    rehash!(st.traits_map)
    rehash!(st.interface_map)
    rehash!(st.composite_map)
    return st
end
function Base.isempty(st::TraitsStorage)
    isempty(st.traits_map) &&
    isempty(st.interface_map) &&
    isempty(st.composite_map)
end

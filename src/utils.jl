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


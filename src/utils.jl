"""
    istrait(x)

Return `true` if x is a trait.  This function is expected to be extended by
users for their trait types.  The extension is automatic when the
[`@trait`](@ref) macro is used.
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

"""
    istrait(x)

Return `true` if x is a trait.  This function is expected to be extended by
users for their trait types.  The extension is automatic when the
[`@trait`](@ref) macro is used.
"""
istrait(x::DataType) = false

"""
    @holy <function definition>

Define a function that contains traits arguments.  The macro expands the function
definition using the Holy Traits pattern such that two functions are defined:

1. A dispatch function that uses `trait` function to determine the type of trait args
2. An implementation function that contains trait type arguments in the front of the signature

# Example

```
@holy second(v::Is{Indexable}) = v[2]
```

is expanded to:
```
second(v::T) where T = second(BinaryTraits.trait(Indexable, T), v)
second(::Positive{Indexable}, v::T) where T = v[2]
```
"""
macro holy(ex::Expr)
    mod = __module__
    def = splitdef(ex)

    trait_args = find_trait_args(mod, def[:args])
    length(trait_args) > 0 || error("Unable to find any trait arguments")

    my_arg_names = arg_names(def[:args])
    holy_def = move_trait_args(mod, def, trait_args)

    dfunc = make_dispatch_function(holy_def, trait_args, my_arg_names)
    ifunc = make_implementation_function(holy_def, trait_args)
    expr = quote
        $dfunc
        $ifunc
    end
    display_expanded_code(expr)
    return esc(expr)
end

"""
    make_dispatch_function

Make the dispatch function.  It needs to make `trait` method call and pass keyword arguments
to the implementation function.
"""
function make_dispatch_function(def::AbstractDict, trait_args::AbstractVector, my_arg_names::Vector{Symbol})

    def = copy(def)  # make a copy to avoid side effects

    # Start building the body expression
    body = Expr(:call, def[:name])

    # Add kwargs if needed.
    # Translate orignal form (k1=v1, k2=v2) into (k1=k1, k2=k2) since we're passing
    # to the implementation function.
    if haskey(def, :kwargs)
        kwargs = Any[Expr(:kw, k.args[1], k.args[1]) for k in def[:kwargs]]
        push!(body.args, Expr(:parameters, kwargs...))
    end

    # Make BinaryTraits.trait() method calls
    trait_exprs = [make_trait_expr(nt.type, nt.param) for nt in trait_args]
    append!(body.args, trait_exprs)

    # Append the regular function arguments
    append!(body.args, my_arg_names)

    def[:body] = body
    return combinedef(def)
end

"""
    make_implementation_function

Make the implementation function, which contains trait type args in the front.
"""
function make_implementation_function(def::AbstractDict, trait_args::AbstractVector)
    def = copy(def)  # make a copy to avoid side effects
    arg_exprs = [:(::$(nt.type)) for nt in trait_args]
    prepend!(def[:args], arg_exprs)
    return combinedef(def)
end

"""
    move_trait_args(mod::Module, def::AbstractDict, trait_args::AbstractVector)

Move the trait args to the where-clause.
"""
function move_trait_args(mod::Module, def::AbstractDict, trait_args::AbstractVector)
    # Make a copy so that we don't mess with the original
    def = deepcopy(def)

    # replace trait arg types with parameter names e.g. x::Can{Fly} ==> x::T1
    for nt in trait_args
        arg = def[:args][nt.pos]                # locate arg that needs to be updated
        argpos = length(arg.args) > 1 ? 2 : 1   # x::T or ::T
        arg.args[argpos] = nt.param             # replace RHS with the param
    end

    # add where parameters e.g. where {T1,T2,...}
    if !haskey(def, :whereparams)
        def[:whereparams] = []
    end
    for nt in trait_args
        push!(def[:whereparams], nt.param)
    end

    return def
end

"""
    arg_names(args::AbstractVector)

Return the function argument names.  If name is missing, a default name is
generated.
"""
function arg_names(args::AbstractVector)
    return map(enumerate(args)) do (i, arg)
        if arg isa Symbol
            arg
        elseif arg isa Expr && arg.head == :(::)
            if length(arg.args) > 1
                arg.args[1]
            else
                Symbol("#ARG", i)
            end
        else
            error("Impossible, bug? arg=$arg")
        end
    end
end

"""
    find_trait_args(mod::Module, args::Vector)

Find trait arguments from the provided arguments.
Return an array of named tuples with the `name` and `type`,
and position `pos` of the trait arguments.
"""
function find_trait_args(mod::Module, args::Vector)
    trait_args = NamedTuple{(:name, :type, :pos, :param),Tuple{Symbol,DataType,Int,Symbol}}[]
    for (i, arg) in enumerate(args)
        if arg isa Expr && arg.head == :(::)     # typed argument e.g. x::T, ::T
            if length(arg.args) > 1
                name = arg.args[1]               # extract x from x::T
                type = arg.args[2]               # extract T from x::T
            else
                name = Symbol("#ARG", i)         # derive argument name as ARG<pos>
                type = arg.args[1]               # extract T from ::T
            end
            try
                T = Base.eval(mod, type)         # eval at the user module to find the data type
                if T <: BinaryTrait
                    push!(trait_args, (name = name, type = T, pos = i, param = Symbol("#T", i)))
                end
            catch
                # It could be a user-provided type parameter (e.g. x::S) and S is
                # in the where-clause later.  No need to do anything here since we
                # know it is not a trait arg.
            end
        end
    end
    return trait_args
end

"""
    make_trait_expr

Make an expression that calls `BinaryTraits.trait` function with the specified
trait type `T`.  This expression will be used in a parametric method so a
parameter name is needed.

# Example

```
julia> make_trait_expr(Can{Fly}, :T1)
:(BinaryTraits.trait(Fly, var"#T1"))
```
"""
function make_trait_expr(T::DataType, param::Symbol)
    trait = T.parameters[1]   # extract Fly from Can{Fly}
    return :( BinaryTraits.trait($trait, $param) )
end

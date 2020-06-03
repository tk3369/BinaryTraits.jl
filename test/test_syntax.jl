module Syntax

using BinaryTraits, Test
using BinaryTraits: SyntaxError
using BinaryTraits.Prefix: Can

# This macro expands to testing code that returns true when syntax error
# is detected properly
macro testme(ex)
    esc(quote
            try
                @macroexpand($ex)
                false
            catch e
                # @info "expansion error" e
                e isa LoadError
            end
        end)
end

@trait Eat
@trait Drink
struct Dog end

function test()
    @test @testme @trait Fly as                # missing type
    @test @testme @trait Fly as 1              # 1 is not a type
    @test @testme @trait Fly prefix            # missing prefix tuple
    @test @testme @trait Fly prefix 1,2        # wrong type
    @test @testme @trait Fly prefix Is         # needs two symbols
    @test @testme @trait Fly prefix Is,Not,Ha  # needs two symbols
    @test @testme @trait Fly with Can{Eat}     # must have at least 2 sub pos/neg trait type
    @test @testme @trait Fly with Can{Eat},Can{Drink},1  # 1 is not a pos/neg trait type

    @test @testme @assign Dog with 1           # 1 is not a pos/neg trait type

    @test @testme @implement Can{Creep} by creep2(_, []) # invalid argument
    @test @testme @implement Can{Creep} by creep3()      # no underscore
end

end # module

using Test
@testset "Syntax Checks" begin
    import .Syntax
    Syntax.test()
end

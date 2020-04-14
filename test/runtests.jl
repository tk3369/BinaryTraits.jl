using Test
module SingleTrait
    using BinaryTraits, Test
    struct Bird end
    @trait Fly
    @assign Bird with Fly

    function test()
        @testset "Single Trait" begin
            @test istrait(FlyTrait) == true
            @test istrait(Int) == false
            @test supertype(FlyTrait) === Any
            @test supertype(CanFly) <: FlyTrait
            @test supertype(CannotFly) <: FlyTrait
            @test flytrait(Bird()) == CanFly()
        end
    end
end

module MultipleTraits
    using BinaryTraits, Test
    struct Duck end
    struct Dog end
    @trait Fly
    @trait Swim
    @assign Duck with Fly,Swim
    @assign Dog with Swim
    function test()
        @testset "Multiple Traits" begin
            @test flytrait(Dog()) == CannotFly()
            @test swimtrait(Dog()) == CanSwim()
            @test flytrait(Duck()) == CanFly()
            @test swimtrait(Duck()) == CanSwim()
        end
    end
end

module TraitSuperType
    using BinaryTraits, Test
    struct Duck end
    abstract type Mobility end
    @trait Fly as Mobility
    function test()
        @testset "Super Type" begin
            @test supertype(FlyTrait) <: Mobility
        end
    end
end

module CustomPrefixes
    using BinaryTraits, Test
    @trait Iterable prefix Is,Not
    @assign AbstractArray with Iterable
    next(x) = next(iterabletrait(x), x)
    next(::IsIterable, x) = iterate(x)
    next(::NotIterable, x) = :toobad
    function test()
        @testset "Custom Prefix" begin
            @test next([1,2,3]) !== nothing
            @test next(:hello) === :toobad
        end
    end
end

module CompositeTraits
    using BinaryTraits, Test

    # possible traits
    @trait Move
    @trait CarryPassenger
    @trait FourWheels prefix Has,No
    @trait Engine prefix Has,No

    # assignments
    struct Acura end
    @assign Acura with Move,CarryPassenger,FourWheels,Engine
    struct Tricycle end
    @assign Tricycle with Move,CarryPassenger

    # composite
    @trait Car prefix Is,Not with Move,CarryPassenger,FourWheels,Engine

    function test()
        @testset "Composite" begin
            @test cartrait(Acura()) == IsCar()
            @test cartrait(Tricycle()) == NotCar()
        end
    end
end

module SyntaxErrors
    using BinaryTraits, Test
    using BinaryTraits: SyntaxError

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
        @testset "Syntax" begin
            @test @testme @trait Fly as                # missing type
            @test @testme @trait Fly as 1              # 1 is not a type
            @test @testme @trait Fly prefix            # missing prefix tuple
            @test @testme @trait Fly prefix 1,2        # wrong type
            @test @testme @trait Fly prefix Is         # needs two symbols
            @test @testme @trait Fly prefix Is,Not,Ha  # needs two symbols
            @test @testme @trait Fly with Eat          # must have at least 2 sub-traits
            @test @testme @trait Fly with Eat,Drink,1  # 1 is not a symbol

            @test @testme @assign Dog with 1           # 1 is not a symbol
        end
    end
end

module Interfaces
    using BinaryTraits, Test

    # Fly trait requires multiple contracts with variety of func signatures
    @trait Fly
    @implement CanFly by liftoff()
    @implement CanFly by speed(resistence::Float64)::Float64
    @implement CanFly by flyto(::Float64, ::Float64)::String  # fly to (x,y)

    # Pretty trait requires a single contract
    @trait Pretty prefix Is,Not
    @implement IsPretty by look_at_the_mirror_daily()::Bool

    # Bird satisfies all contracts from FlyTrait by concrete type
    struct Bird end
    @assign Bird with Fly
    liftoff(::Bird) = "hi ho!"
    speed(::Bird, resistence::Float64) = 100 - resistence
    flyto(::Bird, x::Float64, y::Float64) = "Arrvied at ($x, $y)"

    # Duck satisfies partial contracts from FlyTrait by concrete type
    struct Duck end
    @assign Duck with Fly
    liftoff(::Duck) = "hi ho!"

    # Chicken does not satisfy any contract from FlyTrait
    struct Chicken end
    @assign Chicken with Fly

    # Flamingo exhibits both Fly and Pretty traits
    struct Flamingo end
    @assign Flamingo with Fly,Pretty  # composite trait
    liftoff(::Flamingo) = "wee!"
    speed(::Flamingo, resistence::Float64) = 150 - resistence
    flyto(::Flamingo, x::Float64, y::Float64) = "Arrvied at ($x, $y)"
    look_at_the_mirror_daily(::Flamingo) = true

    # Test composite traits - total underlying 4 contracts required for this!
    @trait FlyPretty prefix Is,Not with Fly,Pretty

    # Crane partially satisfies FlyTrait and fully satisfies Pretty trait
    struct Crane end
    @assign Crane with FlyPretty
    speed(::Crane, resistence::Float64) = 150 - resistence
    flyto(::Crane, x::Float64, y::Float64) = "Arrvied at ($x, $y)"
    look_at_the_mirror_daily(::Crane) = true

    struct Penguin end
    @trait Dive
    @assign Penguin with Dive
    @implement CanDive by dive1(::Integer)           # missing argument name
    @implement CanDive by dive2(::Vector{<:Integer}) # parameterized type
    if VERSION >= v"1.2"
    @implement CanDive by dive31(x::Real;)            # keyword arguments
    @implement CanDive by dive32(x::Real; kw::Real)   # keyword arguments
    @implement CanDive by dive33(x::Real; kw1::Real, kw2) # keyword arguments
    end
    @implement CanDive by dive4(::Base.Bottom)
    @implement CanDive by dive5(::Base.Bottom)
    @implement CanDive by dive6(x)              # default type is Base.Bottom

    dive1(::Penguin, ::Real) = 1                # Real >: Integer
    dive2(::Penguin, ::Vector) = 2              # Vector >: Vector{<:Integer}
    dive31(::Penguin, ::Number) = 31            # no kw argument
    dive32(::Penguin, ::Number; kw::Complex) = 32 # kw argument type is ignored!
    dive33(::Penguin, ::Number; kw...) = 33     # any number of kw arguments
    dive4(::Penguin, ::Integer) = 4             # Integer >: Base.Bottom
    dive5(::Penguin, ::Int) = 5                 # Int is not recognized as >: Bottom !
    dive6(::Penguin, ::AbstractFloat) = 6       # AbstractFloat >: Base.Bottom

    function test()
        @testset "Interface validation" begin

            bird_check = check(Bird)
            @test bird_check.result == true
            @test bird_check.implemented |> length == 3
            @test bird_check.misses |> length == 0

            chicken_check = check(Chicken)
            @test chicken_check.result == false
            @test chicken_check.implemented |> length == 0
            @test chicken_check.misses |> length == 3

            duck_check = check(Duck)
            @test duck_check.result == false
            @test duck_check.implemented |> length == 1
            @test duck_check.misses |> length == 2

            flamingo_check = check(Flamingo)
            @test flamingo_check.result == true
            @test flamingo_check.implemented |> length == 4
            @test flamingo_check.misses |> length == 0

            crane_check = check(Crane)
            @test crane_check.result == false
            @test crane_check.implemented |> length == 3
            @test crane_check.misses |> length == 1

            penguin_check = check(Penguin)
            @test penguin_check.result == false
            @test penguin_check.implemented |> length == (VERSION >= v"1.2" ? 7 : 4)
            @test penguin_check.misses |> length == 1

            # test `show` function
            buf = IOBuffer()
            contains(s) = x -> occursin(s, x)

            show(buf, flamingo_check)
            @test buf |> take! |> String |> contains("has implemented")

            show(buf, bird_check)
            @test buf |> take! |> String |> contains("has implemented")

            show(buf, duck_check)
            @test buf |> take! |> String |> contains("is missing")

            # Bird is assigned with 1 FlyTrait and that requires 3 contracts
            @test required_contracts(Bird) |> length == 3

            # Crane requires 4 contracts because it has both Fly and Pretty traits
            @test required_contracts(Crane) |> length == 4

            # Penguin is unexpectedly missing dive5
            show(buf, penguin_check.misses)
            @test buf |> take! |> String |> contains("dive5")
        end
    end
end

module Verbose
    using BinaryTraits, Test, Logging

    # Capture output and make sure that `expected` appears in the log
    # when expression `ex` is evaluated
    macro testme(expected, ex)
        esc(quote
            buf = IOBuffer()
            with_logger(ConsoleLogger(buf)) do
                @macroexpand($ex)
            end
            s = String(take!(buf))
            @test occursin($expected, s)
        end)
    end

    struct Cat end

    # Testing verbose mode
    function test()
        BinaryTraits.set_verbose(true)
        @testset "Verbose" begin
            @testme "struct CanScratch" @trait Scratch
            @testme "scratchtrait(::Cat) = CanScratch()" @assign Cat with Scratch
        end
    end
end

@testset "BinaryTraits Tests" begin
    import .SingleTrait;        SingleTrait.test()
    import .MultipleTraits;     MultipleTraits.test()
    import .TraitSuperType;     TraitSuperType.test()
    import .CustomPrefixes;     CustomPrefixes.test()
    import .CompositeTraits;    CompositeTraits.test()
    import .SyntaxErrors;       SyntaxErrors.test()
    import .Interfaces;         Interfaces.test()
    import .Verbose;            Verbose.test()
end

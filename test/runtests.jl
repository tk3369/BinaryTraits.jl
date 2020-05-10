using Test
module SingleTrait
    using BinaryTraits, Test
    struct Bird end

    @test check(SingleTrait, Bird).result == true # everything ok without traits defined

    @trait Fly
    @assign Bird with FlyTrait

    function test()
        @testset "Single Trait" begin
            # @test istrait(FlyTrait) == true
            # @test istrait(Int) == false
            @test supertype(FlyTrait) === Any
            # @test supertype(CanFly) <: FlyTrait
            # @test supertype(CannotFly) <: FlyTrait
            @test flytrait(Bird()) == Can{FlyTrait}()
        end
    end
end

module MultipleTraits
    using BinaryTraits, Test
    struct Duck end
    struct Dog end
    @trait Fly
    @trait Swim
    @assign Duck with FlyTrait, SwimTrait
    @assign Dog with SwimTrait
    function test()
        @testset "Multiple Traits" begin
            @test flytrait(Dog()) isa Cannot{FlyTrait}
            @test swimtrait(Dog()) isa Can{SwimTrait}
            @test flytrait(Duck()) isa Can{FlyTrait}
            @test swimtrait(Duck()) isa Can{SwimTrait}
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
    @assign AbstractArray with IterableTrait
    next(x) = next(iterabletrait(x), x)
    next(::Is{IterableTrait}, x) = iterate(x)
    next(::Not{IterableTrait}, x) = :toobad
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
    @assign Acura with CanMove, CanCarryPassenger, HasFourWheels, HasEngine
    struct Tricycle end
    @assign Tricycle with CanMove, CanCarryPassenger

    # composite
    @trait Car prefix Is,Not with CanMove, CanCarryPassenger, HasFourWheels, HasEngine

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

            @test @testme @implement CanCreep by creep2(_, []) # invalid argument
            @test @testme @implement CanCreep by creep3()      # no underscore
        end
    end
end

module Interfaces
    using BinaryTraits, Test
    using BinaryTraits: SyntaxError, extract_type

    const SUPPORT_KWARGS = VERSION >= v"1.2"
    const mod = @__MODULE__

    struct Bird end
    # Fly trait requires multiple contracts with variety of func signatures
    @trait Fly
    @assign Bird with CanFly
    bird_check = @check(Bird)
    @test bird_check.result == true # everything ok without interface contracts

    @implement CanFly by liftoff(_)
    @implement CanFly by speed(_, resistence::Float64)::Float64
    @implement CanFly by flyto(::Float64, ::Float64, _)::String  # fly to (x,y)

    # Pretty trait requires a single contract
    @trait Pretty prefix Is,Not
    @implement IsPretty by look_at_the_mirror_daily(_)::Bool

    # Bird satisfies all contracts from FlyTrait by concrete type
    liftoff(::Bird) = "hi ho!"
    speed(::Bird, resistence::Float64) = 100 - resistence
    flyto(x::Float64, y::Float64, ::Bird) = "Arrvied at ($x, $y)"

    # Duck satisfies partial contracts from FlyTrait by concrete type
    struct Duck end
    @assign Duck with CanFly
    liftoff(::Duck) = "hi ho!"

    # Chicken does not satisfy any contract from FlyTrait
    struct Chicken end
    @assign Chicken with CanFly

    # Flamingo exhibits both Fly and Pretty traits
    struct Flamingo end
    @assign Flamingo with CanFly, IsPretty  # composite trait
    liftoff(::Flamingo) = "wee!"
    speed(::Flamingo, resistence::Float64) = 150 - resistence
    flyto(x::Float64, y::Float64, ::Flamingo) = "Arrvied at ($x, $y)"
    look_at_the_mirror_daily(::Flamingo) = true

    # Test composite traits - total underlying 4 contracts required for this!
    @trait FlyPretty prefix Is,Not with CanFly, IsPretty

    # Crane partially satisfies FlyTrait and fully satisfies Pretty trait
    struct Crane end
    @assign Crane with IsFlyPretty
    speed(::Crane, resistence::Float64) = 150 - resistence
    flyto(x::Float64, y::Float64, ::Crane) = "Arrvied at ($x, $y)"
    look_at_the_mirror_daily(::Crane) = true

    struct Penguin end
    @trait Dive
    @assign Penguin with CanDive
    @implement CanDive by dive1(_, ::Integer)           # no argument name
    @implement CanDive by dive2(_, ::Vector{<:Integer}) # parameterized type
    if SUPPORT_KWARGS
        @implement CanDive by dive31(_, x::Real;)            # keyword arguments
        @implement CanDive by dive32(_, x::Real; kw::Real)   # keyword arguments
        @implement CanDive by dive33(_, y; kw1::Real, kw2)   # keyword arguments
        @implement CanDive by dive34(_, x; kw1)
    end
    @implement CanDive by dive4(_, ::Base.Bottom)
    @implement CanDive by dive5(_, x)
    @implement CanDive by dive6(_, ::Number)

    dive1(::Penguin, ::Real) = 1                # Real >: Integer
    dive2(::Penguin, ::Vector) = 2              # Vector >: Vector{<:Integer}
    dive31(::Penguin, ::Number) = 31            # no kw argument
    dive32(::Penguin, ::Number; kw::Complex) = 32 # kw argument type is ignored!
    dive33(::Penguin, ::Int; kw...) = 33        # any number of kw arguments
    dive34(::Penguin, ::Float64) = 34           # keyword argument missing
    dive4(::Penguin, ::Integer) = 4             # Integer >: Base.Bottom
    dive5(::Penguin, ::Int) = 5                 # Int >: Bottom
    dive6(::Penguin, ::Int) = 6                 # not Int >: Number

    # Issue #30 - propagate interfaces according to type inheritance
    abstract type Animal end
    struct Rabbit <: Animal end
    @trait Eat
    @assign Animal with CanEat
    @implement CanEat by eat(_)
    eat(::Animal) = 1

    # no contract requirements (code coverage)
    struct Kiwi end

    # weird argument types in contract specs
    @trait Creep
    @implement CanCreep by creep1(_, a::Int=5) # argument assignment

    struct Snake end
    @assign Snake with CanCreep
    creep1(::Snake, ::Integer) = 1

    @trait PlayNice
    @implement CanPlayNice by play(_,_)
    struct Dog end
    struct Cat end
    play(::Dog, ::Dog) = 1
    play(::Cat, ::Dog) = 2
    @assign Dog with CanPlayNice
    @assign Cat with CanPlayNice

    function test()
        @testset "Interface validation" begin

            bird_check = @check(Bird)
            @test bird_check.result == true
            @test bird_check.implemented |> length == 3
            @test bird_check.misses |> length == 0

            chicken_check = @check(Chicken)
            @test chicken_check.result == false
            @test chicken_check.implemented |> length == 0
            @test chicken_check.misses |> length == 3

            duck_check = @check(Duck)
            @test duck_check.result == false
            @test duck_check.implemented |> length == 1
            @test duck_check.misses |> length == 2

            flamingo_check = @check(Flamingo)
            @test flamingo_check.result == true
            @test flamingo_check.implemented |> length == 4
            @test flamingo_check.misses |> length == 0

            crane_check = @check(Crane)
            @test crane_check.result == false
            @test crane_check.implemented |> length == 3
            @test crane_check.misses |> length == 1

            penguin_check = @check(Penguin)
            @test penguin_check.result == false
            @test penguin_check.implemented |> length == (SUPPORT_KWARGS ? 7 : 4)
            @test penguin_check.misses |> length == (SUPPORT_KWARGS ? 2 : 1)

            rabbit_check = @check(Rabbit)
            @test rabbit_check.result == true

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
            @test required_contracts(mod, Bird) |> length == 3

            # Crane requires 4 contracts because it has both Fly and Pretty traits
            @test required_contracts(mod, Crane) |> length == 4

            # Penguin
            if SUPPORT_KWARGS
                show(buf, penguin_check.misses)
                @test buf |> take! |> String |> contains("dive34")
            end
            show(buf, penguin_check.misses)
            @test buf |> take! |> String |> contains("dive6")

            # has no interface requirements
            check_kiwi = @check(Kiwi)
            @test check_kiwi.result
            show(buf, check_kiwi)
            @test buf |> take! |> String |> contains("has no interface contract")

            # strange argument types are both accepted
            check_snake = @check(Snake)
            @test check_snake.result
            @test check_snake.implemented |> length == 1

            # Multiple underscores in the contract
            check_dog = @check(Dog)
            check_cat = @check(Cat)
            @test check_dog.result === true    # Dog plays nice with Dog
            @test check_cat.result === false   # Cat does not play nice with Cat

            # code coverage
            @test_throws SyntaxError extract_type(:([]), :(CanFly), nothing)

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

    @trait Scratch
    struct Cat end

    # Testing verbose mode
    function test()
        BinaryTraits.set_verbose(true)
        @testset "Verbose" begin
            @testme "struct CanScratch" @trait Scratch
            @testme "scratchtrait(::Cat) = CanScratch()" @assign Cat with CanScratch
        end
    end
end

module CrossModule
    using Test, Logging, BinaryTraits
    module X
        using BinaryTraits
        @trait RowTable prefix Is,Not
        @implement IsRowTable by row(_, ::Integer)
        __init__() = inittraits(@__MODULE__)
    end

    module Y
        using Test
        using BinaryTraits
        using ..X
        struct AwesomeTable end
        @assign AwesomeTable with X.IsRowTable
        r = @check(AwesomeTable)
        @test r.implemented |> length == 0
        X.row(::AwesomeTable, ::Number) = 1
        __init__() = inittraits(@__MODULE__)
    end

    function test()
        @testset "cross-module implementation" begin
            r = @check(Y.AwesomeTable)
            @test r.implemented |> length == 1
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
    import .CrossModule;        CrossModule.test()
end

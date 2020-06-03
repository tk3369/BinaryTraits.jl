module Interfaces

using BinaryTraits
using BinaryTraits: SyntaxError, extract_type
using BinaryTraits.Prefix: Can, Is, Has
using Test

const SUPPORT_KWARGS = VERSION >= v"1.2"
const mod = @__MODULE__

struct Bird end

# Fly trait requires multiple contracts with variety of func signatures
@trait Fly
@assign Bird with Can{Fly}
bird_check = @check(Bird)
@test bird_check.result == true # everything ok without interface contracts

@implement Can{Fly} by liftoff(_)
@implement Can{Fly} by speed(_, resistence::Float64)::Float64
@implement Can{Fly} by flyto(::Float64, ::Float64, _)::String  # fly to (x,y)

# Pretty trait requires a single contract
@trait Pretty
@implement Is{Pretty} by look_at_the_mirror_daily(_)::Bool

# Bird satisfies all contracts from Fly trait by concrete type
liftoff(::Bird) = "hi ho!"
speed(::Bird, resistence::Float64) = 100 - resistence
flyto(x::Float64, y::Float64, ::Bird) = "Arrvied at ($x, $y)"

# Duck satisfies partial contracts from Fly trait by concrete type
struct Duck end
@assign Duck with Can{Fly}
liftoff(::Duck) = "hi ho!"

# Chicken does not satisfy any contract from Fly trait
struct Chicken end
@assign Chicken with Can{Fly}

# Flamingo exhibits both Fly and Pretty traits
struct Flamingo end
@assign Flamingo with Can{Fly}, Is{Pretty}  # composite trait
liftoff(::Flamingo) = "wee!"
speed(::Flamingo, resistence::Float64) = 150 - resistence
flyto(x::Float64, y::Float64, ::Flamingo) = "Arrvied at ($x, $y)"
look_at_the_mirror_daily(::Flamingo) = true

# Test composite traits - total underlying 4 contracts required for this!
@trait FlyPretty with Can{Fly}, Is{Pretty}

# Crane partially satisfies Fly trait and fully satisfies Pretty trait
struct Crane end
@assign Crane with Is{FlyPretty}
speed(::Crane, resistence::Float64) = 150 - resistence
flyto(x::Float64, y::Float64, ::Crane) = "Arrvied at ($x, $y)"
look_at_the_mirror_daily(::Crane) = true

struct Penguin end
@trait Dive
@assign Penguin with Can{Dive}
@implement Can{Dive} by dive1(_, ::Integer)           # no argument name
@implement Can{Dive} by dive2(_, ::Vector{<:Integer}) # parameterized type
if SUPPORT_KWARGS
    @implement Can{Dive} by dive31(_, x::Real;)            # keyword arguments
    @implement Can{Dive} by dive32(_, x::Real; kw::Real)   # keyword arguments
    @implement Can{Dive} by dive33(_, y; kw1::Real, kw2)   # keyword arguments
    @implement Can{Dive} by dive34(_, x; kw1)
end
@implement Can{Dive} by dive4(_, ::Base.Bottom)
@implement Can{Dive} by dive5(_, x)
@implement Can{Dive} by dive6(_, ::Number)

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
@assign Animal with Can{Eat}
@implement Can{Eat} by eat(_)
eat(::Animal) = 1

# no contract requirements (code coverage)
struct Kiwi end

# weird argument types in contract specs
@trait Creep
@implement Can{Creep} by creep1(_, a::Int=5) # argument assignment

struct Snake end
@assign Snake with Can{Creep}
creep1(::Snake, ::Integer) = 1

@trait PlayNice
@implement Can{PlayNice} by play(_,_)
struct Dog end
struct Cat end
play(::Dog, ::Dog) = 1
play(::Cat, ::Dog) = 2
@assign Dog with Can{PlayNice}
@assign Cat with Can{PlayNice}

# ------------------------------------------------------------------------
# interface method return type check

# 1. good case
struct HummingBird end
@assign HummingBird with Can{Fly}
liftoff(::HummingBird) = "woo hoo!"                   # good, because the contract didn't specify return type
speed(::HummingBird, ::Float64) = 64.0                # good, because contract says Float64
flyto(::Float64, ::Float64, ::HummingBird) = "Paris"  # good, because contract says String

function test_hummingbird_return_type()
    result = @check(HummingBird)
    @show result
    @test result.result == true
    @test result.implemented |> length == 3
    @test result.misses |> length == 0
end

# 2. bad case
struct Hawk end
@assign Hawk with Can{Fly}
liftoff(::Hawk) = "woo hoo!"                   # good, because the contract didn't specify return type
speed(::Hawk, ::Float64) = 64                  # bad, because contract says Float64 but we're returning Int
flyto(::Float64, ::Float64, ::Hawk) = "Paris"  # good, because contract says String

function test_hawk_return_type()
    result = @check(Hawk)
    @test result.result == false
    @test result.implemented |> length == 2
    @test result.misses |> length == 1
    @test result.miss_reasons[1] == "Improper return type"
end

# 3. abstract return type
@trait Wings
@implement Has{Wings} by nwings(_)::Integer

struct Pigeon end
@assign Pigeon with Has{Wings}
nwings(::Pigeon) = 2

struct Parrot end
@assign Parrot with Has{Wings}
nwings(::Parrot) = UInt8(2)

function test_abstract_return_type()
    for animal in (Pigeon, Parrot)
        result = @check(animal)
        @test result.result == true
        @test result.misses |> length == 0
    end
end

# ------------------------------------------------------------------------

function test()

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

    # Bird is assigned with 1 Fly trait and that requires 3 contracts
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
    @test_throws SyntaxError extract_type(:([]), :(Can{Fly}), nothing)
end

end # module

using Test
@testset "Interface validation" begin
    import .Interfaces
    Interfaces.test()
    Interfaces.test_hummingbird_return_type()
    Interfaces.test_hawk_return_type()
    Interfaces.test_abstract_return_type()
end

# BinaryTraits.jl

[![Dev Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://tk3369.github.io/BinaryTraits.jl/dev)
[![Travis Build Status](https://travis-ci.org/tk3369/BinaryTraits.jl.svg?branch=master)](https://travis-ci.org/tk3369/BinaryTraits.jl)
[![codecov.io](http://codecov.io/github/tk3369/BinaryTraits.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/BinaryTraits.jl?branch=master)

*NOTE: This package is quite functional already but still experimental in the
sense that more breaking changes are expected.  Follow the
[issues list](https://github.com/tk3369/BinaryTraits.jl/issues)
if you are interested in the ongoing progress.*

BinaryTraits.jl focuses on usability - traits should be simple to understand and easy to use.
For that reason, it is designed to be an *opinionated* library and follows certain conventions.

The underlying mechanism is just Holy Traits as explained in my
[Holy Traits book excerpt](https://ahsmart.com/pub/holy-traits-design-patterns-and-best-practice-book.html)
as well as in Julia manual's
[trait-based dispatch section](https://docs.julialang.org/en/v1/manual/methods/#Trait-based-dispatch-1).
If you think about Holy Traits as the powerful manual transmission, then BinaryTraits.jl
gives you automatic transmission.  The machinery is the same but it is a lot more pleasant
to use.

## Motivation

Just a quick example below.  More details can be found
in our [documentation](https://tk3369.github.io/BinaryTraits.jl/dev).

```julia
# Define a trait and its interface contracts
@trait Fly
@implement CanFly by fly(_, destination::Location, speed::Float64)

# Define your data type and implementation
struct Bird end
fly(::Bird, destination::Location, speed::Float64) = "Wohoo! Arrived! 🐦"

# Assign your data type to a trait
@assign Bird with CanFly

# Verify that your implementation is correct
@check(Bird)
```

## Main Features

The following features have already been implemented.  Additional features are planned
and logged as [issues in this repo](https://github.com/tk3369/BinaryTraits.jl/issues).

* Define traits and assigning them to your own data types
* Define composite traits that exhibits all of the underlying traits
* Define interface contracts required for a trait
* Verify if your data type fully implements all interface contracts
* Allow traits and assigned-to data types are located in different modules

## Credits

* [Klaus Crusius](https://github.com/KlausC) for his ideas and significant contributions to this project

## Related Projects

There are quite a few traits libraries around.  If this package isn't for
you, take a look at these others:

* [Traits.jl](https://github.com/schlichtanders/Traits.jl)
* [SimpleTraits.jl](https://github.com/mauro3/SimpleTraits.jl)
* [TraitWrappers.jl](https://github.com/xiaodaigh/TraitWrappers.jl)


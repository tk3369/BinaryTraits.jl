# BinaryTraits.jl

[![Dev Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://tk3369.github.io/BinaryTraits.jl/dev)
[![Travis Build Status](https://travis-ci.org/tk3369/BinaryTraits.jl.svg?branch=master)](https://travis-ci.org/tk3369/BinaryTraits.jl)
[![codecov.io](http://codecov.io/github/tk3369/BinaryTraits.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/BinaryTraits.jl?branch=master)


BinaryTraits is yet another traits library for Julia.  This package focuses on
usability - traits should be simple to understand and easy to use.  For that reason,
it is designed to be an *opinionated* library, and it follows certain conventions.

The underlying mechanism is just Holy Traits as explained in my
[Holy Traits book excerpt](https://ahsmart.com/pub/holy-traits-design-patterns-and-best-practice-book.html)
as well as in Julia manual's
[trait-based dispatch secion](https://docs.julialang.org/en/v1/manual/methods/#Trait-based-dispatch-1).
If you think about Holy Traits as the powerful manual transmission, then BinaryTraits
is like automatic transmission.  The machinery is the same but it is a lot more pleasant
to use for casual users.

A design consideration is to support only binary traits, hence the name of the package.
Every trait is defined as whether you can do something or not.  I believe enforcing this
restriction makes everything simpler and easier to understand.

## Features

* Define traits and assigning them to your own data types
* Define composite traits that exhibits all of the underlying traits
* Define interface contracts for a trait
* Check if your data type fully implements all interface contracts

## Related Projects

There are quite a few traits libraries around.  If this package isn't for
you, take a look at these others:

* [Traits.jl](https://github.com/schlichtanders/Traits.jl)
* [TraitWrappers.jl](https://github.com/xiaodaigh/TraitWrappers.jl)
* [SimpleTraits.jl](https://github.com/mauro3/SimpleTraits.jl)

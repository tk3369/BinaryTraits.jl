# BinaryTraits.jl

[![Dev Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://tk3369.github.io/BinaryTraits.jl/dev)
[![Travis Build Status](https://travis-ci.org/tk3369/BinaryTraits.jl.svg?branch=master)](https://travis-ci.org/tk3369/BinaryTraits.jl)
[![codecov.io](http://codecov.io/github/tk3369/BinaryTraits.jl/coverage.svg?branch=master)](http://codecov.io/github/tk3369/BinaryTraits.jl?branch=master)


BinaryTraits is yet another traits library for Julia.  This package focuses on usability - traits should be simple to understand and easy to use.  For that reason, it is designed to be an *opinionated* library, so it follows certain conventions.

The underlying mechanism is just [Holy Traits](https://ahsmart.com/pub/holy-traits-design-patterns-and-best-practice-book.html).  If you think about Holy Traits as the powerful manual transmission, then BinaryTraits is like automatic transmission.  The machinery is the same but it is a lot more pleasant to use for casual users.

A design consideration is to support only binary traits, hence the name of the package.  Every trait is defined as whether you can do something or not.  I believe enforcing this restriction makes everything simpler and easier to understand.

## Features

* Define traits and assigning them to your own data types
* Define composite traits that exhibits all of the underlying traits
* Define interface contracts for a trait
* Check if your data type fully implements all interface contracts

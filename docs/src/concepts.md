## Traits

Shen a trait is defined, several data types are automatically declared.
The parent type always has `Trait` append to the end of the trait's
name.  The subtypes include the so-called *can-trait type* and
*cannot-trait type*.  You may realize this is a common type hierarchy
structure used by the Holy Traits pattern.

Let's take a look at an example:

![](assets/concept_fly_trait.png)

## Interface Contracts

It should be a common practice to associate a can-trait type with
a set of interface contracts.  So any
data type that exhibits the trait should define those functions.

![](assets/concept_fly_contracts.png)

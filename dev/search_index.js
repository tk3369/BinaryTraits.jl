var documenterSearchIndex = {"docs":
[{"location":"guide/#Defining-traits-1","page":"User Guide","title":"Defining traits","text":"","category":"section"},{"location":"guide/#The-@trait-macro-1","page":"User Guide","title":"The @trait macro","text":"","category":"section"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"You can define a new trait using the @trait macro. The syntax is described below:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"@trait <Trait> [as <Category>] [prefix <Can>,<Cannot>] [with <Trait1>,<Trait2>,...]","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"A trait type <Trait>Trait will be automatically defined\n<Can> and <Cannot> are words that indicates whether a data type exhibits the trait.\n<Trait1>, <Trait2>, etc. are used to define composite traits.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"The as-clause, prefix-clause, and with-clause are all optional.","category":"page"},{"location":"guide/#Specifying-super-type-for-trait-1","page":"User Guide","title":"Specifying super-type for trait","text":"","category":"section"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"The as-clause is used to specify the super-type of the trait type. If the clause is missing, the super-type is defaulted to Any. This may be useful when you want to group a set of traits under the same hierarchy.  For example:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"abstract type Ability end\n@trait Fly as Ability\n@trait Swim as Ability","category":"page"},{"location":"guide/#Using-custom-prefixes-1","page":"User Guide","title":"Using custom prefixes","text":"","category":"section"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"When you define a trait using verbs like Fly or Swim in the above, it makes sense to define trait types with Can and Cannot prefixes.  But, what if you want to define a trait using a noun or an adjective? In that case, you can define your trait with the prefix-clause. For example:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"@trait Iterable prefix Is,Not","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"In this case, the following types will be defined instead:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"IsIterable\nNotIterable","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"This should make your code a lot more readable.","category":"page"},{"location":"guide/#Making-composite-traits-1","page":"User Guide","title":"Making composite traits","text":"","category":"section"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"Sometimes we really want to compose traits and use a single one directly for dispatch.  In that case, we can just use the with-clause like this:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"@trait FlySwim with CanFly,CanSwim","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"This above syntax would define a new trait where it assumes the sub-traits Fly and Swim.  Then, we can just apply the Holy Trait pattern as usual:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"spank(x) = spank(flyswimtrait(x), x)\nspank(::CanFlySwim, x) = \"Flying high and diving deep\"\nspank(::CannotFlySwim, x) = \"Too Bad\"","category":"page"},{"location":"guide/#Assigning-traits-to-types-1","page":"User Guide","title":"Assigning traits to types","text":"","category":"section"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"Once you define your favorite traits, you may assign any data type to any traits. The syntax of the assignment is as follows:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"@assign <DataType> with <CanTraitType1>,<CanTraitType2>,...","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"You can assign a data type with 1 or more can-trait types in a single statement:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"struct Crane end\n@assign Crane with CanFly,CanSwim","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"Doing that is pretty much equivalent to defining these functions:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"flytrait(::Crane) = CanFly()\nswimtrait(::Crane) = CanSwim()","category":"page"},{"location":"guide/#Specifying-interfaces-1","page":"User Guide","title":"Specifying interfaces","text":"","category":"section"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"A useful feature of traits is to define formal interfaces.  Currently, Julia does not come with any facility to specify interface contracts.  The users are expected to look up interface definitions from documentations and make sure that they implement those contracts per documentation.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"This package provides additional machinery for users to formally define interfaces. It also comes with a macro for verifying the validity of data type implementations.","category":"page"},{"location":"guide/#Formal-interface-contracts-1","page":"User Guide","title":"Formal interface contracts","text":"","category":"section"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"Once you have defined a trait, you may define a set of interface contracts that a data type must implement in order to carry that trait.  These contracts are registered in the BinaryTraits system using the @implement macro. The syntax of @implement is as follows:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"@implement <CanType> by <FunctionSignature>","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"The value of <CanType> is the positive side of a trait e.g. CanFly, IsIterable, etc.  The <FunctionSignature> is basically a standard function signature.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"The followings are all valid usages:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"@implement CanFly by liftoff(_)\n@implement CanFly by fly(_, direction::Float64, altitude::Float64)\n@implement CanFly by speed(_)::Float64","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"When return type is not specified, it is default to Any. Return type is currently not validated so it could be used here just for documentation purpose.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"The underscore _ is a special syntax where you can indicate which positional argument you want to pass an object to the function.  The object is expected to have a type that is assigned to the Fly trait.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"note: Note\nThe underscore may be placed at any argument position although it is quite common to leave it as the first argument.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"note: Note\nIf you have multiple underscores, then the semantic is such that they are all of the same type.  For example, two ducks may exhibits a Playful trait and a play(_, _) interface expects an implementation of play(::Duck, ::Duck).","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"It is also possible to use the negative part of the trait e.g. CannotFly for interface specification.","category":"page"},{"location":"guide/#Implementing-interface-contracts-1","page":"User Guide","title":"Implementing interface contracts","text":"","category":"section"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"A data type that is assigned to a trait should implement all interface contracts. From the previous section, we established three contracts for the Fly trait - liftoff, fly, and speed. To satisfy those contracts, we must implement those functions.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"For example, let's say we are defining a Bird type that exhibits Fly trait, we can implement the following contracts:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"abstract type Animal end\nstruct Bird <: Animal end\n@assign Bird with CanFly\n\n# implmementation of CanFly contracts\nliftoff(bird::Bird) = \"Hoo hoo!\"\nfly(bird::Bird, direction::Float64, altitude::Float64) = \"Getting there!\"\nspeed(bird::Bird) = 10.0","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"Here, we implement the contracts directly with the specific concrete type. What if you have multiple types that satisfy the same trait. Holy Trait comes to rescue:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"liftoff(x::Animal) = liftoff(flytrait(x), x)\nliftoff(::CanFly, x) = \"Hi ho!\"\nliftoff(::CannotFly, x) = \"Hi ho!\"","category":"page"},{"location":"guide/#Validating-a-type-against-its-interfaces-1","page":"User Guide","title":"Validating a type against its interfaces","text":"","category":"section"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"The reason for spending so much effort in specifying interface contracts is so that we have a high confidence about our code.  Julia is a dynamic system and so generally speaking we do not have any static type checking in place. BinaryTraits now gives you that capability.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"The @check macro can be used to verify whether your data type has fully implemented its assigned traits and respective interface contracts.  The usage is embarrassingly simple.  You can just call the @check macro with the data type:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"julia> @check(Bird)\n✅ Bird has no interface contract requirements.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"The @check macro returns an InterfaceReview object, which gives you the validation result.  The warnings are generated so that it comes up in the log file. The string representation of the InterfaceReview object is designed to clearly show you what has been implemented and what's not.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"note: Note\nWhen you define composite traits, all contracts from the underlying traits must be implemented as well.  If you have a FlySwim trait, then all contracts specified for CanFly and CanSwim are required even though you have not added any new contracts for CanFlySwim.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"note: Note\nOne way to utilize the @check macro is to put that in your module's __init__ function so that it is verified before the package is used.  Another option is to do that in your test suite and so it will be run every single time.","category":"page"},{"location":"guide/#Notes-for-framework-providers-1","page":"User Guide","title":"Notes for framework providers","text":"","category":"section"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"BinaryTraits is designed to allow one module to define traits and interfaces and have other modules implementing them.  For example, it should be possible for Tables.jl to define traits for row tables and column tables and required interface functions, and have all of its integrations participate in the same traits system.","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"In order to facilitate interaction between modules, BinaryTraits requires the framework provider (e.g. Tables.jl in the example above) to add the following code in its __init__ function:","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"function __init__()\n    inittraits(@__MODULE__)\nend","category":"page"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"This additional steps allows all packages that utilize BinaryTraits to register their traits and interface contracts at a central location.","category":"page"},{"location":"guide/#Summary-1","page":"User Guide","title":"Summary","text":"","category":"section"},{"location":"guide/#","page":"User Guide","title":"User Guide","text":"The ability to design software with traits and interfaces and the ability to verify software for conformance to established interface contracts are highly desirable for professional software development projects. BinaryTraits is designed to fill the language gap as related to the lack of a formal traits and interface system.","category":"page"},{"location":"concepts/#Traits-1","page":"Concepts","title":"Traits","text":"","category":"section"},{"location":"concepts/#","page":"Concepts","title":"Concepts","text":"Shen a trait is defined, several data types are automatically declared. The parent type always has Trait append to the end of the trait's name.  The subtypes include the so-called can-trait type and cannot-trait type.  You may realize this is a common type hierarchy structure used by the Holy Traits pattern.","category":"page"},{"location":"concepts/#","page":"Concepts","title":"Concepts","text":"Let's take a look at an example:","category":"page"},{"location":"concepts/#","page":"Concepts","title":"Concepts","text":"(Image: )","category":"page"},{"location":"concepts/#Interface-Contracts-1","page":"Concepts","title":"Interface Contracts","text":"","category":"section"},{"location":"concepts/#","page":"Concepts","title":"Concepts","text":"It should be a common practice to associate a can-trait type with a set of interface contracts.  So any data type that exhibits the trait should define those functions.","category":"page"},{"location":"concepts/#","page":"Concepts","title":"Concepts","text":"(Image: )","category":"page"},{"location":"design/#Basic-machinery-1","page":"Under the hood","title":"Basic machinery","text":"","category":"section"},{"location":"design/#","page":"Under the hood","title":"Under the hood","text":"The machinery is extremely simple. When you define a traits like @trait Fly as Ability, it literally expands to the following code:","category":"page"},{"location":"design/#","page":"Under the hood","title":"Under the hood","text":"abstract type FlyTrait <: Ability end\nstruct CanFly <: FlyTrait end\nstruct CannotFly <: FlyTrait end\nflytrait(x) = CannotFly()","category":"page"},{"location":"design/#","page":"Under the hood","title":"Under the hood","text":"As you can see, a new abstract type called  FlyTrait is automatically generated Likewise, we define CanFly and CannotFly subtypes.  Finally, we define a default trait function flytrait that just returns an instance of CannotFly.  Hence, all data types are automatically defined from the trait by default.","category":"page"},{"location":"design/#","page":"Under the hood","title":"Under the hood","text":"Now, when you do @assign Duck with CanFly,CanSwim, it is just translated to:","category":"page"},{"location":"design/#","page":"Under the hood","title":"Under the hood","text":"flytrait(::Duck) = CanFly()\nswimtrait(::Duck) = CanSwim()","category":"page"},{"location":"design/#Composite-traits-1","page":"Under the hood","title":"Composite traits","text":"","category":"section"},{"location":"design/#","page":"Under the hood","title":"Under the hood","text":"Making composite traits is slightly more interesting.  It creates a new trait by combining multiple traits together.  Having a composite trait is defined as one that exhibits all of the underlying traits.  Hence, @trait FlySwim as Ability with CanFly,CanSwim would be translated to the following:","category":"page"},{"location":"design/#","page":"Under the hood","title":"Under the hood","text":"abstract type FlySwimTrait <: Ability end\nstruct CanFlySwim <: FlySwimTrait end\nstruct CannotFlySwim <: FlySwimTrait end\n\nfunction flyswimtrait(x)\n    if flytrait(x) === CanFly() && swimtrait(x) === CanSwim()\n        CanFlySwim()\n    else\n        CannotFlySwim()\n    end\nend","category":"page"},{"location":"design/#Turning-on-verbose-mode-1","page":"Under the hood","title":"Turning on verbose mode","text":"","category":"section"},{"location":"design/#","page":"Under the hood","title":"Under the hood","text":"If you feel this package is a little too magical, don't worry.  To make things more transparent, you can turn on verbose mode.  All macro expansions are then displayed automatically.","category":"page"},{"location":"design/#","page":"Under the hood","title":"Under the hood","text":"julia> BinaryTraits.set_verbose(true)\ntrue\n\njulia> @trait Iterable prefix Is,Not\n┌ Info: Generated code\n│   code =\n│    quote\n│        abstract type IterableTrait <: Any end\n│        struct IsIterable <: IterableTrait\n│        end\n│        struct NotIterable <: IterableTrait\n│        end\n│        iterabletrait(x::Any) = begin\n│                NotIterable()\n│            end\n│        BinaryTraits.istrait(::Type{IterableTrait}) = begin\n│                true\n│            end\n│        nothing\n└    end","category":"page"},{"location":"reference/#","page":"Reference","title":"Reference","text":"This page contains the most important macros, functions, and types that you should be aware of.","category":"page"},{"location":"reference/#Macros-1","page":"Reference","title":"Macros","text":"","category":"section"},{"location":"reference/#","page":"Reference","title":"Reference","text":"@trait\n@assign\n@implement\n@check","category":"page"},{"location":"reference/#BinaryTraits.@trait","page":"Reference","title":"BinaryTraits.@trait","text":"@trait <name> [as <category>] [prefix <positive>,<negative>] [with <trait1,trait2,...>]\n\nCreate a new trait type for name called $(name)Trait:\n\nIf the as clause is provided, then category (an abstract type) will be used as the super type of the trait type.\nIf the prefix clause is provided, then it allows the user to choose different prefixes than the default ones (Can and Cannot) e.g. prefix Is,Not or prefix Has,Not.\nIf the with clause is provided, then it defines a composite trait from existing traits.\n\nNote that you must specify at least 2 traits to make a composite trait.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#BinaryTraits.@assign","page":"Reference","title":"BinaryTraits.@assign","text":"@assign <T> with <CanTrait1, CanTrait2, ...>\n\nAssign traits to the data type T.  For example:\n\n@assign Duck with CanFly,CanSwim\n\nis translated to something like:\n\nflytrait(::Duck) = CanFly()\nswimtrait(::Duck) = CanSwim()\n\nwhere x is the name of the trait X in all lowercase, and T is the type being assigned with the trait X.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#BinaryTraits.@implement","page":"Reference","title":"BinaryTraits.@implement","text":"@implement <CanType> by <FunctionSignature>\n\nRegister function signature for the specified CanType of a trait. You can use the @check function to verify your implementation after these interface contracts are registered.  The function signature only needs to specify required arguments other than the object itself.  Also, return type is optional and in that case it will be ignored by the interface checker.\n\nFor examples:\n\n@implement CanFly by fly(_, direction::Direction, speed::Float64)\n@implement CanFly by has_wings()::Bool\n\nThe data types that exhibit those CanFly traits must implement the function signature with the addition of an object as first argument i.e.\n\nfly(duck::Duck, direction::Direction, speed::Float64)\nhas_wings(duck::Duck)::Bool\n\n\n\n\n\n","category":"macro"},{"location":"reference/#BinaryTraits.@check","page":"Reference","title":"BinaryTraits.@check","text":"@check(T::Assignable)\ncheck(module::Module, T::Assignable)\n\nCheck if the data type T has fully implemented all trait functions that it was previously assigned. See also: @assign.\n\n\n\n\n\n","category":"macro"},{"location":"reference/#Functions-1","page":"Reference","title":"Functions","text":"","category":"section"},{"location":"reference/#","page":"Reference","title":"Reference","text":"traits\nistrait\nrequired_contracts\ninittraits","category":"page"},{"location":"reference/#BinaryTraits.traits","page":"Reference","title":"BinaryTraits.traits","text":"traits(m::Module, T::Assignable)\n\nReturns a set of Can-types that the data type T exhibits.  Look through the composite traits and return the union of all Can-types as such. See also @assign.\n\n\n\n\n\n","category":"function"},{"location":"reference/#BinaryTraits.istrait","page":"Reference","title":"BinaryTraits.istrait","text":"istrait(x)\n\nReturn true if x is a trait type e.g. FlyTrait is a trait type when it is defined by a statement like @trait Fly.\n\n\n\n\n\n","category":"function"},{"location":"reference/#BinaryTraits.required_contracts","page":"Reference","title":"BinaryTraits.required_contracts","text":"required_contracts(module::Module, T::Assignable)\n\nReturn a set of contracts that is required to be implemented for the provided type T.\n\n\n\n\n\n","category":"function"},{"location":"reference/#BinaryTraits.inittraits","page":"Reference","title":"BinaryTraits.inittraits","text":"inittraits(module::Module)\n\nThis function should be called like inittraits(@__MODULE__) inside the __init__()' method of each module usingBinaryTraits`.\n\nAlternatively it can be called outside the module this way: using Module; inittraits(Module), if Module missed to call it within its __init__ function.\n\nThis is required only if the traits/interfaces are expected to be shared across modules.\n\n\n\n\n\n","category":"function"},{"location":"reference/#Types-1","page":"Reference","title":"Types","text":"","category":"section"},{"location":"reference/#","page":"Reference","title":"Reference","text":"BinaryTraits.Assignable\nBinaryTraits.Contract\nBinaryTraits.InterfaceReview","category":"page"},{"location":"reference/#BinaryTraits.Assignable","page":"Reference","title":"BinaryTraits.Assignable","text":"Assignable\n\nAssignable represents any data type that can be associated with traits. It essentially covers all data types including parametric types e.g. AbstractArray\n\n\n\n\n\n","category":"constant"},{"location":"reference/#BinaryTraits.Contract","page":"Reference","title":"BinaryTraits.Contract","text":"Contract{T <: DataType, F <: Function, N}\n\nA contract refers to a function defintion func that is required to satisfy the Can-type of a trait. The function func must accepts args and returns ret.\n\nFields\n\ncan_type: can-type of a trait e.g. CanFly\nfunc: function that must be implemented to satisfy this trait\nargs: argument types of the function func\nkwargs: keyword argument names of the function func\nret: return type of the function func\n\n\n\n\n\n","category":"type"},{"location":"reference/#BinaryTraits.InterfaceReview","page":"Reference","title":"BinaryTraits.InterfaceReview","text":"InterfaceReview\n\nAn InterfaceReview object contains the validation results of an interface.\n\nFields\n\ndata_type: the type being checked\nresult: true if the type fully implements all required contracts\nimplemented: an array of implemented contracts\nmisses: an array of unimplemented contracts\n\n\n\n\n\n","category":"type"},{"location":"#","page":"Motivation","title":"Motivation","text":"BinaryTraits.jl project is located at https://github.com/tk3369/BinaryTraits.jl.","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"Every motivation starts with an example.  In this page, we cover the following tasks:","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"Defining traits\nAssigning data types with traits\nSpecifying an interface for traits\nChecking if a data type fully implements all contracts from its traits\nApplying Holy Traits pattern","category":"page"},{"location":"#Example:-tickling-a-duck-and-a-dog-1","page":"Motivation","title":"Example: tickling a duck and a dog","text":"","category":"section"},{"location":"#","page":"Motivation","title":"Motivation","text":"Suppose that we are modeling the ability of animals.  So we can define traits as follows:","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"using BinaryTraits\nabstract type Ability end\n@trait Swim as Ability\n@trait Fly as Ability","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"Consider the following animal types. We can assign them traits quite easily:","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"struct Dog end\nstruct Duck end\n@assign Dog with CanSwim\n@assign Duck with CanSwim,CanFly","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"Next, how do you dispatch by traits?  Just follow the Holy Trait pattern:","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"tickle(x) = tickle(flytrait(x), swimtrait(x), x)\ntickle(::CanFly, ::CanSwim, x) = \"Flying high and diving deep\"\ntickle(::CanFly, ::CannotSwim, x) = \"Flying away\"\ntickle(::Ability, ::Ability, x) = \"Stuck laughing\"","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"Voila!","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"julia> tickle(Dog())\n\"Stuck laughing\"\n\njulia> tickle(Duck())\n\"Flying high and diving deep\"","category":"page"},{"location":"#Working-with-interfaces-1","page":"Motivation","title":"Working with interfaces","text":"","category":"section"},{"location":"#","page":"Motivation","title":"Motivation","text":"What if we want to enforce an interface? e.g. animals that can fly must implement a fly method.  We can define that interface as follows:","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"@implement CanFly by fly(_, direction::Float64, altitude::Float64)","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"The underscore character is used to indicate how an object should be passed to the fly function.","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"Then, to make sure that our implementation is correct, we can use the @check macro as shown below:","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"julia> @check(Duck)\n┌ Warning: Missing implementation\n│   contract = FlyTrait: CanFly ⇢ fly(🔹, ::Float64, ::Float64)::Any\n└ @ BinaryTraits ~/.julia/dev/BinaryTraits.jl/src/interface.jl:59\n❌ Duck is missing these implementations:\n1. FlyTrait: CanFly ⇢ fly(🔹, ::Float64, ::Float64)::Any","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"Now, let's implement the method and check again:","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"julia> fly(duck::Duck, direction::Float64, altitude::Float64) = \"Having fun!\"\n\njulia> @check(Duck)\n✅ Duck has implemented:\n1. FlyTrait: CanFly ⇢ fly(🔹, ::Float64, ::Float64)::Any","category":"page"},{"location":"#Applying-Holy-Traits-1","page":"Motivation","title":"Applying Holy Traits","text":"","category":"section"},{"location":"#","page":"Motivation","title":"Motivation","text":"If we would just implement interface contracts directly on concrete types then it can be too specific for what it is worth.  If we have 100 flying animals, we shouldn't need to define 100 interface methods for the 100 concrete types.","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"That's how Holy Traits pattern kicks in.  Rather than implementing the fly method for Duck as shown in the previous section, we could have implemented the following functions instead:","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"fly(x, direction::Float64, altitude::Float64) = fly(flytrait(x), x, direction, altitude)\nfly(::CanFly, x, direction::Float64, altitude::Float64) = \"Having fun!\"\nfly(::CannotFly, x, direction::Float64, altitude::Float64) = \"Too bad...\"","category":"page"},{"location":"#","page":"Motivation","title":"Motivation","text":"The first function determines whether the object exhibits CanFly or CannotFly trait and dispatch to the proper function. We did not specify the type of the x argument but in reality if we are dealing with the animal kingdom only then we can define an abstract type Animal and apply holy traits to all Animal objects only.","category":"page"}]
}

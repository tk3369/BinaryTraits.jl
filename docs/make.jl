using Documenter
using BinaryTraits

makedocs(
    modules = [BinaryTraits],
    sitename="BinaryTraits.jl",
    pages = [
        "Motivation" => "index.md",
        "User Guide" => "guide.md",
        "Concepts" => "concepts.md",
        "Reference" => "reference.md",
        "Under the hood" => "design.md",
    ]
)

deploydocs(
    repo = "github.com/tk3369/BinaryTraits.jl.git",
)

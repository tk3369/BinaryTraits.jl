using Documenter
using BinaryTraits

makedocs(
    modules = [BinaryTraits],
    sitename="BinaryTraits.jl",
    pages = [
        "Introduction" => "index.md",
        "User Guide" => "guide.md",
        "Reference" => "reference.md",
        "Under the hood" => "design.md",
    ]
)

deploydocs(
    repo = "github.com/tk3369/BinaryTraits.jl.git",
)

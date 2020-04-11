using Documenter
using BinaryTraits

makedocs(
    modules = [BinaryTraits],
    sitename="BinaryTraits"
)

deploydocs(
    repo = "github.com/tk3369/BinaryTraits.jl.git",
    # deps = Deps.pip("pygments", "mkdocs", "mkdocs-material", "python-markdown-math"),
    # make   = () -> run(`mkdocs build`),
    # target = "site"
)


# verbose flag
const VERBOSE = Ref(false)

"""
    set_verbose!(flag::Bool)

For debugging - set flag to print macro expansions
"""
function set_verbose!(verbose::Bool)
    VERBOSE[] = verbose
end


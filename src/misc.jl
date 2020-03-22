struct SyntaxError <: Exception
    msg
end

# verbose flag

const VERBOSE = Ref(false)

function set_verbose(b::Bool)
    VERBOSE[] = b
end

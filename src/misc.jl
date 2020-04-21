
# verbose flag

const VERBOSE = Ref(false)

function set_verbose(verbose::Bool)
    VERBOSE[] = verbose
end

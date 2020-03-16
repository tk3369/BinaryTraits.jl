# prefix customizations

const prefix_map = Dict{Module,Dict{Symbol,Tuple{Symbol,Symbol}}}()

function get_prefix(m::Module, trait::Symbol)
    trait_dict = get!(prefix_map, m, Dict{Symbol,Tuple{Symbol,Symbol}}())
    return get!(trait_dict, trait, (:Can, :Cannot))
end

function set_prefix(m::Module, trait::Symbol, prefixes::Tuple{Symbol, Symbol})
    trait_dict = get!(prefix_map, m, Dict{Symbol,Tuple{Symbol,Symbol}}())
    return get!(trait_dict, trait, prefixes)
end

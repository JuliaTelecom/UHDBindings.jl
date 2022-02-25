module LibUHD

# Bindings generated with Clang.jl ! https://github.com/JuliaInterop/Clang.jl 

# ----------------------------------------------------
# --- Dependencies 
# ---------------------------------------------------- 
using USRPHardwareDriver_jll
using CEnum
@static if uhd_provider == "local"
    # --- Using local install, assuming it works
    libUHD_system_h = dlopen("libuhd", false);
    const libuhd = dlpath(libUHD_system_h)
end
# ----------------------------------------------------
# --- Constant
# ---------------------------------------------------- 
const UHD_VERSION_ABI_STRING = "4.1.0"
const UHD_VERSION = 4010099


# ----------------------------------------------------
# --- Enumeration
# ---------------------------------------------------- 
include("enums.jl")

# ----------------------------------------------------
# --- Structures
# ---------------------------------------------------- 
include("struct.jl")

# ----------------------------------------------------
# --- Function calls
# ---------------------------------------------------- 
include("functions.jl")

# ----------------------------------------------------
# --- UHD Symbol exportation
# ---------------------------------------------------- 
# exports
const PREFIXES = ["UHD_","uhd_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module

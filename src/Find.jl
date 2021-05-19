# ----------------------------------------------------
# --- Finding USRP 
# ---------------------------------------------------- 
mutable struct uhd_string_vector
end



""" 
Find all connected USRP devices 
out = uhd_find_devices(args)
- args : String with uhd_find_devices argument (such as "addr=192.168.10.16"
"""
function uhd_find_devices(stringArgs)
	args	=  Base.unsafe_convert(Cstring,stringArgs);
    # --- Create an handler to get the string 
    global stringHandler = uhd_string_vector_make()

    # --- Call UHD Find device 
    ccall((:uhd_usrp_find,libUHD),uhd_error,(Cstring,Ptr{Ptr{uhd_string_vector}}),args,stringHandler)

    vectorSize = uhd_string_vector_size(stringHandler)
    allStr = String[]
    if vectorSize == 0
        @info "No UHD devices found. Try with \"addr=xxx.xxx.x.x\" to specify the USRP IP address"
    else
        @info "Found $(vectorSize) USRP devices" 
        for n = 0 : 1 : vectorSize - 1 
            # --- Recreate the string for a fancy output
            stringOut = uhd_string_vector_at(stringHandler,0)
            global allS = String.(split(stringOut,","))
            ee = "UHD Device $n \n"*join([" "*allS[i]*"\n" for i ∈ 1:length(allS)])
            customPrint(ee,"UHD",bold=true,color=:magenta)
            # --- FIXME Populate a dict to get USRP IP addr
            push!(allStr,ee)
        end
    end
    # --- Free the structure 
    uhd_string_vector_free(stringHandler)
    # Return number of UHD device found 
    return allStr
end

# In case of no input parameters, equivalent to call with "" 
uhd_find_devices() = uhd_find_devices("")


""" 
Create a string handler usefull to get/take messages from the USRP 
""" 
function uhd_string_vector_make()
    stringHandler = Ref{Ptr{uhd_string_vector}}()
    ccall((:uhd_string_vector_make,libUHD),uhd_error,(Ptr{Ptr{uhd_string_vector}},),stringHandler)
    return stringHandler
end

""" 
Free a string handler craeted by uhd_string_vector_make() 
""" 
function uhd_string_vector_free(stringHandler)
    # --- Free the structure 
    ccall((:uhd_string_vector_free,libUHD),uhd_error,(Ptr{Ptr{uhd_string_vector}},),stringHandler);
end



""" 
Get the UHD internal string size. Takes a stringHandler as input parameter and returns a Int (Number of strings) 
The string handler can be obtained with uhd_string_vector_make
""" 
function uhd_string_vector_size(stringHandler)
    # --- Pointer for answer
    vectorSize = Ref{Csize_t}(0)
    # --- CCall 
    errCall = ccall((:uhd_string_vector_size,libUHD),uhd_error,(Ptr{uhd_string_vector},Ref{Csize_t}),stringHandler[],vectorSize)
    return vectorSize[]
end


"""
Get the string at position index in the stringHandler container
The string handler can be obtained with uhd_string_vector_make
"""
function uhd_string_vector_at(stringHandler,index)
    # --- Init container 
    v = Vector{UInt8}(undef,1024)
    # --- Get the data 
    errCall = ccall((:uhd_string_vector_at,libUHD),uhd_error,(Ptr{uhd_string_vector},Csize_t,Ptr{Cchar},Csize_t),stringHandler[],index,v,1024)
    # --- Convert it into String 
    strOut = String(v)
    # --- Find end of string 
    indexM = findfirst('\0',strOut)
    if indexM > 1 
        # Non null 
        stringOut = strOut[1:indexM-1]
    else 
        stringOut = ""
    end
    return stringOut
end


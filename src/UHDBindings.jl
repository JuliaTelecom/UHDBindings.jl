module UHDBindings

using Printf
using Preferences
using Libdl


# ----------------------------------------------------
# --- Loading UHD library 
# ---------------------------------------------------- 
# We use Yggdrasil to load the artifact responsible for UHD.
# It is possible to use a local install instead of the proposed UHD version 
""" 
Change UHD driver provider. Support "yggdrasil" to use shipped jll file or "local" to use custom installed library
set_provider("yggdrasil")
or 
set_provider("local")
"""
function set_provider(new_provider::String)
    if !(new_provider in ("yggdrasil","default", "local"))
        throw(ArgumentError("Invalid provider: \"$(new_provider)\""))
    end
    # Set it in our runtime values, as well as saving it to disk
    @set_preferences!("provider" => new_provider)
    @info("New provider set; restart your Julia session for this change to take effect!")
end
function get_provider()
    return @load_preference("provider","yggdrasil")
end
const uhd_provider = get_provider()
@static  if uhd_provider == "yggdrasil" || uhd_provider =="local"
    # --- Using Yggdrasil jll file 
    using USRPHardwareDriver_jll
    try 
        # --- We load the lib, but in two steps in case of an problem occur
        global tmp_libUHD = USRPHardwareDriver_jll.libuhd 
    catch exception 
        # A problem occured :D. Load manually the lib
        @warn "Unable to load libUHD using Yggdrasil. It probably means that the platform you use is not supported by artifact generated through Yggdrasil."
        @info "We fallback to local provider. It means that UHDBindings will work if you have installed a functionnal version of UHD on your system"
        libUHD_system_h = dlopen("libuhd", false);
        global tmp_libUHD =  dlpath(libUHD_system_h)
        # --- Change provider 
        set_provider("local")
    end
    # --- Point lib here it is good
    const libUHD = tmp_libUHD
end
@static if uhd_provider == "local"
    # --- Using local install, assuming it works
    libUHD_system_h = dlopen("libuhd", false);
    const libUHD = dlpath(libUHD_system_h)
end
# ---------------------------------------------------- 
# --- Bindings, structure and low level functions
# ---------------------------------------------------- 
# --- Including the file 
include("Bindings.jl");
# Export necessary structures for high API level managment
export Timestamp
export UHDBinding
# Exporting printing macros 
export @infotx, @warntx;
export @inforx, @warnrx;


# ----------------------------------------------------
# --- Finding devices 
# ---------------------------------------------------- 
include("Find.jl")
export uhd_find_devices

# ---------------------------------------------------- 
# --- Receiver Configuration 
# ---------------------------------------------------- 
# All structures and functions for the Rx side 
include("Rx.jl");
# Structures 
export UHDRx
# Export functions 
export recv,recv!;
export populateBuffer!
export getError, getTimestamp
export restartStreamer


# ---------------------------------------------------- 
# --- Transmitter Configuration  
# ---------------------------------------------------- 
# All structures and functions for the Tx side 
include("Tx.jl");
# Structures 
export UHDTx
# Export functions 
export send;
""" 
Init the core parameter of the radio in Tx or in Rx mode and initiate RF parameters 
# --- Syntax 
openUHD(mode,sysImage,carrierFreq,samplingRate,txGain,antenna="RX2")
# --- Input parameters 
- mode 			: String to open radio in "Tx" (transmitter) or in "Rx" (receive) mode
- carrierFreq	: Desired Carrier frequency [Union{Int,Float64}] 
- samplingRate	: Desired bandwidth [Union{Int,Float64}] 
- gain		: Desired Gain [Union{Int,Float64}] 
- antenna		: Desired Antenna alias Dict{Symbol,Vector[String]} (e.g. Dict(:Rx=>["RX2"],:Tx=>["TRX"]))
Keywords=
- args	  : String with the additionnal load parameters (for instance, path to the FPHGA image) [String]
# --- Output parameters 
- uhd		  	: UHD object [UHDBinding]
""" 
function openUHD(carrierFreq, samplingRate, gain;args="",channels=[0],antennas=Dict(:Rx=>["RX2"],:Tx=>["TRX"]),cpu_format="fc32",otw_format="sc16",subdev="",nbAntennaRx=1,nbAntennaTx=1,bypassStreamer=false)
	# ---------------------------------------------------- 
	# --- Handler  
	# ---------------------------------------------------- 
	addressUSRP = Ref{uhd_usrp_handle}();
	# --- Cal the init
    @assert_uhd uhd_usrp_make(addressUSRP,args)
	# --- Get the usable object 
	pointerUSRP = addressUSRP[];
    # ----------------------------------------------------
    # --- Manage dictionnaries for custom option passing 
    # ----------------------------------------------------
    aTx = parseDict(antennas,:Tx,["TRX"])
    aRx = parseDict(antennas,:Rx,["RX2"])
	# ---------------------------------------------------- 
	# --- Set Rx stage  
	# ---------------------------------------------------- 	
    rx = openUHDRx(pointerUSRP,carrierFreq, samplingRate, gain;channels,antennas=aRx,args,cpu_format,otw_format,subdev,nbAntennaRx,bypassStreamer)
	# ---------------------------------------------------- 
	# --- Set Tx stage  
	# ---------------------------------------------------- 	
    tx = openUHDTx(pointerUSRP,carrierFreq, samplingRate, gain;channels,antennas=aTx,args,cpu_format,otw_format,subdev,nbAntennaTx,bypassStreamer)
	# ---------------------------------------------------- 
	# --- Create radio 
	# ----------------------------------------------------	
	uhdBinding = UHDBinding(addressUSRP,rx,tx);
	return uhdBinding;
end
export openUHD;

# Be able to get a default value
parseDict(d,key,val=0) = (haskey(d,key) ? d[key] : val)


""" 
Close the USRP device (Rx or Tx mode) and release all associated objects

# --- Syntax 

close(uhd)
# --- Input parameters 
- uhd	: UHD object [UHDBinding]
# --- Output parameters 
- []
"""
function Base.close(uhdBinding::UHDBinding)
	# --- Close Rx and Tx streams
	close(uhdBinding.rx);
	close(uhdBinding.tx);
	# --- Close the USRP main object 
    @assert_uhd uhd_usrp_free(uhdBinding.addressUSRP);
	# --- Print a flag
	print("\n");
	@info "USRP device is now closed.";
end


""" 
Print the radio configuration 

# --- Syntax 

print(radio,chan=0)
# --- Input parameters 
- radio		: UHD object [Union{UHDBinding,UHDTx,UHDRx}]
- chan : Channel index to display (default 0)
# --- Output parameters 
- []
"""
function Base.print(radio::UHDBinding,chan=0)
	# --- Print the configuration of Tx and Rx 
	print(radio.rx,chan);
	print(radio.tx,chan);
end

# All functions are defined @UHDTx or @UHDRx level, we should define configuration functions @UHDBinding level 
# In such case, we will both apply configuration at Rx and Tx sides.

""" 
Update sampling rate of current radio device, and update radio object with the new obtained sampling frequency. If the input parameter is the UHDBinding object, the desired sampling frequency will be applied on both Rx and Tx sides. 
If the input is a [UHDRx] or a [UHDTx] object, it updates only the Rx or Tx sampling frequency   

# --- Syntax 

updateSamplingRate!(radio,samplingRate,chan=0)
# --- Input parameters 
- radio	  : UHD device [Union{UHDBinding,UHDRx,UHDTx}]
- samplingRate	: New desired sampling rate 
- chan : Channel index to use (default 0)
# --- Output parameters 
- 
"""
function updateSamplingRate!(radio::UHDBinding,samplingRate,chan=0)
	@sync updateSamplingRate!(radio.rx,samplingRate,chan);
	@sync updateSamplingRate!(radio.tx,samplingRate,chan);
end


""" 
Update carrier frequency of current radio device, and update radio object with the new obtained carrier frequency. If the input parameter is the UHDBinding object, the desired carrier frequency will be applied on both Rx and Tx sides. 
If the input is a [UHDRx] or a [UHDTx] object, it updates only the Rx or Tx carrier frequency   

# --- Syntax 

updateCarrierFreq!(radio,carrierFreq)
# --- Input parameters 
- radio	  : UHD device [Union{UHDBinding,UHDRx,UHDTx}]
- carrierFreq	: New desired carrier frequency 
- chan : Channel index to use (default 0)
# --- Output parameters 
- 
"""
function updateCarrierFreq!(radio::UHDBinding,carrierFreq,chan=0)
	@sync updateCarrierFreq!(radio.rx,carrierFreq,chan);
	@sync updateCarrierFreq!(radio.tx,carrierFreq,chan);
end

""" 
Update gain of current radio device, and update radio object with the new obtained gain. If the input parameter is the UHDBinding object, the desired gain will be applied on both Rx and Tx sides. 
If the input is a [UHDRx] or a [UHDTx] object, it updates only the Rx or Tx gain   

# --- Syntax 

updateGain!(radio,gain)
# --- Input parameters 
- radio	  : UHD device [Union{UHDBinding,UHDRx,UHDTx}]
- gain	: New desired gain 
- chan : Channel index to use (default 0)
# --- Output parameters 
- 
"""
function updateGain!(radio::UHDBinding,gain,chan=0)
	@sync updateGain!(radio.rx,gain,chan);
	@sync updateGain!(radio.tx,gain,chan);
end

# When given to UHDBinding, recv and send will dispatch to the appropriate substructure 
# Recv
recv(radio::UHDBinding,nbSamples)  = recv(radio.rx,nbSamples);
recv!(sig::Vector{Vector{T}},radio::UHDBinding;kwargs...) where T = recv!(sig,radio.rx;kwargs...);
recv!(sig::Vector{T},radio::UHDBinding;kwargs...) where T = recv!([sig],radio.rx;kwargs...);
# Send 
send(radio::UHDBinding,params...) = send(radio.tx,params...);


# Config can laos be dispatch 
uhd_usrp_create_stream(radio::UHDBinding;kwargs...) = uhd_usrp_create_stream(radio.rx;kwargs...)

"""" 
Returns the  internal radio buffer size 
""" 
function getBufferSize(radio)
    return radio.rx.packetSize
end

# ---------------------------------------------------- 
# --- Common functions and structures   
# ---------------------------------------------------- 
export updateSamplingRate!
export updateGain!
export updateCarrierFreq!
export print; 
export close;
export getBufferSize


end # module

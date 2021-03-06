module UHDBindings

using Libdl 
using Printf

# ---------------------------------------------------- 
# --- Library managment  
# ---------------------------------------------------- 
# As we shall be able to use the same module on a host PC (like Unix and MacOs, maybe windows ?) but also on ARM devices (targetting USRP E310) 
# We have to separate the fact that we want to use the RFNoC version, installed on the sysroot 
# For MACOS, some issue when UHD is installed from macports (not defined in PATH for compat reasons)
# TODO This is quite a hacky way to do this, a cleaner way to do this ?? 
const ARCHI = Sys.CPU_NAME == "cortex-a9" ? "arm" : "pc";
if Sys.isapple() 
	# --- For apple archi, UHD is installed with macports 
	const libUHD	= "/opt/local/lib/libuhd.dylib"; 
	const FORMAT_LONG = Clonglong;
else 
	# Default UHD library to be used 
	if ARCHI == "arm"
		const libUHD = "libuhd";
		# For E310 device, TimeStamp is a Int32 and Clonglong is mapped as a 64 bit word.
		const FORMAT_LONG = Int32;
	else 
		const libUHD = "libuhd"
		#const libUHD = "/usr/lib/x86_64-linux-gnu/libuhd.so.3.14.1";
		const FORMAT_LONG = Clonglong;
	end
end

# ---------------------------------------------------- 
# --- Common configuration and structures 
# ---------------------------------------------------- 
# --- Including the file 
include("common.jl");
export Timestamp
export UHDBinding
# Exporting printing macros 
export @infotx, @warntx;
export @inforx, @warnrx;

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
- antenna		: Desired Antenna alias [String]
Keywords=
- args	  : String with the additionnal load parameters (for instance, path to the FPHGA image) [String]
# --- Output parameters 
- uhd		  	: UHD object [UHDBinding]
""" 
function openUHD(carrierFreq, samplingRate, gain, antenna = "RX2";args="")
	# ---------------------------------------------------- 
	# --- Handler  
	# ---------------------------------------------------- 
	addressUSRP = Ref{Ptr{uhd_usrp}}();
	# --- Cal the init
	@assert_uhd ccall((:uhd_usrp_make, libUHD), uhd_error, (Ptr{Ptr{uhd_usrp}}, Cstring),addressUSRP,args);
	# --- Get the usable object 
	pointerUSRP = addressUSRP[];
	# ---------------------------------------------------- 
	# --- Set Rx stage  
	# ---------------------------------------------------- 	
	rx = openUHDRx(pointerUSRP,carrierFreq, samplingRate, gain, antenna;args=args);
	# ---------------------------------------------------- 
	# --- Set Tx stage  
	# ---------------------------------------------------- 	
	tx = openUHDTx(pointerUSRP,carrierFreq, samplingRate, gain, antenna;args=args);
	# ---------------------------------------------------- 
	# --- Create radio 
	# ----------------------------------------------------	
	uhdBinding = UHDBinding(addressUSRP,rx,tx);
	return uhdBinding;
end
export openUHD;

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
	@assert_uhd  ccall((:uhd_usrp_free, libUHD), uhd_error, (Ptr{Ptr{uhd_usrp}},),uhdBinding.addressUSRP);
	# --- Print a flag
	print("\n");
	@info "USRP device is now closed.";
end


""" 
Print the radio configuration 

# --- Syntax 

print(radio)
# --- Input parameters 
- radio		: UHD object [Union{UHDBinding,UHDTx,UHDRx}]
# --- Output parameters 
- []
"""
function Base.print(radio::UHDBinding)
	# --- Print the configuration of Tx and Rx 
	print(radio.rx);
	print(radio.tx);
end

# All functions are defined @UHDTx or @UHDRx level, we should define configuration functions @UHDBinding level 
# In such case, we will both apply configuration at Rx and Tx sides.

""" 
Update sampling rate of current radio device, and update radio object with the new obtained sampling frequency. If the input parameter is the UHDBinding object, the desired sampling frequency will be applied on both Rx and Tx sides. 
If the input is a [UHDRx] or a [UHDTx] object, it updates only the Rx or Tx sampling frequency   

# --- Syntax 

updateSamplingRate!(radio,samplingRate)
# --- Input parameters 
- radio	  : UHD device [Union{UHDBinding,UHDRx,UHDTx}]
- samplingRate	: New desired sampling rate 
# --- Output parameters 
- 
"""
function updateSamplingRate!(radio::UHDBinding,samplingRate)
	@sync updateSamplingRate!(radio.rx,samplingRate);
	@sync updateSamplingRate!(radio.tx,samplingRate);
end


""" 
Update carrier frequency of current radio device, and update radio object with the new obtained carrier frequency. If the input parameter is the UHDBinding object, the desired carrier frequency will be applied on both Rx and Tx sides. 
If the input is a [UHDRx] or a [UHDTx] object, it updates only the Rx or Tx carrier frequency   

# --- Syntax 

updateCarrierFreq!(radio,carrierFreq)
# --- Input parameters 
- radio	  : UHD device [Union{UHDBinding,UHDRx,UHDTx}]
- carrierFreq	: New desired carrier frequency 
# --- Output parameters 
- 
"""
function updateCarrierFreq!(radio::UHDBinding,carrierFreq)
	@sync updateCarrierFreq!(radio.rx,carrierFreq);
	@sync updateCarrierFreq!(radio.tx,carrierFreq);
end

""" 
Update gain of current radio device, and update radio object with the new obtained gain. If the input parameter is the UHDBinding object, the desired gain will be applied on both Rx and Tx sides. 
If the input is a [UHDRx] or a [UHDTx] object, it updates only the Rx or Tx gain   

# --- Syntax 

updateGain!(radio,gain)
# --- Input parameters 
- radio	  : UHD device [Union{UHDBinding,UHDRx,UHDTx}]
- gain	: New desired gain 
# --- Output parameters 
- 
"""
function updateGain!(radio::UHDBinding,gain)
	@sync updateGain!(radio.rx,gain);
	@sync updateGain!(radio.tx,gain);
end

# When given to UHDBinding, recv and send will dispatch to the appropriate substructure 
# Recv
recv(radio::UHDBinding,nbSamples)  = recv(radio.rx,nbSamples);
recv!(sig,radio::UHDBinding;kwargs...) = recv!(sig,radio.rx;kwargs...);
# Send 
send(radio::UHDBinding,params...) = send(radio.tx,params...);



# ---------------------------------------------------- 
# --- Common functions and structures   
# ---------------------------------------------------- 
export updateSamplingRate!
export updateGain!
export updateCarrierFreq!
export print; 
export close;



end # module

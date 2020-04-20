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
useRFNoC		= false;  
# Librar$ to use is RFNoC based 
const ARCHI = Sys.CPU_NAME == "cortex-a9" ? "arm" : "pc";
if useRFNoC 
	# We manually load the libuhd.so.4
	#const libUHD	= "/home/root/localInstall/usr/lib/libuhd.so.4";
	const libUHD	= "/home/root/newinstall/usr/lib/libuhd.so.4";
else 
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
end

# ---------------------------------------------------- 
# --- Common configuration and structures 
# ---------------------------------------------------- 
# --- Including the file 
include("common.jl");
export Timestamp


# ---------------------------------------------------- 
# --- Receiver Configuration 
# ---------------------------------------------------- 
# All structures and functions for the Rx side 
include("Rx.jl");
# Structures 
export UHDRx
# Export functions 
export initRxUHD; 
export openUHDRx;
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
export initTxUHD; 
export openUHDTx;
export send;
# ---------------------------------------------------- 
# --- Common functions and structures   
# ---------------------------------------------------- 
export updateSamplingRate!
export updateGain!
export updateCarrierFreq!
export print; 
export close;

""" 
Init the core parameter of the radio in Tx or in Rx mode and initiate RF parameters 

# --- Syntax 

openUHD(mode,sysImage,carrierFreq,samplingRate,txGain,antenna="RX2")
# --- Input parameters 
- mode 			: String to open radio in "Tx" (transmitter) or in "Rx" (receive) mode
- carrierFreq	: Desired Carrier frequency [Union{Int,Float64}] 
- samplingRate	: Desired bandwidth [Union{Int,Float64}] 
- txGain		: Desired Tx Gain [Union{Int,Float64}] 
- antenna		: Desired Antenna alias [String]
Keywords=
- args	  : String with the additionnal load parameters (for instance, path to the FPHGA image) [String]
# --- Output parameters 
- UHDTx		  	: UHD Tx or Rx object with PHY parameters [Union{UHDTx,UHDRx}]  
""" 
function openUHD(mode::String,carrierFreq, samplingRate, txGain, antenna = "RX2";args="")
	if mode == "Tx" 
		# --- Open radio in Tx mode 
		 radio 	 = openUHDTx(carrierFreq, samplingRate, txGain, antenna,args=args);
	elseif mode == "Rx" 
		# --- Open radio in Rx mode 
		 radio 	 = openUHDRx(carrierFreq, samplingRate, txGain, antenna,args=args);
	else 
		@error "Unknown mode for radio config. First parameter should be Tx or Rx (String)";
	end
	return radio;
end
export openUHD;

""" 
Close the USRP device (Rx or Tx mode) and release all associated objects

# --- Syntax 

close(uhd)
# --- Input parameters 
- uhd	: UHD object [UHDRx,UHDTx]
# --- Output parameters 
- []
"""
function Base.close(radio::UHDRx)
	# --- Checking realease nature 
	# There is one flag to avoid double close (that leads to seg fault) 
	if radio.released == 0
		# print("\n");
		# @info "Catch exception, release UHD related ressources"
		# C Wrapper to ressource release 
		@assert_uhd ccall((:uhd_rx_streamer_free, libUHD), uhd_error, (Ptr{Ptr{uhd_rx_streamer}},),radio.uhd.addressStream);
		@assert_uhd ccall((:uhd_rx_metadata_free, libUHD), uhd_error, (Ptr{Ptr{uhd_rx_metadata}},),radio.uhd.addressMD);
		@assert_uhd  ccall((:uhd_usrp_free, libUHD), uhd_error, (Ptr{Ptr{uhd_usrp}},),radio.uhd.addressUSRP);
		print("\n");
		@info "USRP device is now closed.";
	else 
		# print a warning  
		@warn "UHD ressource was already released, abort call";
	end 
	# --- Force flag value 
	radio.released = 1;
end
function Base.close(radio::UHDTx)
	# --- Checking realease nature 
	# There is one flag to avoid double free (that leads to seg fault) 
	if radio.released == 0
		# C Wrapper to ressource release 
		@assert_uhd  ccall((:uhd_usrp_free, libUHD), uhd_error, (Ptr{Ptr{uhd_usrp}},), radio.uhd.addressUSRP);
		@assert_uhd ccall((:uhd_tx_streamer_free, libUHD), uhd_error, (Ptr{Ptr{uhd_tx_streamer}},), radio.uhd.addressStream);
		@assert_uhd ccall((:uhd_tx_metadata_free, libUHD), uhd_error, (Ptr{Ptr{uhd_tx_metadata}},), radio.uhd.addressMD);
		@info "USRP device is now closed.";
	else 
		# print a warning  
		@warn "UHD ressource was already released, abort call";
	end 
	# --- Force flag value 
	radio.released = 1;
end

""" 
Print the radio configuration 

# --- Syntax 

print(radio)
# --- Input parameters 
- radio		: UHD object (Tx or Rx)
# --- Output parameters 
- []
"""
function Base.print(radio::UHDRx)
	# Get the gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_gain, libUHD), Cvoid, (Ptr{Cvoid}, Csize_t, Cstring,Ref{Cdouble}),radio.uhd.pointerUSRP,0,"",pointerGain);
	updateGain	  = pointerGain[]; 
	# Get the rate from UHD 
	pointerRate	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_rate, libUHD), Cvoid, (Ptr{Cvoid}, Csize_t, Ref{Cdouble}),radio.uhd.pointerUSRP,0,pointerRate);
	updateRate	  = pointerRate[]; 
	# Get the freq from UHD 
	pointerFreq	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_freq, libUHD), Cvoid, (Ptr{Cvoid}, Csize_t, Ref{Cdouble}),radio.uhd.pointerUSRP,0,pointerFreq);
	updateFreq	  = pointerFreq[];
	# Print message 
	strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Rx Gain: %2.2f dB\n",updateFreq/1e6,updateRate/1e6,updateGain);
	@info "Current UHD Configuration in Rx mode\n$strF"; 
end
function Base.print(radio::UHDTx)
	# Get the gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_gain, libUHD), Cvoid, (Ptr{Cvoid}, Csize_t, Cstring, Ref{Cdouble}), radio.uhd.pointerUSRP, 0, "", pointerGain);
	updateGain	  = pointerGain[]; 
	# Get the rate from UHD 
	pointerRate	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_rate, libUHD), Cvoid, (Ptr{Cvoid}, Csize_t, Ref{Cdouble}), radio.uhd.pointerUSRP, 0, pointerRate);
	updateRate	  = pointerRate[]; 
	# Get the freq from UHD 
	pointerFreq	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_freq, libUHD), Cvoid, (Ptr{Cvoid}, Csize_t, Ref{Cdouble}), radio.uhd.pointerUSRP, 0, pointerFreq);
	updateFreq	  = pointerFreq[];
	# Print message 
	strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Tx Gain: %2.2f dB\n",updateFreq / 1e6,updateRate / 1e6,updateGain);
	@info "Current UHD Configuration in Tx mode\n$strF"; 
end

end # module

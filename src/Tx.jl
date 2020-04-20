# --- Working structures 
mutable struct uhd_tx_streamer
end

struct uhd_tx_metadata 
	has_time_spec::Cuchar;
	time_spec::Clonglong;
	time_spec_frac::Cdouble;
	start_of_burst::Cuchar;
	end_of_burst::Cuchar;
	eov_positions::Ref{Csize_t};
	eov_positions_size::Csize_t;
end

# --- Tx structures 
mutable struct UHDTxWrapper 
	flag::Bool;
	pointerUSRP::Ptr{uhd_usrp};
	pointerStreamer::Ptr{uhd_tx_streamer};
	pointerMD::Ptr{uhd_tx_metadata};
	addressUSRP::Ref{Ptr{uhd_usrp}};
	addressStream::Ref{Ptr{uhd_tx_streamer}};
	addressMD::Ref{Ptr{uhd_tx_metadata}};
end 
mutable struct UHDTx 
	uhd::UHDTxWrapper;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::String;
	packetSize::Csize_t;
	released::Int;
end


""" 
Initiate all structures to instantiate and pilot a USRP device in Transmitter (Tx) mode.

# --- Syntax 

uhd	  = initTxUHD(sysImage)
# --- Input parameters 
- sysImage	  : String with the additionnal load parameters (for instance, path to the FPHGA image) [String]
# --- Output parameters 
- uhd		  = UHD Tx object [UHDTxWrapper] 
"""
function initTxUHD(sysImage)
	# ---------------------------------------------------- 
	# --- Handler  
	# ---------------------------------------------------- 
	addressUSRP = Ref{Ptr{uhd_usrp}}();
	# --- Cal the init
	@assert_uhd ccall((:uhd_usrp_make, libUHD), uhd_error, (Ptr{Ptr{uhd_usrp}}, Cstring), addressUSRP, sysImage);
	# --- Get the usable object 
	usrpPointer = addressUSRP[];
	# ---------------------------------------------------- 
	# --- Tx Streamer  
	# ---------------------------------------------------- 
	# --- Create a pointer related to the Tx streamer
	addressStream = Ref{Ptr{uhd_tx_streamer}}(); 
	# --- Cal the init
	@assert_uhd ccall((:uhd_tx_streamer_make, libUHD), uhd_error, (Ptr{Ptr{uhd_tx_streamer}},), addressStream);
	streamerPointer = addressStream[];
	# ---------------------------------------------------- 
	# --- Tx Metadata  
	# ---------------------------------------------------- 
	# --- Create a pointer related to Metadata 
	addressMD = Ref{Ptr{uhd_tx_metadata}}(); 
	# --- Cal the init
	@assert_uhd ccall((:uhd_tx_metadata_make, libUHD), uhd_error, (Ptr{Ptr{uhd_tx_metadata}}, Cuchar, FORMAT_LONG, Cdouble, Cuchar, Cuchar), addressMD, false, 0, 0.1, true, false);
	# --- Get the usable object 
	metadataPointer = addressMD[];
	# ---------------------------------------------------- 
	# --- Create the USRP wrapper object  
	# ---------------------------------------------------- 
	uhd  = UHDTxWrapper(true, usrpPointer, streamerPointer, metadataPointer, addressUSRP, addressStream, addressMD);
	@info("Done init \n");
	return uhd;
end

""" 
Init the core parameter of the radio in Tx mode and initiate RF parameters 

# --- Syntax 

openUHDTx(carrierFreq,samplingRate,gain,antenna="TX-RX";args="")
# --- Input parameters 
- carrierFreq	: Desired Carrier frequency [Union{Int,Float64}] 
- samplingRate	: Desired bandwidth [Union{Int,Float64}] 
- gain		: Desired Tx Gain [Union{Int,Float64}] 
- antenna		: Desired Antenna alias (default "TX-RX") [String] 
Keywords:
- args	  : String with the additionnal load parameters (for instance, path to the FPHGA image) [String]
# --- Output parameters 
- UHDTx		  	: UHD Tx object with PHY parameters [UHDTx]  
"""
function openUHDTx(carrierFreq, samplingRate, gain, antenna = "TX-RX";args="")
	# ---------------------------------------------------- 
	# --- Init  UHD object  
	# ---------------------------------------------------- 
	uhd	  = initTxUHD(args);
	# ---------------------------------------------------- 
	# --- Creating Runtime structures  
	# ---------------------------------------------------- 
	# --- Create structure for UHD argument 
	# TODO Adding custom levels here for user API
	channel		   =  Ref{Csize_t}(0);
	a1			   =  Base.unsafe_convert(Cstring, "fc32");
	a2			   =  Base.unsafe_convert(Cstring, "sc16");
	a3			   =  Base.unsafe_convert(Cstring, "");
	uhdArgs		   = uhd_stream_args_t(a1, a2, a3, channel, 1);
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	# --- Update the Tx sampling rate 
	ccall((:uhd_usrp_set_tx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t), uhd.pointerUSRP, samplingRate, 0);
	# --- Get the Tx rate from the radio 
	pointerRate  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}), uhd.pointerUSRP, 0, pointerRate);
	updateRate  = pointerRate[];	
	# --- Print a flag 
	if updateRate != samplingRate 
		@warn "Effective Rate is $(updateRate / 1e6) MHz and not $(samplingRate / 1e6) MHz\n" 
	else 
		@info "Effective Rate is $(updateRate / 1e6) MHz\n";
	end
	# ---------------------------------------------------- 
	# --- Carrier Frequency configuration  
	# ---------------------------------------------------- 
	# --- Create structure for request 
	tuneRequest	   = uhd_tune_request_t(carrierFreq, UHD_TUNE_REQUEST_POLICY_AUTO, UHD_TUNE_REQUEST_POLICY_AUTO);
	tunePointer	  = Ref{uhd_tune_request_t}(tuneRequest);	
	pointerTuneResult	  = Ref{uhd_tune_result}();	
	ccall((:uhd_usrp_set_tx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Ptr{uhd_tune_request_t}, Csize_t, Ptr{uhd_tune_result}), uhd.pointerUSRP, tunePointer, 0, pointerTuneResult);
	pointerCarrierFreq = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}), uhd.pointerUSRP, 0, pointerCarrierFreq); 
	updateCarrierFreq	= pointerCarrierFreq[];
	if updateCarrierFreq != carrierFreq 
		@warn "Effective carrier frequency is $(updateCarrierFreq / 1e6) MHz and not $(carrierFreq / 1e6) Hz\n" 
	else 
		@info "Effective carrier frequency is $(updateCarrierFreq / 1e6) MHz\n";
	end	
	# ---------------------------------------------------- 
	# --- Gain configuration  
	# ---------------------------------------------------- 
	# Update the UHD sampling rate 
	ccall((:uhd_usrp_set_tx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t, Cstring), uhd.pointerUSRP, gain, 0, "");
	# Get the updated gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Cstring, Ref{Cdouble}), uhd.pointerUSRP, 0, "", pointerGain);
	updateGain	  = pointerGain[]; 
	# --- Print a flag 
	if updateGain != gain 
		@warn "Effective gain is $(updateGain) dB and not $(gain) dB\n" 
	else 
		@info "Effective gain is $(updateGain) dB\n";
	end 
	# ---------------------------------------------------- 
	# --- Antenna configuration 
	# ---------------------------------------------------- 
	# ccall((:uhd_usrp_set_tx_antenna, libUHD), Cvoid, (Ptr{uhd_usrp}, Cstring, Csize_t), uhd.pointerUSRP, antenna, 0);
	# ---------------------------------------------------- 
	# --- Setting up streamer  
	# ---------------------------------------------------- 
	# --- Setting up arguments 
	pointerArgs	  = Ref{uhd_stream_args_t}(uhdArgs);
	ccall((:uhd_usrp_get_tx_stream, libUHD), Cvoid, (Ptr{uhd_usrp}, Ptr{uhd_stream_args_t}, Ptr{uhd_tx_streamer}), uhd.pointerUSRP, pointerArgs, uhd.pointerStreamer);
	# --- Getting number of samples ber buffer 
	pointerSamples	  = Ref{Csize_t}(0);
	ccall((:uhd_tx_streamer_max_num_samps, libUHD), Cvoid, (Ptr{uhd_stream_args_t}, Ref{Csize_t}), uhd.pointerStreamer, pointerSamples);
	nbSamples		  = pointerSamples[];	
	# ---------------------------------------------------- 
	# --- Create object and return  
	# ---------------------------------------------------- 
	# --- Return  
	return UHDTx(uhd, updateCarrierFreq, updateRate, updateGain, antenna, nbSamples, 0);
end



""" 
Update sampling rate of current radio device, and update radio object with the new obtained sampling frequency  

# --- Syntax 

updateSamplingRate!(radio,samplingRate)
# --- Input parameters 
- radio	  : UHD device [UHDTx]
- samplingRate	: New desired sampling rate 
# --- Output parameters 
- 
"""
function updateSamplingRate!(radio::UHDTx, samplingRate)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	@info  "Try to change rate from $(radio.samplingRate / 1e6) MHz to $(samplingRate / 1e6) MHz";
	# --- Update the Tx sampling rate 
	ccall((:uhd_usrp_set_tx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t), radio.uhd.pointerUSRP, samplingRate, 0);
	# --- Get the Tx rate from the radio 
	pointerRate  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}), radio.uhd.pointerUSRP, 0, pointerRate);
	updateRate  = pointerRate[];	
	# --- Print a flag 
	if updateRate != samplingRate 
		@warn "Effective Rate is $(updateRate / 1e6) MHz and not $(samplingRate / 1e6) MHz\n" 
	else 
		@info "Effective Rate is $(updateRate / 1e6) MHz\n";
	end
	radio.samplingRate = updateRate;
end


""" 
Update gain of current radio device, and update radio object with the new obtained  gain

# --- Syntax 

updateGain!(radio,gain)
# --- Input parameters 
- radio	  : UHD device [UHDTx]
- gain	: New desired gain 
# --- Output parameters 
- updateGain : Current Radio gain [Float64]
"""
function updateGain!(radio::UHDTx, gain)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	@info  "Try to change gain from $(radio.gain) dB to $(gain) dB";
	# Update the UHD sampling rate 
	ccall((:uhd_usrp_set_tx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t, Cstring), radio.uhd.pointerUSRP, gain, 0, "");
	# Get the updated gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Cstring, Ref{Cdouble}), radio.uhd.pointerUSRP, 0, "", pointerGain);
	updateGain	  = pointerGain[]; 
	# --- Print a flag 
	if updateGain != gain 
		@warn "Effective gain is $(updateGain) dB and not $(gain) dB\n" 
	else 
		@info "Effective gain is $(updateGain) dB\n";
	end 
	radio.gain = updateGain;
	return updateGain;
end

""" 
Update carrier frequency of current radio device, and update radio object with the new obtained carrier frequency 

# --- Syntax 

updateCarrierFreq!(radio,carrierFreq)
# --- Input parameters 
- radio	  : UHD device [UHDRx]
- carrierFreq	: New desired carrier freq 
# --- Output parameters 
- carrierFreq 	: Current radio carrier frequency 
# --- 
# v 1.0
"""
function updateCarrierFreq!(radio::UHDTx, carrierFreq)
	# ---------------------------------------------------- 
	# --- Carrier Frequency configuration  
	# ---------------------------------------------------- 
	@info  "Try to change carrier frequency from $(radio.carrierFreq / 1e6) MHz to $(carrierFreq / 1e6) MHz";
	tuneRequest   = uhd_tune_request_t(carrierFreq, UHD_TUNE_REQUEST_POLICY_AUTO, UHD_TUNE_REQUEST_POLICY_AUTO);
	tunePointer	  = Ref{uhd_tune_request_t}(tuneRequest);	
	pointerTuneResult	  = Ref{uhd_tune_result}();	
	ccall((:uhd_usrp_set_tx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Ptr{uhd_tune_request_t}, Csize_t, Ptr{uhd_tune_result}), radio.uhd.pointerUSRP, tunePointer, 0, pointerTuneResult);
	pointerCarrierFreq = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}), radio.uhd.pointerUSRP, 0, pointerCarrierFreq); 
	updateCarrierFreq	= pointerCarrierFreq[];
	if updateCarrierFreq != carrierFreq 
		@warn "Effective carrier frequency is $(updateCarrierFreq / 1e6) MHz and not $(carrierFreq / 1e6) MHz\n" 
	else 
		@info "Effective carrier frequency is $(updateCarrierFreq / 1e6) MHz\n";
	end	
	radio.carrierFreq = updateCarrierFreq;
	return updateCarrierFreq;
end

""" 
Send a buffer though the radio device. It is possible to force a cyclic buffer send (the radio uninterruply send the same buffer) by setting the cyclic parameter to true

# --- Syntax 

send(radio,buffer,cyclic=false)
# --- Input parameters 
- radio	  	: UHD device [UHDRx]
- buffer 	: Buffer to be send [Union{Array{Complex{Cfloat}},Array{Cfloat}}] 
- cyclic 	: Send same buffer multiple times (default false) [Bool]
# --- Output parameters 
- nbEch 	: Number of samples effectively send [Csize_t]. It corresponds to the number of complex samples sent.
# --- 
# v 1.0
"""
function send(radio::UHDTx, buffer::Union{Array{Complex{Cfloat}},Array{Cfloat}}, cyclic::Bool = false)
	# --- Global pointer 
	ptr				= Ref(Ptr{Cvoid}(pointer(buffer)));
	# --- Pointer to number of samples transmitted 
	pointerSamples 	= Ref{Csize_t}(0);
	# --- Size of buffer 
	sL 				= Csize_t(sizeof(buffer) ÷ sizeof(Cfloat));
	# --- Accumulated value of number of samples transmitted
	nbEch 			= Csize_t(0);
	try 
		while true
			# --- Effectively transmit data
			ccall((:uhd_tx_streamer_send, libUHD), uhd_error, (Ptr{uhd_tx_streamer}, Ptr{Ptr{Cvoid}}, Csize_t, Ptr{Ptr{uhd_tx_metadata}}, Cfloat, Ref{Csize_t}), radio.uhd.pointerStreamer, ptr, sL, radio.uhd.addressMD, 0.1, pointerSamples);
			# --- Getting number of transmitted samples
			nbEch 		+= pointerSamples[];
			# --- Detection of cyclic mode 
			(cyclic == false) && break 
			# --- Forcing refresh
			yield();
		end 
	catch e;
		# --- Interruption handling
		print(e);
		print("\n");
		@info "Interruption detected";
	end
	# --- Return number of complex samples transmitted
	# We accumulate number of samples transmitted, we should divide by 2 to get number of Complex samples
	return (nbEch ÷ 2);
end


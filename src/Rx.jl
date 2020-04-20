# --- Working structures 

mutable struct uhd_rx_streamer
end

struct uhd_rx_metadata 
	has_time_spec::Cuchar;
	time_spec::Clonglong;
	time_spec_frac::Cdouble;
	more_fragments::Cuchar;
	fragment_offset::Csize_t;
	start_of_burst::Cuchar;
	end_of_burst::Cuchar;
	eov_positions::Ref{Csize_t};
	eov_positions_size::Csize_t;
	eov_positions_count::Csize_t;
	error_code::error_code_t;
	out_of_sequence::Cuchar;
end

# --- Rx structures 
struct UHDRxWrapper 
	flag::Bool;
	pointerUSRP::Ptr{uhd_usrp};
	pointerStreamer::Ptr{uhd_rx_streamer};
	pointerMD::Ptr{uhd_rx_metadata};
	addressUSRP::Ref{Ptr{uhd_usrp}};
	addressStream::Ref{Ptr{uhd_rx_streamer}};
	addressMD::Ref{Ptr{uhd_rx_metadata}};
	pointerSamples::Ref{Csize_t}
end 

mutable struct UHDRx 
	uhd::UHDRxWrapper;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
	antenna::String;
	packetSize::Csize_t;
	released::Int;
end



""" 

Initiate all structures to instantiate and pilot a USRP device into Receiver mode (Rx).

# --- Syntax 

uhd	  = initRxUHD(sysImage)
# --- Input parameters 
- sysImage	  : String with the additionnal load parameters (for instance, path to the FPHGA image) [String]
# --- Output parameters 
- uhd		  = UHD Rx object [UHDRxWrapper] 
"""
function initRxUHD(sysImage)
	# ---------------------------------------------------- 
	# --- Handler  
	# ---------------------------------------------------- 
	addressUSRP = Ref{Ptr{uhd_usrp}}();
	# --- Cal the init
	@assert_uhd ccall((:uhd_usrp_make, libUHD), uhd_error, (Ptr{Ptr{uhd_usrp}}, Cstring),addressUSRP,sysImage);
	# --- Get the usable object 
	usrpPointer = addressUSRP[];
	# ---------------------------------------------------- 
	# --- Rx Streamer  
	# ---------------------------------------------------- 
	# --- Create a pointer related to the Rx streamer
	addressStream = Ref{Ptr{uhd_rx_streamer}}(); 
	# --- Cal the init
	@assert_uhd ccall((:uhd_rx_streamer_make, libUHD), uhd_error, (Ptr{Ptr{uhd_rx_streamer}},),addressStream);
	streamerPointer = addressStream[];
	# ---------------------------------------------------- 
	# --- Rx Metadata  
	# ---------------------------------------------------- 
	# --- Create a pointer related to Metadata 
	addressMD = Ref{Ptr{uhd_rx_metadata}}(); 
	# --- Cal the init
	@assert_uhd ccall((:uhd_rx_metadata_make, libUHD), uhd_error, (Ptr{Ptr{uhd_rx_metadata}},),addressMD);
	# --- Get the usable object 
	metadataPointer = addressMD[];
	# --- Pointer for counting number of samples 
	pointerSamples = Ref{Csize_t}(0);
	# ---------------------------------------------------- 
	# --- Create the USRP wrapper object  
	# ---------------------------------------------------- 
	uhd  = UHDRxWrapper(true,usrpPointer,streamerPointer,metadataPointer,addressUSRP,addressStream,addressMD,pointerSamples);
	@info("Done init \n");
	return uhd;
end


""" 
Init the core parameter of the radio (Rx mode) and initiate RF parameters 

# --- Syntax 

openUHDRx(sysImage,carrierFreq,samplingRate,gain,antenna="TX-RX")
# --- Input parameters 
- carrierFreq	: Desired Carrier frequency [Union{Int,Float64}] 
- samplingRate	: Desired bandwidth [Union{Int,Float64}] 
- gain		: Desired Rx Gain [Union{Int,Float64}] 
- antenna		: Desired Antenna alias  (default "TX-RX") [String]
Keywords 
- args	  : String with the additionnal load parameters (for instance, path to the FPHGA image) [String]
# --- Output parameters 
- UHDRx		  	: UHD Rx object with PHY parameters [UHDRx]  
"""
function openUHDRx(carrierFreq,samplingRate,gain,antenna="RX2";args="",uhdArgs="");
	# ---------------------------------------------------- 
	# --- Init  UHD object  
	# ---------------------------------------------------- 
	uhd	  = initRxUHD(args);
	# ---------------------------------------------------- 
	# --- Creating Runtime structures  
	# ---------------------------------------------------- 
	# --- Create structure for UHD argument 
	# TODO Adding custom levels here for user API
	channel		   =  Ref{Csize_t}(0);
	a1			   =  Base.unsafe_convert(Cstring,"fc32");
	a2			   =  Base.unsafe_convert(Cstring,"sc16");
	a3			   =  Base.unsafe_convert(Cstring,uhdArgs);
	uhdArgs		   = uhd_stream_args_t(a1,a2,a3,channel,1);
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	# --- Update the Rx sampling rate 
	ccall((:uhd_usrp_set_rx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t),uhd.pointerUSRP,samplingRate,0);
	# --- Get the Rx rate from the radio 
	pointerRate  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}),uhd.pointerUSRP,0,pointerRate);
	updateRate  = pointerRate[];	
	# --- Print a flag 
	if updateRate != samplingRate 
		@warn "Effective Rate is $(updateRate/1e6) MHz and not $(samplingRate/1e6) MHz\n" 
	else 
		@info "Effective Rate is $(updateRate/1e6) MHz\n";
	end
	# ---------------------------------------------------- 
	# --- Carrier Frequency configuration  
	# ---------------------------------------------------- 
	# --- Create structure for request 
	tuneRequest	   = uhd_tune_request_t(carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,UHD_TUNE_REQUEST_POLICY_AUTO);
	tunePointer	  = Ref{uhd_tune_request_t}(tuneRequest);	
	pointerTuneResult	  = Ref{uhd_tune_result}();	
	ccall((:uhd_usrp_set_rx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Ptr{uhd_tune_request_t}, Csize_t, Ptr{uhd_tune_result}),uhd.pointerUSRP,tunePointer,0,pointerTuneResult);
	pointerCarrierFreq = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}),uhd.pointerUSRP,0,pointerCarrierFreq); 
	updateCarrierFreq	= pointerCarrierFreq[];
	if updateCarrierFreq != carrierFreq 
		@warn "Effective carrier frequency is $(updateCarrierFreq/1e6) MHz and not $(carrierFreq/1e6) MHz\n" 
	else 
		@info "Effective carrier frequency is $(updateCarrierFreq/1e6) MHz\n";
	end	
	# ---------------------------------------------------- 
	# --- Gain configuration  
	# ---------------------------------------------------- 
	# Update the UHD sampling rate 
	ccall((:uhd_usrp_set_rx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t, Cstring),uhd.pointerUSRP,gain,0,"");
	# Get the updated gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Cstring,Ref{Cdouble}),uhd.pointerUSRP,0,"",pointerGain);
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
	ccall((:uhd_usrp_set_rx_antenna, libUHD), Cvoid, (Ptr{uhd_usrp}, Cstring, Csize_t),uhd.pointerUSRP,antenna,0);
	# ---------------------------------------------------- 
	# --- Setting up streamer  
	# ---------------------------------------------------- 
	# --- Setting up arguments 
	pointerArgs	  = Ref{uhd_stream_args_t}(uhdArgs);
	ccall((:uhd_usrp_get_rx_stream, libUHD), Cvoid, (Ptr{uhd_usrp},Ptr{uhd_stream_args_t},Ptr{uhd_rx_streamer}),uhd.pointerUSRP,pointerArgs,uhd.pointerStreamer);
	# --- Getting number of samples ber buffer 
	pointerSamples	  = Ref{Csize_t}(0);
	ccall((:uhd_rx_streamer_max_num_samps, libUHD), Cvoid, (Ptr{uhd_stream_args_t},Ref{Csize_t}),uhd.pointerStreamer,pointerSamples);
	nbSamples		  = pointerSamples[];	
	# --- Create streamer master 
	#streamCmd	= stream_cmd(UHD_STREAM_MODE_NUM_SAMPS_AND_DONE,nbSamples,true,0,0.0);
	streamCmd	= stream_cmd(UHD_STREAM_MODE_START_CONTINUOUS,nbSamples,true,2,0.0);
	pointerCmd	= Ref{stream_cmd}(streamCmd);
	ccall((:uhd_rx_streamer_issue_stream_cmd, libUHD), Cvoid, (Ptr{uhd_stream_args_t},Ptr{stream_cmd}),uhd.pointerStreamer,pointerCmd);
	# ---------------------------------------------------- 
	# --- Create object and return  
	# ---------------------------------------------------- 
	# --- Return  
	return UHDRx(uhd,updateCarrierFreq,updateRate,updateGain,antenna,nbSamples,0);
end


""" 
Update sampling rate of current radio device, and update radio object with the new obtained sampling frequency  

# --- Syntax 

updateSamplingRate!(radio,samplingRate)
# --- Input parameters 
- radio	  : UHD device [UHDRx]
- samplingRate	: New desired sampling rate 
# --- Output parameters 
- 
"""
function updateSamplingRate!(radio::UHDRx,samplingRate)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	@info  "Try to change rate from $(radio.samplingRate/1e6) MHz to $(samplingRate/1e6) MHz";
	# --- Update the Rx sampling rate 
	ccall((:uhd_usrp_set_rx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t),radio.uhd.pointerUSRP,samplingRate,0);
	# --- Get the Rx rate from the radio 
	pointerRate  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}),radio.uhd.pointerUSRP,0,pointerRate);
	updateRate  = pointerRate[];	
	# --- Print a flag 
	if updateRate != samplingRate 
		@warn "Effective Rate is $(updateRate/1e6) MHz and not $(samplingRate/1e6) MHz\n" 
	else 
		@info "Effective Rate is $(updateRate/1e6) MHz\n";
	end
	radio.samplingRate = updateRate;
end


""" 
Update gain of current radio device, and update radio object with the new obtained  gain

# --- Syntax 

updateGain!(radio,gain)
# --- Input parameters 
- radio	  : UHD device [UHDRx]
- gain	: New desired gain 
# --- Output parameters 
- gain 	: Current radio gain
"""
function updateGain!(radio::UHDRx,gain)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	@info  "Try to change gain from $(radio.gain) dB to $(gain) dB";
	# Update the UHD sampling rate 
	ccall((:uhd_usrp_set_rx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t, Cstring),radio.uhd.pointerUSRP,gain,0,"");
	# Get the updated gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Cstring,Ref{Cdouble}),radio.uhd.pointerUSRP,0,"",pointerGain);
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
function updateCarrierFreq!(radio::UHDRx,carrierFreq)
	# ---------------------------------------------------- 
	# --- Carrier Frequency configuration  
	# ---------------------------------------------------- 
	@info  "Try to change carrier frequency from $(radio.carrierFreq/1e6) MHz to $(carrierFreq/1e6) MHz";
	tuneRequest   = uhd_tune_request_t(carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,UHD_TUNE_REQUEST_POLICY_AUTO);
	tunePointer	  = Ref{uhd_tune_request_t}(tuneRequest);	
	pointerTuneResult	  = Ref{uhd_tune_result}();	
	ccall((:uhd_usrp_set_rx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Ptr{uhd_tune_request_t}, Csize_t, Ptr{uhd_tune_result}),radio.uhd.pointerUSRP,tunePointer,0,pointerTuneResult);
	pointerCarrierFreq = Ref{Cdouble}(0);
	sleep(0.001);
	ccall((:uhd_usrp_get_rx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}),radio.uhd.pointerUSRP,0,pointerCarrierFreq); 
	updateCarrierFreq	= pointerCarrierFreq[];
	if updateCarrierFreq != carrierFreq 
		@warn "Effective carrier frequency is $(updateCarrierFreq/1e6) MHz and not $(carrierFreq/1e6) MHz\n" 
	else 
		@info "Effective carrier frequency is $(updateCarrierFreq/1e6) MHz\n";
	end	
	radio.carrierFreq = updateCarrierFreq;
	return updateCarrierFreq;
end

""" 
Get a single buffer from the USRP device, and create all the necessary ressources

# --- Syntax 

sig	  = recv(radio,nbSamples)
# --- Input parameters 
- radio	  : UHD object [UHDRx]
- nbSamples : Desired number of samples [Int]
# --- Output parameters 
- sig	  : baseband signal from radio [Array{Complex{CFloat}},radio.packetSize]
"""
function recv(radio,nbSamples);
	# --- Create the global container 
	sigRx	= zeros(Complex{Cfloat},nbSamples); 
	# --- Populate the buffer 
	nbSamples = recv!(sigRx,radio);
	return sigRx 
end 



""" 
Get a single buffer from the USRP device, using the Buffer structure 

# --- Syntax 

recv!(sig,radio,nbSamples)
# --- Input parameters 
- sig	  : Complex signal to populate [Array{Complex{Cfloat}}]
- radio	  : UHD object [UHDRx]
- buffer  : Buffer object (obtained with setBuffer(radio)) [Buffer] 
# --- Output parameters 
- sig	  : baseband signal from radio [Array{Complex{Cfloat}},radio.packetSize]
"""
function recv!(sig,radio::UHDRx;nbSamples=0,offset=0)
	# --- Defined parameters for multiple buffer reception 
	filled		= false;
	# --- Fill the input buffer @ a specific offset 
	if offset == 0 
		posT		= Csize_t(0);
	else 
		posT 		= Csize_t(offset);
	end
	# --- Managing desired size and buffer size
	if nbSamples == 0
		# --- Fill all the buffer  
		# x2 as input is complex and we feed real words
		nbSamples	= Csize_t(length(sig));
	else 
		# ---  x2 as input is complex and we feed real words
		nbSamples 	= Csize_t(nbSamples);
		# --- Ensure that the allocation is possible
		@assert nbSamples < (length(sig)+posT) "Impossible to fill the buffer (number of samples > residual size";
	end
	while !filled 
		# --- Get a buffer: We should have radio.packetSize or less 
		# radio.packetSize is the complex size, so x2
		(posT+radio.packetSize> nbSamples) ? n = nbSamples - posT : n = radio.packetSize;
		# --- To avoid memcopy, we direclty feed the pointer at the appropriate solution
		ptr=Ref(Ptr{Cvoid}(pointer(sig,1+posT)));
		# --- Populate buffer with radio samples
		cSamples 	= populateBuffer!(radio,ptr,n);
		# cSamples  = populateBuffer!(radio,n);
		# --- Populate the complete buffer 
		# sig[posT .+ (1:cSamples)] .= reinterpret(Complex{Cfloat},@view radio.buffer.x[1:2cSamples]);
		# sig[posT .+ (1:cSamples)] .= reinterpret(Complex{Cfloat},radio.buffer.x[1:2cSamples]);
		# --- Update counters 
		posT += cSamples; 
		# @show Int(cSamples),Int(posT)
		# --- Breaking flag
		(posT == nbSamples) ? filled = true : filled = false;
	end
	return posT
end



""" 
Calling UHD function wrapper to fill a buffer 

# --- Syntax 

recv!(sig,radio,nbSamples)
# --- Input parameters 
- radio	  	: UHD object [UHDRx]
- ptr  		: Writable memory position [Ref{Ptr{Cvoid}}]
- nbSamples : Number of samples to acquire 
# --- Output parameters 
- nbSamp 	: Number of samples fill in buffer [Csize_t]
"""
function populateBuffer!(radio,ptr,nbSamples::Csize_t=0)
	# --- Getting number of samples 
	# If not specified, we get back to radio.packetSize
	if (nbSamples == Csize_t(0)) 
		nbSamples = radio.packetSize;
	end 
	#@assert nbSamples <= length(buffer.x) "Number of desired samples can not be greater than buffer size";
	# --- Effectively recover data
	# ccall((:uhd_rx_streamer_recv, libUHD), Cvoid,(Ptr{uhd_rx_streamer},Ptr{Ptr{Cvoid}},Csize_t,Ptr{Ptr{uhd_rx_metadata}},Cfloat,Cint,Ref{Csize_t}),radio.uhd.pointerStreamer,ptr,nbSamples,radio.uhd.addressMD,0.1,false,radio.uhd.pointerSamples);
	pointerSamples = Ref{Csize_t}(0);
	ccall((:uhd_rx_streamer_recv, libUHD), Cvoid,(Ptr{uhd_rx_streamer},Ptr{Ptr{Cvoid}},Csize_t,Ptr{Ptr{uhd_rx_metadata}},Cfloat,Cint,Ref{Csize_t}),radio.uhd.pointerStreamer,ptr,nbSamples,radio.uhd.addressMD,0.1,false,pointerSamples);
		# --- Pointer deferencing 
	return pointerSamples[];
end#



""" 
Returns the Error flag of the current UHD burst 

# --- Syntax 

flag = getError(radio)
# --- Input parameters 
- radio : UHD object [UHDRx]
# --- Output parameters 
- err	: Error Flag [error_code_t]
"""
function getError(radio::UHDRx)
	ptrErr = Ref{error_code_t}();
	ccall((:uhd_rx_metadata_error_code,libUHD), Cvoid,(Ptr{uhd_rx_metadata},Ref{error_code_t}),radio.uhd.pointerMD,ptrErr);
	return err = ptrErr[];
end


""" 
Return the timestamp of the last UHD burst 

# --- Syntax 

(second,fracSecond) = getTimestamp(radio)
# --- Input parameters 
- radio	  : UHD UHD object [UHDRx]
# --- Output parameters 
- second  : Second value for the flag [Int]
- fracSecond : Fractional second value [Float64]
"""
function getTimestamp(radio::UHDRx)
	ptrFullSec = Ref{FORMAT_LONG}();
	ptrFracSec = Ref{Cdouble}();
	ccall( (:uhd_rx_metadata_time_spec,libUHD), Cvoid, (Ptr{uhd_rx_metadata},Ref{FORMAT_LONG},Ref{Cdouble}),radio.uhd.pointerMD,ptrFullSec,ptrFracSec);
	return (ptrFullSec[],ptrFracSec[]);
end

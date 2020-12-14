

function initRxUHD(pointerUSRP)
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
	uhd  = UHDRxWrapper(true,pointerUSRP,streamerPointer,metadataPointer,addressStream,addressMD,pointerSamples);
	# @inforx("Done init \n");
	return uhd;
end


function openUHDRx(pointerUSRP,carrierFreq,samplingRate,gain,antenna="RX2";args="",uhdArgs="");
	# --- Init Rx stage 
	uhd	  = initRxUHD(pointerUSRP);
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
	ccall((:uhd_usrp_set_rx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t),pointerUSRP,samplingRate,0);
	# --- Get the Rx rate from the radio 
	pointerRate  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}),pointerUSRP,0,pointerRate);
	updateRate  = pointerRate[];	
	# --- Print a flag 
	if updateRate != samplingRate 
		@warnrx "Effective Rate is $(updateRate/1e6) MHz and not $(samplingRate/1e6) MHz\n" 
	else 
		# @inforx "Effective Rate is $(updateRate/1e6) MHz\n";
	end
	# ---------------------------------------------------- 
	# --- Carrier Frequency configuration  
	# ---------------------------------------------------- 
	# --- Create structure for request 
	a5			   =  Base.unsafe_convert(Cstring,"");
	tuneRequest	   = uhd_tune_request_t(carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,200e6,a5);
	tunePointer	  = Ref{uhd_tune_request_t}(tuneRequest);	
	pointerTuneResult	  = Ref{uhd_tune_result}();	
	ccall((:uhd_usrp_set_rx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Ptr{uhd_tune_request_t}, Csize_t, Ptr{uhd_tune_result}),pointerUSRP,tunePointer,0,pointerTuneResult);
	pointerCarrierFreq = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}),pointerUSRP,0,pointerCarrierFreq); 
	updateCarrierFreq	= pointerCarrierFreq[];
	if updateCarrierFreq != carrierFreq 
		@warnrx "Effective carrier frequency is $(updateCarrierFreq/1e6) MHz and not $(carrierFreq/1e6) MHz\n" 
	else 
		# @inforx "Effective carrier frequency is $(updateCarrierFreq/1e6) MHz\n";
	end	
	# ---------------------------------------------------- 
	# --- Gain configuration  
	# ---------------------------------------------------- 
	# Update the UHD sampling rate 
	ccall((:uhd_usrp_set_rx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t, Cstring),pointerUSRP,gain,0,"");
	# Get the updated gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Cstring,Ref{Cdouble}),pointerUSRP,0,"",pointerGain);
	updateGain	  = pointerGain[]; 
	# --- Print a flag 
	if updateGain != gain 
		@warnrx "Effective gain is $(updateGain) dB and not $(gain) dB\n" 
	else 
		# @inforx "Effective gain is $(updateGain) dB\n";
	end 
	# ---------------------------------------------------- 
	# --- Antenna configuration 
	# ---------------------------------------------------- 
	ccall((:uhd_usrp_set_rx_antenna, libUHD), Cvoid, (Ptr{uhd_usrp}, Cstring, Csize_t),pointerUSRP,antenna,0);
	# ---------------------------------------------------- 
	# --- Setting up streamer  
	# ---------------------------------------------------- 
	# --- Setting up arguments 
	pointerArgs	  = Ref{uhd_stream_args_t}(uhdArgs);
	ccall((:uhd_usrp_get_rx_stream, libUHD), Cvoid, (Ptr{uhd_usrp},Ptr{uhd_stream_args_t},Ptr{uhd_rx_streamer}),pointerUSRP,pointerArgs,uhd.pointerStreamer);
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
	# --- Create the main Rx Object 
	rx = UHDRx(uhd,updateCarrierFreq,updateRate,updateGain,antenna,nbSamples,0);
end



function updateSamplingRate!(radio::UHDRx,samplingRate)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	# @inforx  "Try to change rate from $(radio.samplingRate/1e6) MHz to $(samplingRate/1e6) MHz";
	# --- Update the Rx sampling rate 
	ccall((:uhd_usrp_set_rx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t),radio.uhd.pointerUSRP,samplingRate,0);
	# --- Get the Rx rate from the radio 
	pointerRate  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}),radio.uhd.pointerUSRP,0,pointerRate);
	updateRate  = pointerRate[];	
	# --- Print a flag 
	if updateRate != samplingRate 
		@warnrx "Effective Rate is $(updateRate/1e6) MHz and not $(samplingRate/1e6) MHz\n" 
	else 
		# @inforx "Effective Rate is $(updateRate/1e6) MHz\n";
	end
	radio.samplingRate = updateRate;
end



function updateGain!(radio::UHDRx,gain)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	# @inforx  "Try to change gain from $(radio.gain) dB to $(gain) dB";
	# Update the UHD sampling rate 
	ccall((:uhd_usrp_set_rx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t, Cstring),radio.uhd.pointerUSRP,gain,0,"");
	# Get the updated gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_rx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Cstring,Ref{Cdouble}),radio.uhd.pointerUSRP,0,"",pointerGain);
	updateGain	  = pointerGain[]; 
	# --- Print a flag 
	if updateGain != gain 
		@warnrx "Effective gain is $(updateGain) dB and not $(gain) dB\n" 
	else 
		# @inforx "Effective gain is $(updateGain) dB\n";
	end 
	radio.gain = updateGain;
	return updateGain;
end


function updateCarrierFreq!(radio::UHDRx,carrierFreq)
	# ---------------------------------------------------- 
	# --- Carrier Frequency configuration  
	# ---------------------------------------------------- 
	# @inforx  "Try to change carrier frequency from $(radio.carrierFreq/1e6) MHz to $(carrierFreq/1e6) MHz";
	a5			   =  Base.unsafe_convert(Cstring,"");
	tuneRequest	   = uhd_tune_request_t(carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,200e6,a5)
	# tuneRequest   = uhd_tune_request_t(carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,UHD_TUNE_REQUEST_POLICY_AUTO);
	tunePointer	  = Ref{uhd_tune_request_t}(tuneRequest);	
	pointerTuneResult	  = Ref{uhd_tune_result}();	
	ccall((:uhd_usrp_set_rx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Ptr{uhd_tune_request_t}, Csize_t, Ptr{uhd_tune_result}),radio.uhd.pointerUSRP,tunePointer,0,pointerTuneResult);
	pointerCarrierFreq = Ref{Cdouble}(0);
	# sleep(0.001);
	ccall((:uhd_usrp_get_rx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}),radio.uhd.pointerUSRP,0,pointerCarrierFreq); 
	updateCarrierFreq	= pointerCarrierFreq[];
	if updateCarrierFreq != carrierFreq 
		@warnrx "Effective carrier frequency is $(updateCarrierFreq/1e6) MHz and not $(carrierFreq/1e6) MHz\n" 
	else 
		# @inforx "Effective carrier frequency is $(updateCarrierFreq/1e6) MHz\n";
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
-
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
Calling UHD function wrapper to fill a buffer. It is preferable to cal this function though the use of recv or recv!

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

function Base.close(radio::UHDRx)
	# --- Checking realease nature 
	# There is one flag to avoid double close (that leads to seg fault) 
	if radio.released == 0
		@assert_uhd ccall((:uhd_rx_streamer_free, libUHD), uhd_error, (Ptr{Ptr{uhd_rx_streamer}},),radio.uhd.addressStream);
		@assert_uhd ccall((:uhd_rx_metadata_free, libUHD), uhd_error, (Ptr{Ptr{uhd_rx_metadata}},),radio.uhd.addressMD);
	else 
		# print a warning  
		@warn "UHD ressource was already released, abort call";
	end 
	# --- Force flag value 
	radio.released = 1;
end

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
	@inforx "Current UHD Configuration in Rx mode\n$strF"; 
end

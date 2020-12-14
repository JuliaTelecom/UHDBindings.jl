

function initTxUHD(pointerUSRP)
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
	uhd  = UHDTxWrapper(true, pointerUSRP, streamerPointer, metadataPointer, addressStream, addressMD);
	# @infotx("Done init \n");
	return uhd;
end


function openUHDTx(pointerUSRP,carrierFreq, samplingRate, gain, antenna = "TX-RX";args="")
	# ---------------------------------------------------- 
	# --- Init  UHD object  
	# ---------------------------------------------------- 
	uhd	  = initTxUHD(pointerUSRP);
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
	ccall((:uhd_usrp_set_tx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t), pointerUSRP, samplingRate, 0);
	# --- Get the Tx rate from the radio 
	pointerRate  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}), pointerUSRP, 0, pointerRate);
	updateRate  = pointerRate[];	
	# --- Print a flag 
	if updateRate != samplingRate 
		@warntx "Effective Rate is $(updateRate / 1e6) MHz and not $(samplingRate / 1e6) MHz\n" 
	else 
		# @infotx "Effective Rate is $(updateRate / 1e6) MHz\n";
	end
	# ---------------------------------------------------- 
	# --- Carrier Frequency configuration  
	# ---------------------------------------------------- 
	# --- Create structure for request 
	a5			   =  Base.unsafe_convert(Cstring,"");
	tuneRequest	   = uhd_tune_request_t(carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,200e6,a5)
	# tuneRequest	   = uhd_tune_request_t(carrierFreq, UHD_TUNE_REQUEST_POLICY_AUTO, UHD_TUNE_REQUEST_POLICY_AUTO);
	tunePointer	  = Ref{uhd_tune_request_t}(tuneRequest);	
	pointerTuneResult	  = Ref{uhd_tune_result}();	
	ccall((:uhd_usrp_set_tx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Ptr{uhd_tune_request_t}, Csize_t, Ptr{uhd_tune_result}), pointerUSRP, tunePointer, 0, pointerTuneResult);
	pointerCarrierFreq = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}), pointerUSRP, 0, pointerCarrierFreq); 
	updateCarrierFreq	= pointerCarrierFreq[];
	if updateCarrierFreq != carrierFreq 
		@warntx "Effective carrier frequency is $(updateCarrierFreq / 1e6) MHz and not $(carrierFreq / 1e6) Hz\n" 
	else 
		# @infotx "Effective carrier frequency is $(updateCarrierFreq / 1e6) MHz\n";
	end	
	# ---------------------------------------------------- 
	# --- Gain configuration  
	# ---------------------------------------------------- 
	# Update the UHD sampling rate 
	ccall((:uhd_usrp_set_tx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t, Cstring), pointerUSRP, gain, 0, "");
	# Get the updated gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Cstring, Ref{Cdouble}), pointerUSRP, 0, "", pointerGain);
	updateGain	  = pointerGain[]; 
	# --- Print a flag 
	if updateGain != gain 
		@warntx "Effective gain is $(updateGain) dB and not $(gain) dB\n" 
	else 
		# @infotx "Effective gain is $(updateGain) dB\n";
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
	ccall((:uhd_usrp_get_tx_stream, libUHD), Cvoid, (Ptr{uhd_usrp}, Ptr{uhd_stream_args_t}, Ptr{uhd_tx_streamer}), pointerUSRP, pointerArgs, uhd.pointerStreamer);
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




function updateSamplingRate!(radio::UHDTx, samplingRate)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	# @infotx  "Try to change rate from $(radio.samplingRate / 1e6) MHz to $(samplingRate / 1e6) MHz";
	# --- Update the Tx sampling rate 
	ccall((:uhd_usrp_set_tx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t), radio.uhd.pointerUSRP, samplingRate, 0);
	# --- Get the Tx rate from the radio 
	pointerRate  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_rate, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}), radio.uhd.pointerUSRP, 0, pointerRate);
	updateRate  = pointerRate[];	
	# --- Print a flag 
	if updateRate != samplingRate 
		@warntx "Effective Rate is $(updateRate / 1e6) MHz and not $(samplingRate / 1e6) MHz\n" 
	else 
		# @infotx "Effective Rate is $(updateRate / 1e6) MHz\n";
	end
	radio.samplingRate = updateRate;
end



function updateGain!(radio::UHDTx, gain)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	# @infotx  "Try to change gain from $(radio.gain) dB to $(gain) dB";
	# Update the UHD sampling rate 
	ccall((:uhd_usrp_set_tx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Cdouble, Csize_t, Cstring), radio.uhd.pointerUSRP, gain, 0, "");
	# Get the updated gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_gain, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Cstring, Ref{Cdouble}), radio.uhd.pointerUSRP, 0, "", pointerGain);
	updateGain	  = pointerGain[]; 
	# --- Print a flag 
	if updateGain != gain 
		@warntx "Effective gain is $(updateGain) dB and not $(gain) dB\n" 
	else 
		# @infotx "Effective gain is $(updateGain) dB\n";
	end 
	radio.gain = updateGain;
	return updateGain;
end


function updateCarrierFreq!(radio::UHDTx, carrierFreq)
	# ---------------------------------------------------- 
	# --- Carrier Frequency configuration  
	# ---------------------------------------------------- 
	# @infotx  "Try to change carrier frequency from $(radio.carrierFreq / 1e6) MHz to $(carrierFreq / 1e6) MHz";
	a5			   =  Base.unsafe_convert(Cstring,"");
	tuneRequest	   = uhd_tune_request_t(carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,200e6,a5)
	# tuneRequest   = uhd_tune_request_t(carrierFreq, UHD_TUNE_REQUEST_POLICY_AUTO, UHD_TUNE_REQUEST_POLICY_AUTO);
	tunePointer	  = Ref{uhd_tune_request_t}(tuneRequest);	
	pointerTuneResult	  = Ref{uhd_tune_result}();	
	ccall((:uhd_usrp_set_tx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Ptr{uhd_tune_request_t}, Csize_t, Ptr{uhd_tune_result}), radio.uhd.pointerUSRP, tunePointer, 0, pointerTuneResult);
	pointerCarrierFreq = Ref{Cdouble}(0);
	ccall((:uhd_usrp_get_tx_freq, libUHD), Cvoid, (Ptr{uhd_usrp}, Csize_t, Ref{Cdouble}), radio.uhd.pointerUSRP, 0, pointerCarrierFreq); 
	updateCarrierFreq	= pointerCarrierFreq[];
	if updateCarrierFreq != carrierFreq 
		@warntx "Effective carrier frequency is $(updateCarrierFreq / 1e6) MHz and not $(carrierFreq / 1e6) MHz\n" 
	else 
		# @infotx "Effective carrier frequency is $(updateCarrierFreq / 1e6) MHz\n";
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
"""
function send(radio::UHDTx, buffer::Union{Array{Complex{Cfloat}},Array{Cfloat}}, cyclic::Bool = false)
	# --- Pointer to number of samples transmitted 
	pointerSamples 	= Ref{Csize_t}(0);
	# --- Size of buffer 
	# We should handle Complex and non complex inputs 
	# If Complex, we have length(buffer) elements. If input is not complex, half element are effectively transmitted (real, imag, real, imag...) and we have length(buffer)÷2.
	# This can done in one instruction with sizeof(Cfloat) and sizeof(buffer)
	nbSamples 				= sizeof(buffer) ÷ sizeof(Cfloat) ÷ 2;
	# --- Fragmentation handling
	posT 	= Csize_t(0);
	filled 	= false;
	# --- Accumulated value of number of samples transmitted
	nbEch 			= Csize_t(0);
	try 
		# --- First while loop is to handle cyclic transmission 
		# It turns to false in case of interruption or cyclic to false 
		while (true)
			# --- Getting pointer position
			(posT+radio.packetSize> nbSamples) ? n = nbSamples - posT : n = radio.packetSize;
			# --- Create pointer pointing to the fragment
			ptr=Ref(Ptr{Cvoid}(pointer(buffer,1+posT)));
			# --- Effectively transmit data
			ccall((:uhd_tx_streamer_send, libUHD), uhd_error, (Ptr{uhd_tx_streamer}, Ptr{Ptr{Cvoid}}, Csize_t, Ptr{Ptr{uhd_tx_metadata}}, Cfloat, Ref{Csize_t}), radio.uhd.pointerStreamer, ptr, n, radio.uhd.addressMD, 0.1, pointerSamples);
			# --- Getting number of transmitted samples
			nbEch 		+= pointerSamples[];
			posT 		+= pointerSamples[];
			(posT == nbSamples) ? filled = true : filled = false;
			# --- Detection of cyclic mode 
			(cyclic == false && filled == true) && break 
			# --- We are in cyclic mode here 
			if filled == true 
				# --- We are not out and filled is true => cyclic is true and we have done one complete Tx buffer transmit. We shall reinit all the counters here 
				posT 	= 0;
				# --- Filled to false 
				filled = false;
			end
			# --- Forcing refresh
			yield();
		end 
	catch e;
		# --- Interruption handling
		print(e);
		print("\n");
		@infotx "Interruption detected";
        return Csize_t(0);
	end
	# --- Return number of complex samples transmitted
	# We accumulate number of samples transmitted, we should divide by 2 to get number of Complex samples
	return (nbEch ÷ 2);
end

function Base.close(radio::UHDTx)
	# --- Checking realease nature 
	# There is one flag to avoid double free (that leads to seg fault) 
	if radio.released == 0
		# C Wrapper to ressource release 
		@assert_uhd ccall((:uhd_tx_streamer_free, libUHD), uhd_error, (Ptr{Ptr{uhd_tx_streamer}},), radio.uhd.addressStream);
		@assert_uhd ccall((:uhd_tx_metadata_free, libUHD), uhd_error, (Ptr{Ptr{uhd_tx_metadata}},), radio.uhd.addressMD);
	else 
		# print a warning  
		@warn "UHD ressource was already released, abort call";
	end 
	# --- Force flag value 
	radio.released = 1;
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
	@infotx "Current UHD Configuration in Tx mode\n$strF"; 
end


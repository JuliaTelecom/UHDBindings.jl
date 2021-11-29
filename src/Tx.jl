

function initTxUHD(pointerUSRP)
	# ---------------------------------------------------- 
	# --- Tx Streamer  
	# ---------------------------------------------------- 
	# --- Create a pointer related to the Tx streamer
	addressStream = Ref{Ptr{uhd_tx_streamer}}(); 
	# --- Cal the init
    @assert_uhd uhd_tx_streamer_make(addressStream)
	streamerPointer = addressStream[];
	# ---------------------------------------------------- 
	# --- Tx Metadata  
	# ---------------------------------------------------- 
	# --- Create a pointer related to Metadata 
	addressMD = Ref{Ptr{uhd_tx_metadata_t}}(); 
	# --- Cal the init
    @assert_uhd uhd_tx_metadata_make(addressMD,false,0,0.1,true,false)
	# --- Get the usable object 
	metadataPointer = addressMD[];
	# ---------------------------------------------------- 
	# --- Create the USRP wrapper object  
	# ---------------------------------------------------- 
	uhd  = UHDTxWrapper(true, pointerUSRP, streamerPointer, metadataPointer, addressStream, addressMD);
	# @infotx("Done init \n");
	return uhd;
end


function openUHDTx(pointerUSRP,carrierFreq, samplingRate, gain;channels=[0],antennas=["TRX"],args="",nbAntennaTx=1,cpu_format="fc32",otw_format="sc16",subdev="",bypassStreamer=false); 
    # ----------------------------------------------------
    # --- Parameter checks 
    # ---------------------------------------------------- 
    # --- MIMO mode shortcut
    (nbAntennaTx == 2) ? MIMO_MODE = true  : MIMO_MODE = false 
    @assert (nbAntennaTx) ≤ length(antennas) "Mismatch in antenna configuration. Number of Rx antennas should match the string vector of antenna"
    @assert (nbAntennaTx) ≤ length(channels) "Number of Tx antennas should be lower than number of channels"
    # ----------------------------------------------------
    # --- Core structure definitions
    # ---------------------------------------------------- 
	# --- Init Tx stage 
	uhd	  = initTxUHD(pointerUSRP);
    # --- Create the structure to be updated 
    tx = UHDTx(uhd,carrierFreq,samplingRate,gain,antennas,channels,0,0,nbAntennaTx);
	# ---------------------------------------------------- 
	# --- Radio configuration
	# ---------------------------------------------------- 
    # --- RF Configuration 
    for (c,currChan) in enumerate(channels[1:nbAntennaTx])
        # Set the carrier frequencies 
        updateCarrierFreq!(tx,carrierFreq,currChan)
        # Set the sampling rate 
        updateSamplingRate!(tx,samplingRate,currChan)
        # Set the gains 
        updateGain!(tx,gain,currChan)
        # Set the antennas
        uhd_usrp_set_tx_antenna(uhd.pointerUSRP,antennas[c],currChan)
    end
    # --- Custom subdev use
    # Should be done @Rx side => no need to redo this
    # if !isempty(subdev)
        # # --- Custom Subdev use 
        # pointerSubDev = Ref{uhd_subdev_spec_handle}()
        # @assert_uhd uhd_subdev_spec_make(pointerSubDev,subdev)
        # @assert_uhd uhd_usrp_set_rx_subdev_spec(tx.uhd.pointerUSRP,pointerSubDev[],0)
        # uhd_subdev_spec_free(pointerSubDev)
    # else 
        # # Default configuration for subdev. It should leads to issues with multiple antenna (at least in e310)
        # if nbAntennaTx > 1 
            # @warn "Multiple channels (antennas)  with default subdev config may leads to recv issue. Please use subdev=\"A:0 A:1\" to configure multiple subdev"  
    # end
    # ----------------------------------------------------
    # --- Clock managment
    # ---------------------------------------------------- 
    # --- Internal streamer and buffer config
    if MIMO_MODE 
        # --- Clock source 
        @assert_uhd LibUHD.uhd_usrp_set_clock_source(tx.uhd.pointerUSRP,"internal",0)
        @assert_uhd LibUHD.uhd_usrp_set_time_now(tx.uhd.pointerUSRP,0,0,0)
    end
	# ---------------------------------------------------- 
	# --- Setting up streamer  
	# ---------------------------------------------------- 
    if (bypassStreamer == false) && (nbAntennaTx > 0)
        # --- Streamer arguments 
        a1			   =  Base.unsafe_convert(Cstring,cpu_format);
        a2			   =  Base.unsafe_convert(Cstring,otw_format);
        a3			   =  Base.unsafe_convert(Cstring,args);
        channel        = pointer(channels)
        uhdArgs	       = uhd_stream_args_t(a1,a2,a3,channel,nbAntennaTx);
        # --- Setting up arguments 
        pointerArgs	  = Ref{uhd_stream_args_t}(uhdArgs);
        uhd_usrp_get_tx_stream( pointerUSRP, pointerArgs, uhd.pointerStreamer);
        # --- Getting number of samples ber buffer 
        pointerSamples	  = Ref{Csize_t}(0);
        uhd_tx_streamer_max_num_samps( uhd.pointerStreamer, pointerSamples);
        nbSamples		  = pointerSamples[];
        tx.packetSize = nbSamples
    end
    return tx
end




function updateSamplingRate!(radio::UHDTx, samplingRate,chan=0)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	# @infotx  "Try to change rate from $(radio.samplingRate / 1e6) MHz to $(samplingRate / 1e6) MHz";
	# --- Update the Tx sampling rate 
    uhd_usrp_set_tx_rate(radio.uhd.pointerUSRP, samplingRate, chan);
	# --- Get the Tx rate from the radio 
	pointerRate  = Ref{Cdouble}(0);
    uhd_usrp_get_tx_rate(radio.uhd.pointerUSRP, chan, pointerRate);
	updateRate  = pointerRate[];	
	# --- Print a flag 
	if updateRate != samplingRate 
		@warntx "Effective Rate is $(updateRate / 1e6) MHz and not $(samplingRate / 1e6) MHz\n" 
	else 
		# @infotx "Effective Rate is $(updateRate / 1e6) MHz\n";
	end
	radio.samplingRate = updateRate;
end



function updateGain!(radio::UHDTx, gain,chan=0)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	# @infotx  "Try to change gain from $(radio.gain) dB to $(gain) dB";
	# Update the UHD sampling rate 
    uhd_usrp_set_tx_gain(radio.uhd.pointerUSRP, gain, chan, "");
	# Get the updated gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
    uhd_usrp_get_tx_gain(radio.uhd.pointerUSRP, chan, "", pointerGain);
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


function updateCarrierFreq!(radio::UHDTx, carrierFreq,chan=0)
	# ---------------------------------------------------- 
	# --- Carrier Frequency configuration  
	# ---------------------------------------------------- 
	# @infotx  "Try to change carrier frequency from $(radio.carrierFreq / 1e6) MHz to $(carrierFreq / 1e6) MHz";
	a5			   =  Base.unsafe_convert(Cstring,"");
	tuneRequest	   = uhd_tune_request_t(carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,200e6,a5)
	# tuneRequest   = uhd_tune_request_t(carrierFreq, UHD_TUNE_REQUEST_POLICY_AUTO, UHD_TUNE_REQUEST_POLICY_AUTO);
	tunePointer	  = Ref{uhd_tune_request_t}(tuneRequest);	
	pointerTuneResult	  = Ref{uhd_tune_result_t}();	
    uhd_usrp_set_tx_freq(radio.uhd.pointerUSRP, tunePointer, chan, pointerTuneResult);
	pointerCarrierFreq = Ref{Cdouble}(0);
    uhd_usrp_get_tx_freq(radio.uhd.pointerUSRP, chan, pointerCarrierFreq); 
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
            uhd_tx_streamer_send(radio.uhd.pointerStreamer, ptr, n, radio.uhd.addressMD, 0.1, pointerSamples);
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
        @assert_uhd uhd_tx_streamer_free(radio.uhd.addressStream);
        @assert_uhd uhd_tx_metadata_free(radio.uhd.addressMD);
	else 
		# print a warning  
		@warn "UHD ressource was already released, abort call";
	end 
	# --- Force flag value 
	radio.released = 1;
end

function Base.print(radio::UHDTx,chan=0)
	# Get the gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
    uhd_usrp_get_tx_gain(radio.uhd.pointerUSRP, chan, "", pointerGain);
	updateGain	  = pointerGain[]; 
	# Get the rate from UHD 
	pointerRate	  = Ref{Cdouble}(0);
    uhd_usrp_get_tx_rate(radio.uhd.pointerUSRP, chan, pointerRate);
	updateRate	  = pointerRate[]; 
	# Get the freq from UHD 
	pointerFreq	  = Ref{Cdouble}(0);
    uhd_usrp_get_tx_freq(radio.uhd.pointerUSRP, chan, pointerFreq);
	updateFreq	  = pointerFreq[];
	# Print message 
	strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Tx Gain: %2.2f dB\n",updateFreq / 1e6,updateRate / 1e6,updateGain);
	@infotx "Current UHD Configuration in Tx mode\n$strF"; 
end


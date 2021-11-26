function initRxUHD(pointerUSRP)
	# ---------------------------------------------------- 
	# --- Rx Streamer  
	# ---------------------------------------------------- 
	# --- Create a pointer related to the Rx streamer
	addressStream = Ref{uhd_rx_streamer_handle}(); 
	# --- Cal the init
    @assert_uhd uhd_rx_streamer_make(addressStream)
	streamerPointer = addressStream[];
	# ---------------------------------------------------- 
	# --- Rx Metadata  
	# ---------------------------------------------------- 
	# --- Create a pointer related to Metadata 
	addressMD = Ref{uhd_rx_metadata_handle}(); 
	# --- Cal the init
    @assert_uhd uhd_rx_metadata_make(addressMD)
	# --- Get the usable object 
	metadataPointer = addressMD[];
# --- Pointer for counting number of samples 
	pointerSamples = Ref{Csize_t}(0);
	# ---------------------------------------------------- 
	# --- Create the USRP wrapper object  
	# ---------------------------------------------------- 
	uhd  = UHDRxWrapper(true,pointerUSRP,streamerPointer,metadataPointer,addressStream,addressMD,pointerSamples);
	return uhd;
end


function openUHDRx(pointerUSRP,carrierFreq,samplingRate,gain;channels=[0],antennas=["RX2"],args="",nbAntennaRx=1,cpu_format="fc32",otw_format="sc16",subdev="",bypassStreamer=false);
    # ----------------------------------------------------
    # --- Parameter checks 
    # ---------------------------------------------------- 
    # --- MIMO mode shortcut
    (nbAntennaRx == 2) ? MIMO_MODE = true  : MIMO_MODE = false 
    @assert (nbAntennaRx) ≤ length(antennas) "Mismatch in antenna configuration. Number of Rx antennas should match the string vector of antenna"
    @assert (nbAntennaRx) ≤ length(channels) "Number of Rx antennas should be lower than number of channels"
    # ----------------------------------------------------
    # --- Core structure definitions
    # ---------------------------------------------------- 
    # --- Init Rx stage 
    uhd	  = initRxUHD(pointerUSRP);
    # --- Create the structure to be updated 
    rx = UHDRx(uhd,carrierFreq,samplingRate,gain,antennas,channels,0,0,nbAntennaRx);
    # ---------------------------------------------------- 
    # --- Radio configuration
    # ---------------------------------------------------- 
    # --- RF Configuration 
    for (c,currChan) in enumerate(channels[1:nbAntennaRx])
        # Set the carrier frequencies 
        updateCarrierFreq!(rx,carrierFreq,currChan)
        # Set the sampling rate 
        updateSamplingRate!(rx,samplingRate,currChan)
        # Set the gains 
        updateGain!(rx,gain,currChan)
        # Set the antennas
        uhd_usrp_set_rx_antenna(uhd.pointerUSRP,antennas[c],currChan)
    end
    # --- Custom subdev use
    if !isempty(subdev)
        # --- Custom Subdev use 
        pointerSubDev = Ref{uhd_subdev_spec_handle}()
        @assert_uhd uhd_subdev_spec_make(pointerSubDev,subdev)
        @assert_uhd uhd_usrp_set_rx_subdev_spec(rx.uhd.pointerUSRP,pointerSubDev[],0)
        uhd_subdev_spec_free(pointerSubDev)
    else 
        # Default configuration for subdev. It should leads to issues with multiple antenna (at least in e310)
        if nbAntennaRx > 1 
            @warn "Multiple channels (antennas)  with default subdev config may leads to recv issue. Please use subdev=\"A:0 A:1\" to configure multiple subdev"  
        end
    end
    # --- Internal streamer and buffer config
    if MIMO_MODE 
        # --- Clock source 
        @assert_uhd LibUHD.uhd_usrp_set_clock_source(rx.uhd.pointerUSRP,"internal",0)
        @assert_uhd LibUHD.uhd_usrp_set_time_now(rx.uhd.pointerUSRP,0,0,0)
    end
    # ----------------------------------------------------
    # --- Set up streamer 
    # ---------------------------------------------------- 
    # Streamer policy depends on MIMO mode or not
    # It can be a pain to have one ssytem for every possible configurations, so one can want to define streamer policy later 
    if nbAntennaRx > 0 && bypassStreamer == false 
        if MIMO_MODE 
            uhd_usrp_create_stream(rx;
                                   nbAntennaRx,
                                   channels,
                                   cpu_format,
                                   otw_format,
                                   args,
                                   stream_mode = UHD_STREAM_MODE_NUM_SAMPS_AND_DONE,
                                   stream_now = false,
                                   full_sec_delay = 1,
                                   frac_sec_delay = 0.5,
                                   num_samps = 10_000_000
                                  )
        else 
            uhd_usrp_create_stream(rx;
                                   nbAntennaRx,
                                   channels,
                                   cpu_format,
                                   otw_format,
                                   args,
                                   stream_mode = UHD_STREAM_MODE_START_CONTINUOUS,
                                   stream_now = true,
                                   full_sec_delay = 0,
                                   frac_sec_delay = 0,
                                   num_samps = rx.packetSize
                                  )
        end
    else 
        (nbAntennaRx > 0 ) &&  @warn "Streamer has not be set up as bypassStreamer has been set to true. Rx will not work without create a dedicated streamer and set up the streamer policy. See uhd_usrp_create_stream to create a streamer with custom parameters"
    end
    return rx
end


""" 
Create and launch a streamer with dedicated parameters 
"""
function uhd_usrp_create_stream(rx::UHDRx;nbAntennaRx = 1, channels=[0],cpu_format="fc32",otw_format="sc16",args="",stream_mode=UHD_STREAM_MODE_START_CONTINUOUS,stream_now=true,full_sec_delay=0,frac_sec_delay=0,num_samps=-1)
        # --- Streamer arguments
        a1			   =  Base.unsafe_convert(Cstring,cpu_format);
        a2			   =  Base.unsafe_convert(Cstring,otw_format);
        a3			   =  Base.unsafe_convert(Cstring,args);
        channel        = pointer(channels)
        uhdArgs_0	   = uhd_stream_args_t(a1,a2,a3,channel,nbAntennaRx);
        pointerArgs	  = Ref{uhd_stream_args_t}(uhdArgs_0);
        pointerSamples = Ref{Csize_t}(0);
        # --- Get internal buffer size
        @assert_uhd uhd_usrp_get_rx_stream(rx.uhd.pointerUSRP,pointerArgs,rx.uhd.pointerStreamer)
        @assert_uhd uhd_rx_streamer_max_num_samps(rx.uhd.pointerStreamer,pointerSamples)
        rx.packetSize= pointerSamples[]
        # --- Launch the stream
        restartStreamer(rx;stream_mode,num_samps,stream_now,full_sec_delay,frac_sec_delay)
end

""" 
Restart the USRP streamer. In some cases (especially macOS) we have an issue with streamer congestion and we need to restart it. 
By now, we have added the restart function in recv! method.
"""
@inline function restartStreamer(rx::UHDRx;stream_mode=UHD_STREAM_MODE_START_CONTINUOUS,num_samps=-1,stream_now=true,full_sec_delay=0,frac_sec_delay=0)
    # ----------------------------------------------------
    # --- Start the streamer 
    # ---------------------------------------------------- 
    (num_samps == -1) && (num_samps = rx.packetSize)
    streamCmd	= UHDBindings.uhd_stream_cmd_t(stream_mode,num_samps,stream_now,full_sec_delay,frac_sec_delay);
    pointerCmd	= Ref{uhd_stream_cmd_t}(streamCmd);
    uhd_rx_streamer_issue_stream_cmd(rx.uhd.pointerStreamer,pointerCmd)

end

function updateSamplingRate!(radio::UHDRx,samplingRate,chan=0)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	# @inforx  "Try to change rate from $(radio.samplingRate/1e6) MHz to $(samplingRate/1e6) MHz";
	# --- Update the Rx sampling rate 
    uhd_usrp_set_rx_rate(radio.uhd.pointerUSRP,samplingRate,chan) 
	# --- Get the Rx rate from the radio 
	pointerRate  = Ref{Cdouble}(0);
    uhd_usrp_get_rx_rate(radio.uhd.pointerUSRP,chan,pointerRate)
	updateRate  = pointerRate[];	
	# --- Print a flag 
	if updateRate != samplingRate 
		@warnrx "Effective Rate is $(updateRate/1e6) MHz and not $(samplingRate/1e6) MHz\n" 
	else 
		# @inforx "Effective Rate is $(updateRate/1e6) MHz\n";
	end
	radio.samplingRate = updateRate;
end


function updateGain!(radio::UHDRx,gain,chan=0)
	# ---------------------------------------------------- 
	# --- Sampling rate configuration  
	# ---------------------------------------------------- 
	# @inforx  "Try to change gain from $(radio.gain) dB to $(gain) dB";
	# Update the UHD sampling rate 
    uhd_usrp_set_rx_gain(radio.uhd.pointerUSRP,gain,chan,"")
	# Get the updated gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
    uhd_usrp_get_rx_gain(radio.uhd.pointerUSRP,chan,"",pointerGain)
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


function updateCarrierFreq!(radio::UHDRx,carrierFreq,chan=0)
	# ---------------------------------------------------- 
	# --- Carrier Frequency configuration  
	# ---------------------------------------------------- 
	# @inforx  "Try to change carrier frequency from $(radio.carrierFreq/1e6) MHz to $(carrierFreq/1e6) MHz";
	a5			   =  Base.unsafe_convert(Cstring,"");
	tuneRequest	   = uhd_tune_request_t(carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,200e6,a5)
	# tuneRequest   = uhd_tune_request_t(carrierFreq,UHD_TUNE_REQUEST_POLICY_AUTO,UHD_TUNE_REQUEST_POLICY_AUTO);
	tunePointer	  = Ref{uhd_tune_request_t}(tuneRequest);	
	pointerTuneResult	  = Ref{uhd_tune_result_t}();	
    uhd_usrp_set_rx_freq(radio.uhd.pointerUSRP,tunePointer,chan,pointerTuneResult)
	pointerCarrierFreq = Ref{Cdouble}(0);
	# sleep(0.001);
    uhd_usrp_get_rx_freq(radio.uhd.pointerUSRP,chan,pointerCarrierFreq)
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
function recv(radio::UHDRx,nbSamples);
        # --- Populate the buffer 
        sig     = [zeros(Complex{Cfloat},nbSamples) for _ ∈ 1:radio.nbAntennaRx]
        nbSamples = recv!(sig,radio);
        if radio.nbAntennaRx == 1 
            # In SISO mode, we return a vector 
            return sig[1]
        else 
            # In MIMO mode, we return a vector of vector 
            return sig 
        end
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
function recv!(sig::Vector{Vector{Complex{T}}},radio::UHDRx;nbSamples=0,offset=0) where T
    # restartStreamer(radio)
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
        nbSamples	= Csize_t(length(sig[1]));
	else 
		# ---  x2 as input is complex and we feed real words
		nbSamples 	= Csize_t(nbSamples);
		# --- Ensure that the allocation is possible
        @assert nbSamples < (length(sig[1])+posT) "Impossible to fill the buffer (number of samples > residual size";
	end
	while !filled 
		# --- Get a buffer: We should have radio.packetSize or less 
		# radio.packetSize is the complex size, so x2
		(posT+radio.packetSize> nbSamples) ? n = nbSamples - posT : n = radio.packetSize;
		# --- To avoid memcopy, we direclty feed the pointer at the appropriate solution
        ptr = [pointer(sig[n],1+posT) for n ∈ 1 : radio.nbAntennaRx]
		# --- Populate buffer with radio samples
		cSamples 	= populateBuffer!(radio,ptr,n);
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
	pointerSamples = Ref{Csize_t}(0);
    uhd_rx_streamer_recv(radio.uhd.pointerStreamer,ptr,nbSamples,radio.uhd.addressMD,0.1,false,pointerSamples)
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
	ptrErr = Ref{uhd_rx_metadata_error_code_t}();
    uhd_rx_metadata_error_code(radio.uhd.pointerMD,ptrErr)
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
    uhd_rx_metadata_time_spec(radio.uhd.pointerMD,ptrFullSec,ptrFracSec)
	return (ptrFullSec[],ptrFracSec[]);
end

function Base.close(radio::UHDRx)
	# --- Checking realease nature 
	# There is one flag to avoid double close (that leads to seg fault) 
	if radio.released == 0
        @assert_uhd uhd_rx_streamer_free(radio.uhd.addressStream) 
        @assert_uhd uhd_rx_metadata_free(radio.uhd.addressMD)
	else 
		# print a warning  
		@warn "UHD ressource was already released, abort call";
	end 
	# --- Force flag value 
	radio.released = 1;
end

function Base.print(radio::UHDRx,chan=0)
	# Get the gain from UHD 
	pointerGain	  = Ref{Cdouble}(0);
    uhd_usrp_get_rx_gain(radio.uhd.pointerUSRP,chan,"",pointerGain)
	updateGain	  = pointerGain[]; 
	# Get the rate from UHD 
	pointerRate	  = Ref{Cdouble}(0);
    uhd_usrp_get_rx_rate(radio.uhd.pointerUSRP,chan,pointerRate)
	updateRate	  = pointerRate[]; 
	# Get the freq from UHD 
	pointerFreq	  = Ref{Cdouble}(0);
    uhd_usrp_get_rx_freq(radio.uhd.pointerUSRP,chan,pointerFreq)
	updateFreq	  = pointerFreq[];
	# Print message 
	strF  = @sprintf(" Carrier Frequency: %2.3f MHz\n Sampling Frequency: %2.3f MHz\n Rx Gain: %2.2f dB\n",updateFreq/1e6,updateRate/1e6,updateGain);
	@inforx "Current UHD Configuration in Rx mode\n$strF"; 
end

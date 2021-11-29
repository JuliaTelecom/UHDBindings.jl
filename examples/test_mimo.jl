using UHDBindings 
import UHDBindings.LibUHD as LibUHD

import UHDBindings.initRxUHD
import UHDBindings.@assert_uhd

# ----------------------------------------------------
# --- Tools 
# ---------------------------------------------------- 
""" 
Init an empty string of size n, filled with space. Usefull to have container to get string from UHD.
"""
initEmptyString(n) = String(ones(UInt8,n)*UInt8(32))
""" 
Retrict the big string used as log container to its usefull part 
"""
truncate(s::String) = s[1 : findfirst("\0",s)[1] - 1]
""" 
Interrupt the script just at right place 
"""
stop() = error("Decide to stop the script. Be sure to release all ressources")
# ----------------------------------------------------
# --- Parameters 
# ---------------------------------------------------- 
carrierFreq = 868e6
samplingRate= 2e6
gain        = 25
# uhdArgs     = "num_recv_frames=1000"
uhdArgs     = ""
nbAntennaRx = 2

# ----------------------------------------------------
# --- Address extraction
# ---------------------------------------------------- 
# allR  = uhd_find_devices()
# extractAddr(x) = x[1][findfirst("_addr=",x[1])[end] .+ (1:13)]
# addr  = extractAddr(allR)

# ---------------------------------------------------- 
# --- Create radio 
# ---------------------------------------------------- 
# --- Open radio, in MIMO mode 
# Note the warning about the streamer. It can not be set in MIMO mode 
# The configuration will be updated later, and most of the parameters overwritten
# To ensure we have what we want, we need to bypass the streamer, and deactivate all antennas
radio = openUHD(carrierFreq,samplingRate,gain;nbAntennaRx=0,nbAntennaTx=0,bypassStreamer = true)

# ----------------------------------------------------
# --- Set up Radio 
# ---------------------------------------------------- 
# --- Channels  & Antenna 
channelIndexes = [0,1]
antennas       = ["TX/RX","RX2"]
# --- Streamer arguments
a1			   =  Base.unsafe_convert(Cstring,"fc32");
a2			   =  Base.unsafe_convert(Cstring,"sc16");
a3			   =  Base.unsafe_convert(Cstring,uhdArgs);
channel        = pointer(channelIndexes)
uhdArgs_0	   = LibUHD.uhd_stream_args_t(a1,a2,a3,channel,nbAntennaRx);
# --- RF Configuration 
for (c,currChan) in enumerate(channelIndexes[1:nbAntennaRx])
    # Set the carrier frequencies 
    updateCarrierFreq!(radio.rx,carrierFreq,currChan)
    # Set the sampling rate 
    updateSamplingRate!(radio.rx,samplingRate,currChan)
    # Set the gains 
    updateGain!(radio.rx,gain,currChan)
    # Set the antennas
    LibUHD.uhd_usrp_set_rx_antenna(radio.rx.uhd.pointerUSRP,antennas[c],currChan)
end
# --- Subdev with 2 boards
pointerSubDev = Ref{LibUHD.uhd_subdev_spec_handle}()
@assert_uhd LibUHD.uhd_subdev_spec_make(pointerSubDev,"A:0 A:1")
@assert_uhd LibUHD.uhd_usrp_set_rx_subdev_spec(radio.rx.uhd.pointerUSRP,pointerSubDev[],0)
LibUHD.uhd_subdev_spec_free(pointerSubDev)
# --- Internal streamer and buffer config
pointerArgs	  = Ref{LibUHD.uhd_stream_args_t}(uhdArgs_0);
pointerSamples = Ref{Csize_t}(0);
@assert_uhd LibUHD.uhd_usrp_get_rx_stream(radio.rx.uhd.pointerUSRP,pointerArgs,radio.rx.uhd.pointerStreamer)
@assert_uhd LibUHD.uhd_rx_streamer_max_num_samps(radio.rx.uhd.pointerStreamer,pointerSamples)
println("Internal buffer size is $(pointerSamples[])")
radio.rx.packetSize= pointerSamples[]
# --- Clock source 
@assert_uhd LibUHD.uhd_usrp_set_clock_source(radio.rx.uhd.pointerUSRP,"internal",0)
@assert_uhd LibUHD.uhd_usrp_set_time_now(radio.rx.uhd.pointerUSRP,0,0,0)

# ----------------------------------------------------
# --- Set up streamer 
# ---------------------------------------------------- 
streamCmd	= UHDBindings.uhd_stream_cmd_t(UHDBindings.UHD_STREAM_MODE_NUM_SAMPS_AND_MORE,radio.rx.packetSize*10_000,false,1,0.5);
# streamCmd	= UHDBindings.uhd_stream_cmd_t(UHDBindings.UHD_STREAM_MODE_NUM_SAMPS_AND_MORE,rx.packetSize,true,0,0);
pointerCmd	= Ref{UHDBindings.uhd_stream_cmd_t}(streamCmd);
LibUHD.uhd_rx_streamer_issue_stream_cmd(radio.rx.uhd.pointerStreamer,pointerCmd)
sleep(0.1)
# ---------------------------------------------------- 
# --- Julia buffers 
# ---------------------------------------------------- 	
# Define an array to get all the buffers from all the channels 
nbSamples             = getBufferSize(radio)
sig                   = [zeros(Complex{Cfloat},radio.rx.packetSize) for n ∈ 1:nbAntennaRx]
listBuffer            = [pointer(sig[n],1) for n ∈ 1 : nbAntennaRx]
# ptr                   = Ref(Ptr{Cvoid}(listBuffer[1]))
ptr                   = listBuffer
pointerCounterSamples = Ref{Csize_t}(0);

# ----------------------------------------------------
# --- Receive data 
# ---------------------------------------------------- 
pointerCounterSamples = Ref{Csize_t}(0);
LibUHD.uhd_rx_streamer_recv(radio.rx.uhd.pointerStreamer,ptr,nbSamples,radio.rx.uhd.addressMD,1.6,true,pointerCounterSamples)
nbReceivedSamples = pointerCounterSamples[]
println("Receive $nbReceivedSamples samples")


# ----------------------------------------------------
# --- Second call 
# ---------------------------------------------------- 
accum = 0
# UHDBindings.restartStreamer(rx)
for iN = 1 : 1 : 10_000
    pointerCounterSamples = Ref{Csize_t}(0);
    LibUHD.uhd_rx_streamer_recv(radio.rx.uhd.pointerStreamer,ptr,nbSamples,radio.rx.uhd.addressMD,0,true,pointerCounterSamples)
    nbReceivedSamples = pointerCounterSamples[]
    global accum += nbReceivedSamples
end
println("End of transmission, received $accum samples")

# ----------------------------------------------------
# --- Logs
# ---------------------------------------------------- 
n = 100
container = initEmptyString(n)
# If we get 0, we should infvestigate metada structrue 
LibUHD.uhd_rx_metadata_strerror(radio.rx.uhd.addressMD[],container,n)
@show truncate(container)

container = initEmptyString(n)
LibUHD.uhd_rx_streamer_last_error(radio.rx.uhd.pointerStreamer,container,n)
@show truncate(container)

# ----------------------------------------------------
# --- Close 
# ---------------------------------------------------- 
close(radio)

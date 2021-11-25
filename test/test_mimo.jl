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
function initEmptyString(n)
    return  String(ones(UInt8,n)*UInt8(32))
end
""" 
Retrict the big string used as log container to its usefull part 
"""
function truncate(s::String)
    return s[1 : findfirst("\0",s)[1] - 1]
end

# ----------------------------------------------------
# --- Parameters 
# ---------------------------------------------------- 
carrierFreq = 868e6
samplingRate = 2e6
gain        = 25
# uhdArgs     = "num_recv_frames=1000"
uhdArgs     = ""
nbAntennaRx = 1

# ----------------------------------------------------
# --- Address extraction
# ---------------------------------------------------- 
# allR  = uhd_find_devices()
# extractAddr(x) = x[1][findfirst("_addr=",x[1])[end] .+ (1:13)]
# addr  = extractAddr(allR)

# ---------------------------------------------------- 
# --- Handler  
# ---------------------------------------------------- 
addressUSRP = Ref{UHDBindings.uhd_usrp_handle}();
# --- Cal the init
@assert_uhd LibUHD.uhd_usrp_make(addressUSRP,"")
# --- Get the usable object 
pointerUSRP = addressUSRP[];
# --- Instantiate core rx structures 
uhdrx = initRxUHD(pointerUSRP)
# --- Create the main Rx Object 
rx = UHDRx(uhdrx,carrierFreq,samplingRate,gain,"TRX",0,0);

# ----------------------------------------------------
# --- Set up Radio 
# ---------------------------------------------------- 
# --- Channels  & Antenna 
# channelIndexes = zeros(Csize_t,nbAntennaRx)
# for n ∈ eachindex(channelIndexes)
    # channelIndexes[n] = n - 1 
# end
channelIndexes = [1,0]
channel = pointer(channelIndexes)
antennas = ["TX/RX","RX2"]
# --- Streamer arguments
a1			   =  Base.unsafe_convert(Cstring,"fc32");
a2			   =  Base.unsafe_convert(Cstring,"sc16");
a3			   =  Base.unsafe_convert(Cstring,uhdArgs);
uhdArgs_0	   = LibUHD.uhd_stream_args_t(a1,a2,a3,channel,nbAntennaRx);
# --- RF Configuration 
for (c,currChan) in enumerate(channelIndexes[1:nbAntennaRx])
    updateCarrierFreq!(rx,carrierFreq,currChan)
    updateSamplingRate!(rx,samplingRate,currChan)
    updateGain!(rx,gain,currChan)
    LibUHD.uhd_usrp_set_rx_antenna(rx.uhd.pointerUSRP,antennas[c],currChan)
end
# --- Subdev with 2 boards
pointerSubDev = Ref{LibUHD.uhd_subdev_spec_handle}()
@assert_uhd LibUHD.uhd_subdev_spec_make(pointerSubDev,"A:0 A:1")
@assert_uhd LibUHD.uhd_usrp_set_rx_subdev_spec(rx.uhd.pointerUSRP,pointerSubDev[],0)
LibUHD.uhd_subdev_spec_free(pointerSubDev)
# --- Internal streamer and buffer config
pointerArgs	  = Ref{LibUHD.uhd_stream_args_t}(uhdArgs_0);
pointerSamples = Ref{Csize_t}(0);
@assert_uhd LibUHD.uhd_usrp_get_rx_stream(rx.uhd.pointerUSRP,pointerArgs,rx.uhd.pointerStreamer)
@assert_uhd LibUHD.uhd_rx_streamer_max_num_samps(rx.uhd.pointerStreamer,pointerSamples)
println("Internal buffer size is $(pointerSamples[])")
rx.packetSize= pointerSamples[]
# --- Clock source 
@assert_uhd LibUHD.uhd_usrp_set_clock_source(rx.uhd.pointerUSRP,"internal",0)
@assert_uhd LibUHD.uhd_usrp_set_time_now(rx.uhd.pointerUSRP,0,0,0)
# @assert_uhd LibUHD.uhd_usrp_set_clock_source(rx.uhd.pointerUSRP,"mimo",0)
# @assert_uhd LibUHD.uhd_usrp_set_time_source(rx.uhd.pointerUSRP,"mimo",1)

# ----------------------------------------------------
# --- Set up streamer 
# ---------------------------------------------------- 
streamCmd	= UHDBindings.uhd_stream_cmd_t(UHDBindings.UHD_STREAM_MODE_NUM_SAMPS_AND_DONE,rx.packetSize,false,1,0.5);
# streamCmd	= UHDBindings.uhd_stream_cmd_t(UHDBindings.UHD_STREAM_MODE_NUM_SAMPS_AND_MORE,rx.packetSize,true,0,0);
pointerCmd	= Ref{UHDBindings.uhd_stream_cmd_t}(streamCmd);
LibUHD.uhd_rx_streamer_issue_stream_cmd(rx.uhd.pointerStreamer,pointerCmd)
sleep(0.1)
# ---------------------------------------------------- 
# --- Julia buffers 
# ---------------------------------------------------- 	
# Define an array to get all the buffers from all the channels 
nbSamples      = rx.packetSize
# sig            = zeros(Complex{Cdouble},rx.packetSize , nbAntennaRx)
sig =  [zeros(Complex{Cfloat},rx.packetSize) for n ∈ 1:nbAntennaRx]
ptr            = Ref(Ptr{Cvoid}(pointer(sig,1)));
pointerCounterSamples = Ref{Csize_t}(0);

# ----------------------------------------------------
# --- Receive data 
# ---------------------------------------------------- 
LibUHD.uhd_rx_streamer_recv(rx.uhd.pointerStreamer,ptr,nbSamples,rx.uhd.addressMD,1.6,true,pointerCounterSamples)
nbSamples = pointerCounterSamples[]
println("Receive $nbSamples samples")

# ----------------------------------------------------
# --- Logs
# ---------------------------------------------------- 
n = 100
container = initEmptyString(n)
# If we get 0, we should infvestigate metada structrue 
LibUHD.uhd_rx_metadata_strerror(rx.uhd.addressMD[],container,n)
@show truncate(container)

container = initEmptyString(n)
LibUHD.uhd_rx_streamer_last_error(rx.uhd.pointerStreamer,container,n)
@show truncate(container)

# ----------------------------------------------------
# --- Close 
# ---------------------------------------------------- 
close(rx)
LibUHD.uhd_usrp_free(addressUSRP)

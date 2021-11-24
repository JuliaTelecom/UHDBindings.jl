using UHDBindings 
import UHDBindings.LibUHD as LibUHD

import UHDBindings.openUHDRx
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

# ----------------------------------------------------
# --- Parameters 
# ---------------------------------------------------- 
carrierFreq = 868e6
samplingRate = 2e6
gain        = 25
uhdArgs     = ""
nbAntennaRx = 2

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
# --- Manually create the streamers 
# Streamer 1
addressStream_0 = Ref{LibUHD.uhd_rx_streamer_handle}(); 
@assert_uhd LibUHD.uhd_rx_streamer_make(addressStream_0)
pointerStreamer_0 = addressStream_0[];
# Streamer 2
addressStream_1 = Ref{LibUHD.uhd_rx_streamer_handle}(); 
@assert_uhd LibUHD.uhd_rx_streamer_make(addressStream_1)
pointerStreamer_1 = addressStream_1[];

# ----------------------------------------------------
# --- Set up Radio 
# ---------------------------------------------------- 
# --- Channels  & Antenna 
# channelIndexes = zeros(Csize_t,nbAntennaRx)
# for n ∈ eachindex(channelIndexes)
    # channelIndexes[n] = n - 1 
# end
channelIndexes = Csize_t.([0,1])
channel = pointer(channelIndexes)
antennas = ["TX/RX","RX2"]
# --- Streamer arguments
a1			   =  Base.unsafe_convert(Cstring,"fc32");
a2			   =  Base.unsafe_convert(Cstring,"sc16");
a3			   =  Base.unsafe_convert(Cstring,uhdArgs);
uhdArgs_0		   = LibUHD.uhd_stream_args_t(a1,a2,a3,pointer(channelIndexes,2),1);
uhdArgs_1		   = LibUHD.uhd_stream_args_t(a1,a2,a3,pointer(channelIndexes,1),1);
# --- RF Configuration 
for (c,currChan) in enumerate(channelIndexes)
    updateCarrierFreq!(rx,carrierFreq,currChan)
    updateSamplingRate!(rx,samplingRate,currChan)
    updateGain!(rx,gain,currChan)
    LibUHD.uhd_usrp_set_rx_antenna(rx.uhd.pointerUSRP,antennas[c],0)
end
# --- Subdev ?
pointerSubDev = Ref{LibUHD.uhd_subdev_spec_handle}()
@assert_uhd LibUHD.uhd_subdev_spec_make(pointerSubDev,"A:0")
@assert_uhd LibUHD.uhd_usrp_set_rx_subdev_spec(rx.uhd.pointerUSRP,pointerSubDev[],0)
LibUHD.uhd_subdev_spec_free(pointerSubDev)
# --- Internal buffer management 
pointerArgs	  = Ref{LibUHD.uhd_stream_args_t}(uhdArgs_0);
pointerSamples = Ref{Csize_t}(0);
@assert_uhd LibUHD.uhd_usrp_get_rx_stream(rx.uhd.pointerUSRP,pointerArgs,pointerStreamer_0)
@assert_uhd LibUHD.uhd_rx_streamer_max_num_samps(pointerStreamer_0,pointerSamples)
println("Internal buffer size is $(pointerSamples[])")
rx.packetSize= pointerSamples[]
# --- Internal buffer management 
pointerArgs	  = Ref{LibUHD.uhd_stream_args_t}(uhdArgs_1);
pointerSamples = Ref{Csize_t}(0);
@assert_uhd LibUHD.uhd_usrp_get_rx_stream(rx.uhd.pointerUSRP,pointerArgs,pointerStreamer_1)
@assert_uhd LibUHD.uhd_rx_streamer_max_num_samps(pointerStreamer_1,pointerSamples)
println("Internal buffer size is $(pointerSamples[])")


# ----------------------------------------------------
# --- Set up streamer 
# ---------------------------------------------------- 
# streamCmd	= UHDBindings.uhd_stream_cmd_t(UHDBindings.UHD_STREAM_MODE_NUM_SAMPS_AND_MORE,rx.packetSize,false,1,0.5);
streamCmd	= UHDBindings.uhd_stream_cmd_t(UHDBindings.UHD_STREAM_MODE_NUM_SAMPS_AND_MORE,rx.packetSize,true,0,0);
pointerCmd	= Ref{UHDBindings.uhd_stream_cmd_t}(streamCmd);
LibUHD.uhd_rx_streamer_issue_stream_cmd(pointerStreamer_0,pointerCmd)
pointerCmd	= Ref{UHDBindings.uhd_stream_cmd_t}(streamCmd);
LibUHD.uhd_rx_streamer_issue_stream_cmd(pointerStreamer_1,pointerCmd)

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
LibUHD.uhd_rx_streamer_recv(pointerStreamer_0,ptr,nbSamples,rx.uhd.addressMD,0.1,true,pointerCounterSamples)
# LibUHD.uhd_rx_streamer_recv(pointerStreamer_1,ptr,nbSamples,rx.uhd.addressMD,0.1,true,pointerCounterSamples)
nbSamples = pointerCounterSamples[]
println("Receive $nbSamples samples")

# ----------------------------------------------------
# --- Logs
# ---------------------------------------------------- 
n = 100
container = initEmptyString(n)
# If we get 0, we should infvestigate metada structrue 
LibUHD.uhd_rx_metadata_strerror(rx.uhd.addressMD[],container,n)
@show container

container = initEmptyString(n)
LibUHD.uhd_rx_streamer_last_error(pointerStreamer_0,container,n)
@show container

# ----------------------------------------------------
# --- Close 
# ---------------------------------------------------- 
close(rx)
LibUHD.uhd_usrp_free(addressUSRP)


# ----------------------------------------------------
# pointerSubDev = Ref{LibUHD.uhd_subdev_spec_handle}()
# @assert_uhd LibUHD.uhd_subdev_spec_make(pointerSubDev,"B:0")
# @assert_uhd LibUHD.uhd_usrp_set_rx_subdev_spec(rx.uhd.pointerUSRP,pointerSubDev[],1)
# LibUHD.uhd_subdev_spec_free(pointerSubDev)
# # Custom streamer
# # For stream 2
# streamCmd	= UHDBindings.uhd_stream_cmd_t(UHDBindings.UHD_STREAM_MODE_NUM_SAMPS_AND_MORE,rx.packetSize,false,1,0.5);
# pointerCmd	= Ref{UHDBindings.uhd_stream_cmd_t}(streamCmd);
# LibUHD.uhd_rx_streamer_issue_stream_cmd(rx.uhd.pointerStreamer,pointerCmd)
# # For stream 1
# streamCmd	= UHDBindings.uhd_stream_cmd_t(UHDBindings.UHD_STREAM_MODE_NUM_SAMPS_AND_MORE,rx.packetSize,false,1,0.5);
# pointerCmd	= Ref{UHDBindings.uhd_stream_cmd_t}(streamCmd);
# LibUHD.uhd_rx_streamer_issue_stream_cmd(rx.uhd.pointerStreamer,pointerCmd)
# pointerClock = Ref{LibUHD.uhd_usrp_clock_handle}()
# pointerBoard = Ref{Csize_t}(0)
# @assert_uhd LibUHD.uhd_usrp_clock_make(pointerClock,"addr=$(addr)")
# LibUHD.uhd_usrp_clock_get_num_boards(pointerClock[],pointerBoard)
# println("Number of board is $(pointerBoard[])")
# LibUHD.get_num_boards(





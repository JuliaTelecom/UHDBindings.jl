using Test
using UHDBindings

# --- USRP address 
const USRP_ADDRESS = "192.168.10.16"
# This address may vary from time to time, not really sure how to handle dynamic testing 



# ----------------------------------------------------
# --- Define test routines 
# ---------------------------------------------------- 
"""
Scan with uhd_find_devices and return the USRP identifier 
"""
function check_scan()
    str = uhd_find_devices("addr=$USRP_ADDRESS")
    @test length(str) > 0 
end

""" 
Test that the device can be open, configured and closed 
"""
function check_open()
    # --- Main parameters 
	carrierFreq		= 440e6;	# --- The carrier frequency 	
	samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    # --- Create the E310 device 
   global sdr = openUHD(carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   # Type is OK 
   @test typeof(sdr) == UHDBinding
   # SDR is not released yet 
   @test sdr.rx.released == false
   # Configuration : Carrier Freq 
   @test sdr.rx.carrierFreq == carrierFreq
   @test sdr.tx.carrierFreq == carrierFreq
   # Configuration : Badnwidth 
   @test sdr.rx.samplingRate == samplingRate
   @test sdr.tx.samplingRate == samplingRate
   # --- We close the SDR 
   close(sdr)
   @test sdr.rx.released == true
end 

""" 
Check the carrier frequency update of the USRP device 
"""
function check_carrierFreq()
    # --- Main parameters 
    carrierFreq		= 440e6;	# --- The carrier frequency 	
    samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    # --- Create the E310 device 
   global sdr = openUHD(carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   #  Classic value, should work 
   updateCarrierFreq!(sdr,800e6)
   @test sdr.rx.carrierFreq == 800e6
   @test sdr.tx.carrierFreq == 800e6
   # Targeting WiFi, should work
   updateCarrierFreq!(sdr,2400e6)
   @test sdr.rx.carrierFreq == 2400e6
   @test sdr.tx.carrierFreq == 2400e6
   # If we specify a out of range frequency, it should bound to max val
   # TODO Check that is should be max freq range, but don't know the range as different USRP may be used
   # Adding tables with various ranges to check taht this is the expected value ?
   eF= updateCarrierFreq!(sdr,9e9)
   @test sdr.rx.carrierFreq != 9e9
   @test sdr.tx.carrierFreq != 9e9
   @test sdr.rx.carrierFreq == eF 
   @test sdr.tx.carrierFreq == eF 
   close(sdr);
   @test sdr.rx.released == true
end

""" 
Check the sampling frequency update of the USRP device 
"""
function check_samplingRate()
    # --- Main parameters 
    carrierFreq		= 440e6;	# --- The carrier frequency 	
    samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    # --- Create the E310 device 
   global sdr = openUHD(carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   #  Classic value, should work 
   updateSamplingRate!(sdr,8e6)
   @test sdr.rx.samplingRate == 8e6
   @test sdr.tx.samplingRate == 8e6
   # Targeting WiFi, should work
   updateSamplingRate!(sdr,15.36e6)
   @test sdr.rx.samplingRate == 15.36e6
   @test sdr.tx.samplingRate == 15.36e6
   # If we specify a out of range frequency, it should bound to max val
   eS = updateSamplingRate!(sdr,100e9)
   # @test sdr.rx.samplingRate != 100e9 ## No Error ?
   # @test sdr.tx.samplingRate != 100e9
   @test sdr.rx.samplingRate == eS 
   @test sdr.tx.samplingRate == eS 
   close(sdr);
   @test sdr.rx.released == true
end

""" 
Check the gain update for the USRP device
"""
function check_gain()
    # --- Main parameters 
    carrierFreq		= 440e6;	# --- The carrier frequency 	
    samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    # --- Create the E310 device 
   global sdr = openUHD(carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   #  Classic value, should work 
   nG  = updateGain!(sdr,20)
   @test sdr.rx.gain == 20
   @test sdr.tx.gain == 20
   @test sdr.rx.gain == nG
   @test sdr.tx.gain == nG
   close(sdr);
   @test sdr.rx.released == true
end 


""" 
Test that the device  can received data 
"""
function check_recv()
    # --- Main parameters 
    carrierFreq		= 440e6;	# --- The carrier frequency 	
    samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    # --- Create the E310 device 
   global sdr = openUHD(carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
    sig = recv(sdr,1024)
    @test length(sig) == 1024 
    @test eltype(sig) == Complex{Float32}
    close(sdr)
    @test sdr.rx.released == true
end 

""" 
Test that the device  can received data  with pre-allocation
"""
function check_recv_preAlloc()
    # --- Main parameters 
    carrierFreq		= 440e6;	# --- The carrier frequency 	
    samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    # --- Create the E310 device 
   global sdr = openUHD(carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   sig = zeros(ComplexF32,2*1024)
   recv!(sig,sdr)
   @test length(sig) == 1024*2
   @test eltype(sig) == Complex{Float32}
   @test length(unique(sig)) > 1 # To be sure we have populated array with data
   close(sdr)
   @test sdr.rx.released == true
end 

""" 
Test that the device can received data several time 
"""
function check_recv_iterative()
    # --- Main parameters 
    carrierFreq		= 440e6;	# --- The carrier frequency 	
    samplingRate	= 8e6;         # --- Targeted bandwdith 
    gain			= 0;         # --- Rx gain  
    # --- Create the E310 device 
   global sdr = openUHD(carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
   sig = zeros(ComplexF32,2*1024)
   nbPackets  = 0
   maxPackets = 100_000 
   for _ ∈ 1 : 1 : maxPackets
       # --- Get a burst 
       recv!(sig,sdr)
       # --- Increment packet index 
       nbPackets += 1
   end 
   @test nbPackets == maxPackets
   close(sdr)
   @test sdr.rx.released == true
end 

"""
Test that the device sucessfully transmit data 
""" 
function check_send()
	carrierFreq		= 770e6;		
	samplingRate	= 4e6; 
	gain			= 50.0; 
    nbSamples		= 4096*2
	# --- Setting a very first configuration 
    global sdr = openUHD(carrierFreq, samplingRate, gain;args="addr=$USRP_ADDRESS");
    print(sdr);
    # --- Create a sine wave
    f_c     = 3940;
    buffer  = 0.5.*[exp.(2im * π * f_c / samplingRate * n)  for n ∈ (0:nbSamples-1)];
    buffer  = convert.(Complex{Cfloat},buffer);

    buffer2  = 0.5.*[exp.(2im * π *  10 * f_c / samplingRate * n)  for n ∈ (0:nbSamples-1)];
    buffer2  = convert.(Complex{Cfloat},buffer2);
    buffer = [buffer;buffer2];

    cntAll  = 0;
    maxPackets = 10_000 
    nbPackets  = 0
    for _ ∈ 1 : maxPackets
        send(sdr,buffer,false);
       # --- Increment packet index 
       nbPackets += 1
    end
    @test nbPackets == maxPackets
    close(sdr)
    @test sdr.rx.released == true
end

# ----------------------------------------------------
# --- Test calls
# ---------------------------------------------------- 
@testset "Scanning and opening" begin 
    check_scan()
    check_open()
end 

@testset "Radio configuration" begin 
    check_carrierFreq()
    check_samplingRate()
    check_gain()
end 

@testset "Checking data retrieval"  begin 
    check_recv()
    check_recv_preAlloc()
    check_recv_iterative()
end

@testset "Checking data transmission"  begin 
    check_send()
end

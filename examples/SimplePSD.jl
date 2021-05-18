module SimplePSD 

# A simple example code to calculate a PSD of a received signal 
# This uses AbstractFFTs to compute the FFT here, even though FFTW would be faster

using UHDBindings 
using FFTW


""" 
Compute the PSD at the given carrier frequency, on the given bandwidth, withe SDR parameters args. 
PSD is calculated a the periodogram (square root of the averaged FFT)
Input parameters 
- carrierFreq = Carrier frequency (in Hz) 
- samplingRate = Desired bandwidth (in Hz)
- gain = desired gain 
- args = USRP device argument (ex: "addr=192.168.10.16")
- N : Desired FFT size [Default 1024]
- nbMean : Averaging factor. Number of buffers averaged before computed final result 
Output parameters 
xAx = Frequency values (Vector{Float})
psd = PSD values at the associated frequencies (Vector{Float})

The result then can be plotted by plot(xAx,10*log10.(psd))

""" 
function computePSD(carrierFreq,samplingRate,gain;args="",N=1024,nbMean=32)
	# ---------------------------------------------------- 
	# --- Physical layer and RF parameters 
	# ---------------------------------------------------- 
	# --- Create the radio object in function
    sdr			= openUHD(carrierFreq,samplingRate,gain,args=args)
	# --- Print the configuration
	print(sdr);
	# We will get complex samples from recv! method
	sig		  = zeros(Complex{Cfloat},N); # Buffer in time domain 
	psd       = zeros(Cfloat,N); # Buffer in freq domain 
    # ----------------------------------------------------
    # --- Acqusition and frequency domain calculation 
    # ---------------------------------------------------- 
    for _ ∈ 1 : nbMean 
        # Populate buffer 
        recv!(sig,sdr)
        # Compute FFT 
        psd += abs2.(fft(sig))
    end 
    # --- Close SDR 
    close(sdr)
    # --- Compute freq axis 
    freqAx = ((0:N-1)/(N-1) .- 0.5) * samplingRate 
    # --- Return tuple (freq,mag)
    return (freqAx, fftshift(psd))
end


end

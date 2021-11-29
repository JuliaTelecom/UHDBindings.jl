module Benchmark 
# ---------------------------------------------------- 
# --- Benchmark module 
# ---------------------------------------------------- 
# This module uses UHDBindings and can be used to benchmark output rate of the SDR 
# Benchmark.main(5e6,args) returns a tuple (ideally (5e6,5e6)) where 
# Input 
# - First parmaeter is the desired radio rate  
# - Second parameter is the radio parameter (USRP device)
# Output 
# First parameter is the actual radio rate 
# Second parameter is the calculated rate

# To benchmark a range one can do Benchmark.main.(1e6:1e6:16e6)

# --- External modules 
using UHDBindings 
# --- Functions 
"""
Calculate rate based on Julia timing
"""
function getRate(tInit,tFinal,nbSamples)
	return nbSamples / (tFinal-tInit);
end


"""
Main call to monitor Rx rate
"""
function main(samplingRate,args,duration=2)	
	# ---------------------------------------------------- 
	# --- Physical layer and RF parameters 
	# ---------------------------------------------------- 
	# --- Create the radio object in function
	carrierFreq		= 770e6;		
	gain			= 50.0; 
    radio			= openUHD(carrierFreq,samplingRate,gain,args=args)
	# --- Print the configuration
	print(radio);
	# --- Init parameters 
	# Get the radio size for buffer pre-allocation
	nbSamples 		= radio.rx.packetSize;
    @show nbSamples
	# We will get complex samples from recv! method
    sig		  = zeros(Complex{Cfloat},nbSamples); 
	# --- Targeting 2 seconds acquisition
	# Init counter increment
	nS		  = 0;
	# Max counter definition
	nbBuffer  = samplingRate*duration;
	# --- Timestamp init 
	p 			= recv!(sig,radio);
	nS			+= p;
	timeInit  	= time();
	while true
		# --- Direct call to avoid allocation 
		p = recv!(sig,radio);
		# # --- Ensure packet is OK
		# err 	= getError(radioRx);
		# --- Update counter
		nS		+= p;
		# --- Interruption 
		if nS > nbBuffer
			break 
		end
	end
	# --- Last timeStamp and rate 
	timeFinal = time();
	# --- Getting effective rate 
	radioRate	  = radio.rx.samplingRate;
    effectiveRate = getRate(timeInit,timeFinal,nS);
	# --- Free all and return
	close(radio);
	return (radioRate,effectiveRate);
    end
end

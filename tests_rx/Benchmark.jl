module Benchmark 
# ---------------------------------------------------- 
# --- Modules & Utils
# ---------------------------------------------------- 
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
function main(samplingRate)	
	# ---------------------------------------------------- 
	# --- Physical layer and RF parameters 
	# ---------------------------------------------------- 
	# --- Create the radio object in function
	carrierFreq		= 770e6;		
	gain			= 50.0; 
    radio			= openUHD(carrierFreq,samplingRate,gain); 
    radioRx         = radio.rx;
	# --- Print the configuration
	print(radioRx);
	# --- Init parameters 
	# Get the radio size for buffer pre-allocation
	nbSamples 		= radioRx.packetSize;
	# We will get complex samples from recv! method
	sig		  = zeros(Complex{Cfloat},nbSamples); 
	# --- Targeting 2 seconds acquisition
	# Init counter increment
	nS		  = 0;
	# Max counter definition
	nbBuffer  = 2*samplingRate;
	# --- Timestamp init 
	p 			= recv!(sig,radioRx);
	nS			+= p;
	timeInit  	= time();
	while true
		# --- Direct call to avoid allocation 
		p = recv!(sig,radioRx);
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
	radioRate	  = radioRx.samplingRate;
    effectiveRate = getRate(timeInit,timeFinal,nS);
	# --- Free all and return
	close(radio);
	return (radioRate,effectiveRate);
    end
end
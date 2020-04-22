module TestConfigUHD 
# ---------------------------------------------------- 
# --- Modules  
# ---------------------------------------------------- 
# --- External modules 
using FFTW 
using Printf
using UHDBindings 


function main()	
	# ---------------------------------------------------- 
	# --- Physical layer and RF parameters 
	# ---------------------------------------------------- 
	carrierFreq		= 770e6;		
	samplingRate	= 66e6; 
	gain			= 50.0; 
	nbSamples		= 1000;

	@printf("done -- \n");

	# --- Setting a very first configuration 
	global radio = openUHD(carrierFreq,samplingRate,gain); 
	print(radio.rx);
	  
	# --- Update configuration 
	updateCarrierFreq!(radio.rx,660e6);
	updateSamplingRate!(radio.rx,100e6);
	updateGain!(radio.rx,15);
	print(radio.rx);
	
	updateSamplingRate!(radio.rx,16e6);
	# --- Release USRP 
	close(radio);
end





end

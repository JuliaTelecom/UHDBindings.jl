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
	global radio = openUHDRx(carrierFreq,samplingRate,gain); 
	print(radio);
	  
	# --- Update configuration 
	updateCarrierFreq!(radio,660e6);
	updateSamplingRate!(radio,100e6);
	updateGain!(radio,15);
	print(radio);
	
	updateSamplingRate!(radio,16e6);
	# --- Release USRP 
	close(radio);
end





end

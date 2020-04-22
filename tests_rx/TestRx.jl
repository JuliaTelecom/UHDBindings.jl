module TestRx
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
	samplingRate	= 100e6; 
	gain			= 50.0; 
	nbSamples		= 1000;

	@printf("done -- \n");

	# --- Setting a very first configuration 
	global radio = openUHD(carrierFreq,samplingRate,gain); 
	#print(radio);
	# --- Get samples 
	#@show sigAll	= getSingleBuffer(radio);
	#@show getError(radio);
	#@show getMetadata(radio);
	# 
	#@show md	= unsafe_load(radio.uhd.pointerMD);
	#@show sigAll	= recv(radio,nbSamples);
#sigAll	= getSingleBuffer(radio);
	# --- Release USRP 
	close(radio);
end





end

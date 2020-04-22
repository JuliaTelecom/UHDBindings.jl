
module TestTx
# ---------------------------------------------------- 
# --- Modules  
# ---------------------------------------------------- 
# --- External modules 
using FFTW 
using Printf
using UHDBindings 
using Random

function main()	
	# ---------------------------------------------------- 
	# --- Physical layer and RF parameters 
	# ---------------------------------------------------- 
	carrierFreq		= 770e6;		
	samplingRate	= 8e6; 
	gain			= 50.0; 
	nbSamples		= 1000;
	# --- Setting a very first configuration 
	global radio = openUHD(carrierFreq,samplingRate,gain); 
	print(radio);
	# --- Get samples 
    buffer	= randn(Complex{Cfloat},radio.tx.packetSize);

	# nbEch	= send(radio,buffer,true)
	for iN = 1 : 1 : 1000
	nbEch = send(radio,buffer);
	@show Int(nbEch);
	end
	# --- Release USRP 
	close(radio);
end

end

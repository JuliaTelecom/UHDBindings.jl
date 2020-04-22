module Stability 
# ---------------------------------------------------- 
# --- Modules  
# ---------------------------------------------------- 
# --- External modules 
using FFTW 
using Printf
using UHDBindings 
using LinearAlgebra 

"""
---
Calculate rate based on timestamp
# ---
# v 1.0 - Robin Gerzaguet.
"""
function getRate(tInit,tFinal,nbSamples)
	sDeb = tInit.intPart + tInit.fracPart;
	sFin = tFinal.intPart + tFinal.fracPart; 
	timing = sFin - sDeb; 
	return nbSamples / timing / 1e6;
end

"""
---
Calculate rate based on Julia time() command
# ---
# v 1.0 - Robin Gerzaguet.
"""
function getRateII(tInit,tFinal,nbSamples)
	timing = tFinal - tInit; 
	return nbSamples / timing / 1e6;
end


struct Res 
	carrierFreq::Float64;
	gain::Float64;	
	rateVect::Array{Float64};
	fftVect::Array{Float64};
	benchPerf::Array{Float64};
	radioRate::Array{Float64};
end
export Res

# Setting max piority to avoid CPU congestion 
function setMaxPiority();
	pid = getpid();
	run(`renice -n -20 -p $pid`);
	run(`chrt -p 99 $pid`)
end 


function main()	
	# ---------------------------------------------------- 
	# --- Physical layer and RF parameters 
	# ---------------------------------------------------- 
	carrierFreq		= 770e6;		
	samplingRate	= 8e6; 
	gain			= 50.0; 

	# --- Setting a very first configuration 
	global radio = openUHD(carrierFreq,samplingRate,gain); 
	print(radio);
	# --- Get samples 
	nbSamples = 1016;
	sig		  = zeros(Complex{Cfloat},nbSamples); 
	cnt		  = 0;
	try 
		while(true) 
			# --- Direct call to avoid allocation 
			recv!(sig,radio);
			cnt += 1;
			#print("\rProcessed $(cnt) bursts");
		end
		close(radio);
	catch exception;
		# --- Release USRP 
		close(radio);
		@show exception;
	end
end



function mainFFT(radio,samplingRate,nbSamples)	
	# ---------------------------------------------------- 
	# --- Physical layer and RF parameters 
	# ---------------------------------------------------- 
	if radio == Any;
		# --- Create the radio object in function
		carrierFreq		= 770e6;		
		gain			= 50.0; 
		radio			= openUHD(carrierFreq,samplingRate,gain); 
		updateSamplingRate!(radio,samplingRate);
		toRelease		= true;
	else 
		# --- Call from a method that have degined radio 
		# UHD will be released there
		toRelease = false;
		# --- We only have to update carrier frequency 
		updateSamplingRate!(radio,samplingRate);
	end
	print(radio);
	sleep(0.5);
	# --- Get samples 
	sig		  = zeros(Complex{Cfloat},nbSamples); 
	out		  = zeros(Cfloat,nbSamples); 
	internal  = zeros(Complex{Cfloat},nbSamples); 
	nS		  = Csize_t(0);
	nbBuffer  = Csize_t(2*samplingRate);
	# --- Pre-processing 
	p = recv!(sig,radio);
	P = plan_fft(sig;flags=FFTW.PATIENT);
	processing!(out,sig,internal,P);
	# --- Timestamp init 
	p = recv!(sig,radio);
	processing!(out,sig,internal,P);
	# --- MEtrics 
	nS		+= p;
	# timeInit  = Timestamp(getTimestamp(radio)...);
	timeInit  = time();
	while true
		# --- Direct call to avoid allocation 
		p = recv!(sig,radio);
		# --- Apply processing method
		processing!(out,sig,internal,P);
		# --- Ensure packet is OK
		# --- Update counter
		nS		+= p;
		# --- Before releasing buffer, we need a valid received system to have a valid timeStamp
		# --- Interruption 
		if nS > nbBuffer
			if getError(radio) == UHD.ERROR_CODE_NONE 
				break 
			end
		end
	end
	# --- Last timeStamp and rate 
	# timeFinal = Timestamp(getTimestamp(radio)...);
	timeFinal = time();
	# --- Getting effective rate 
	radioRate	  = radio.samplingRate;
	effectiveRate = getRateII(timeInit, timeFinal, nS);
	# --- Free all and return
	if toRelease 
		close(radio);
	end
	return (radioRate,effectiveRate);
end

function processing!(out,sig,internal,P)
	# --- Plan FFT 
	mul!(internal,P,sig);
	# --- |.|^2 
	out .= abs2.(internal);
	# return abs2.(fft(sig));
end


function bench()
	# --- Set priority 
	setMaxPiority();
	# --- Configuration
	carrierFreq		= 770e6;		
	gain			= 50.0; 
	rateVect	= [1e3;100e3;500e3;1e6:1e6:8e6;16e6];
	fftVect		= [64;128;256;512;1016;1024;2048;2*1016;4*1016];
	# fftVect		= [32768];
	# fftVect		= [4096];
	# fftVect		= [1016;2*1016;4*1016];
	benchPerf	= zeros(Float64,length(fftVect),length(rateVect));
	radioRate	= zeros(Float64,length(rateVect));
	# --- Setting a very first configuration 
	radio = openUHD(carrierFreq,1e6,gain); 
	for (iR,targetRate) in enumerate(rateVect)
		for (iN,fftSize) in enumerate(fftVect)
			# --- Calling method 
			(eR,cR)            = mainFFT(radio,targetRate,fftSize);
			# --- Getting rate 
			benchPerf[iN,iR] = cR;
			# --- Getting radio rate 
			radioRate[iR]      = eR;
			# --- Print a flag
			print("$targetRate - $fftSize -- ");
			print("$eR MS/s -- $cR MS/s\n");
		end
	end
	close(radio);
	strucRes  = Res(carrierFreq,gain,rateVect,fftVect,benchPerf,radioRate);
	return strucRes;
end


end

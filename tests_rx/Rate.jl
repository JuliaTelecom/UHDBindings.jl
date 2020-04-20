module Rate 


using FFTW 
using UHDBindings 
using Plotly 

struct timeStamp 
	intPart::Clonglong;
	fracPart::Cdouble;
end

function getRate(tInit,tFinal,nbSamples)
	sDeb = 60*tInit.intPart + tInit.fracPart;
	sFin = 60*tFinal.intPart + tFinal.fracPart; 
	timing = sFin - sDeb; 
	return nbSamples / timing;
end


function testRate(samplingRate)
	carrierFreq		= 770e6;		
	gain			= 10.0; 
	# --- Setting a very first configuration 
	radio = openUHDRx(carrierFreq,samplingRate,gain); 
	print(radio);
	# --- Get samples 
	nbSamples = radio.packetSize;
	sig		  = zeros(Complex{Cfloat},nbSamples); 
	try 
		#while(true)
		bL		  = 0;
		nbRun	  = 1000000;
		tInit	= Any;
		tFinal	= Any; 
		while bL < nbRun
			# --- Direct call to avoid allocation 
			nS = recv!(sig,radio);
			#nS = populateBuffer!(buffer,radio);
			if bL == 0
				tInit  = timeStamp(getTimestamp(buffer)...);
			end
			bL += nS;
		end
		tFinal= timeStamp(getTimestamp(buffer)...);
		@show rate  = getRate(tInit,tFinal,bL);
		close(radio);
		return rate, radio.samplingRate;
	catch exception;
		# --- Release USRP 
		close(radio);
		@show exception;
	end
end


function bench()
	carrierFreq		= 770e6;		
	gain			= 10.0; 
	tRate	= collect(1e6:2e6:200e6);
	oRate	= zeros(Float64,length(tRate));
	fRate	= zeros(Float64,length(tRate));
	# --- Setting a very first configuration 
	radio = openUHDRx(carrierFreq,100e6,gain); 
	for (i,r) in enumerate(tRate) 
		updateSamplingRate!(radio,r);
		print(radio);
		# --- Get samples 
		nbSamples = 20*radio.packetSize;
		sig		  = zeros(Complex{Cfloat},nbSamples); 
		try 
			#while(true)
			bL		  = 0;
			nbRun	  = 1000000;
			tInit	= Any;
			tFinal	= Any; 
			while bL < nbRun
				# --- Direct call to avoid allocation 
				nS = recv!(sig,radio);
				#nS = populateBuffer!(buffer,radio);
				if bL == 0
					tInit  = timeStamp(getTimestamp(buffer)...);
				end
				bL += nS;
			end
			tFinal	  = timeStamp(getTimestamp(buffer)...);
			rate	  = getRate(tInit,tFinal,bL);
			oRate[i]  = rate;
			fRate[i]  = radio.samplingRate;
		catch exception;
			# --- Release USRP 
			buffer = Any;
			close(radio);
			@show exception;
		end
	end
	buffer = Any;
	close(radio);
	# --- Figure 
	layout = Plotly.Layout(;title="Rate  ",
						   xaxis_title="Desired rate  ",
						   yaxis_title="Obtained rate  ",
						   xaxis_showgrid=true, yaxis_showgrid=true,
						   )
	pl1	  = Plotly.scatter(; x=fRate ,y=oRate , name="X310 Rat ");
	plt = Plotly.plot([pl1],layout)
	display(plt);
	return (fRate,oRate,plt);
end






end

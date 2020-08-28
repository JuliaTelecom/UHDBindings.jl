
module SinusTx
# ---------------------------------------------------- 
# --- Modules  
# ---------------------------------------------------- 
# --- External modules 
using UHDBindings 

function main()	
	# ---------------------------------------------------- 
	# --- Physical layer and RF parameters 
	# ---------------------------------------------------- 
	carrierFreq		= 770e6;		
	samplingRate	= 4e6; 
	gain			= 50.0; 
    nbSamples		= 4096*2
    @show carrierFreq, samplingRate, gain, nbSamples
	# --- Setting a very first configuration 
	radio = openUHD(carrierFreq,samplingRate,gain); 
	print(radio);
    # --- Create a sine wave
    f_c     = 3940;
    buffer  = 0.5.*[exp.(2im * π * f_c / samplingRate * n)  for n ∈ (0:nbSamples-1)];
    buffer  = convert.(Complex{Cfloat},buffer);

    buffer2  = 0.5.*[exp.(2im * π *  10 * f_c / samplingRate * n)  for n ∈ (0:nbSamples-1)];
    buffer2  = convert.(Complex{Cfloat},buffer2);
    buffer = [buffer;buffer2];

    cntAll  = 0;
    send(radio,buffer,true);
    # try 
    #     while (true)
    #         nbEch   = send(radio,buffer);
    #         cntAll += nbEch;
    #         yield();
    #     end
    # catch exception 
    #         @info "Getting interruption";
    #         @show exception
	# end
    # --- Release USRP 
    @show cntAll;
	close(radio);
end

end

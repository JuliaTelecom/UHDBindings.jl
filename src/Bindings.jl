# Loads the low level UHD bindings and define high level API bindings 

# ----------------------------------------------------
# --- Using LibUHD 
# ---------------------------------------------------- 
# --- Loading the lib file with UHD 
include("LibUHD/LibUHD.jl")
using .LibUHD


# ----------------------------------------------------
# --- Custom type and API definition
# ---------------------------------------------------- 
# --- Structure to manipulate UHD time stamps
struct Timestamp 
	intPart::Clonglong;
	fracPart::Cdouble;
end


"""
" @assert_uhd macro
# Get the current UHD flag and raise an error if necessary 
"""
macro assert_uhd(ex)
	quote 
		local flag = $(esc(ex));
		if flag == UHD_ERROR_KEY
			# --- Specific 
			error("Unable to create the UHD device. No attached UHD device found."); 
		elseif flag != UHD_ERROR_NONE 
			error("Unable to create or instantiate the UHD device. The return error flag is $flag"); 
		end
	end
end

# --- Structure with pointer reference
struct UHDRxWrapper 
	flag::Bool;
	pointerUSRP::Ptr{uhd_usrp};
	pointerStreamer::Ptr{uhd_rx_streamer};
	pointerMD::Ptr{uhd_rx_metadata_t};
	addressStream::Ref{uhd_rx_streamer_handle};
	addressMD::Ref{uhd_rx_metadata_handle};
	pointerSamples::Ref{Csize_t}
end 
# --- Main Rx structure 
mutable struct UHDRx 
	uhd::UHDRxWrapper;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
    antennas::Vector{String};
    channels::Vector{Int};
	packetSize::Csize_t;
	released::Int;
    nbAntennaRx::Int;
end

# --- Structure with pointer reference
struct UHDTxWrapper 
	flag::Bool;
	pointerUSRP::Ptr{uhd_usrp};
	pointerStreamer::Ptr{uhd_tx_streamer};
	pointerMD::Ptr{uhd_tx_metadata_t};
	addressStream::Ref{uhd_tx_streamer_handle};
	addressMD::Ref{uhd_tx_metadata_handle};
end 
# --- Main Tx structure 
mutable struct UHDTx 
	uhd::UHDTxWrapper;
	carrierFreq::Float64;
	samplingRate::Float64;
	gain::Union{Int,Float64}; 
    antennas::Vector{String};
    channels::Vector{Int};
	packetSize::Csize_t;
	released::Int;
    nbAntennaTx::Int;
end

# ----------------------------------------------------
# --- UHDBinding structure 
# ---------------------------------------------------- 
mutable struct UHDBinding 
	addressUSRP::Ref{uhd_usrp_handle};
	rx::UHDRx;
	tx::UHDTx;
end

# ----------------------------------------------------
# --- Print functions
# ---------------------------------------------------- 
# To print fancy message with different colors with Tx and Rx
function customPrint(str,handler;style...)
    msglines = split(chomp(str), '\n')
    printstyled("┌",handler,": ";style...)
    println(msglines[1])
    for i in 2:length(msglines)
        (i == length(msglines)) ? symb="└ " : symb = "|";
        printstyled(symb;style...);
        println(msglines[i]);
    end
end
# define macro for printing Rx info
macro inforx(str)
    quote
        customPrint($(esc(str)),"Rx";bold=true,color=:light_green)
    end
end
# define macro for printing Rx warning 
macro warnrx(str)
    quote
        customPrint($(esc(str)),"Rx Warning";bold=true,color=:light_yellow)
    end
end
# define macro for printing Tx info
macro infotx(str)
    quote
        customPrint($(esc(str)),"Tx";bold=true,color=:light_blue)
    end
end
# define macro for printing Tx warning 
macro warntx(str)
    quote
        customPrint($(esc(str)),"Tx Warning";bold=true,color=:light_yellow)
    end
end

# Direclry inherited from C file tune_request.h
@enum uhd_tune_request_policy_t begin 
	UHD_TUNE_REQUEST_POLICY_NONE=78;
	UHD_TUNE_REQUEST_POLICY_AUTO=65;
	UHD_TUNE_REQUEST_POLICY_MANUAL=77
end
# Directly inherited from C file usrp.h
@enum uhd_stream_mode_t  begin 
	UHD_STREAM_MODE_START_CONTINUOUS   = 97;
	UHD_STREAM_MODE_STOP_CONTINUOUS    = 111;
	UHD_STREAM_MODE_NUM_SAMPS_AND_DONE = 100;
	UHD_STREAM_MODE_NUM_SAMPS_AND_MORE = 109
end
@enum error_code_t begin
	ERROR_CODE_NONE = 0x0;
	ERROR_CODE_TIMEOUT = 0x1;
	ERROR_CODE_LATE_COMMAND = 0x2;
	ERROR_CODE_BROKEN_CHAIN = 0x4;
	ERROR_CODE_OVERFLOW = 0x8;
	ERROR_CODE_ALIGNMENT = 0xc;
	ERROR_CODE_BAD_PACKET = 0xf;
	BIG_PROBLEM;
end
@enum uhd_error begin 
	UHD_ERROR_NONE = 0;
	UHD_ERROR_INVALID_DEVICE = 1;
	UHD_ERROR_INDEX = 10;
	UHD_ERROR_KEY = 11;
	UHD_ERROR_NOT_IMPLEMENTED = 20;
	UHD_ERROR_USB = 21;
	UHD_ERROR_IO = 30;
	UHD_ERROR_OS = 31;
	UHD_ERROR_ASSERTION = 40;
	UHD_ERROR_LOOKUP = 41;
	UHD_ERROR_TYPE = 42;
	UHD_ERROR_VALUE = 43;
	UHD_ERROR_RUNTIME = 44;
	UHD_ERROR_ENVIRONMENT = 45;
	UHD_ERROR_SYSTEM = 46;
	UHD_ERROR_EXCEPT = 47;
	UHD_ERROR_BOOSTEXCEPT = 60;
	UHD_ERROR_STDEXCEPT = 70;
	UHD_ERROR_UNKNOWN = 100
end 

# --- Runtime structure 
# These structures are necessary to run the wrapper 
struct uhd_stream_args_t 
	cpu_format::Cstring
	otw_format::Cstring;
	args::Cstring;
	channel_list::Ref{Csize_t};
	n_channels::Cint;
end
struct uhd_tune_request_t 
	target_freq::Cdouble;
	rf_freq_policy::uhd_tune_request_policy_t;
	dsp_freq_policy::uhd_tune_request_policy_t;
end
struct uhd_tune_result 
	clipped_rf_freq::Cdouble;
	target_rf_freq::Cdouble;
	actual_rf_freq::Cdouble;
	target_dsp_freq::Cdouble;
	actual_dsp_freq::Cdouble;
end
struct stream_cmd
	stream_mode::uhd_stream_mode_t;
	num_samps::Csize_t;
	stream_now::Cint;
	time_spec_full_secs::Cintmax_t;
	time_spec_frac_secs::Cdouble;
end

# --- Structure to manipulate UHD time stamps
struct Timestamp 
	intPart::FORMAT_LONG;
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

# --- Global UHD structure from UHD 
mutable struct uhd_usrp
end



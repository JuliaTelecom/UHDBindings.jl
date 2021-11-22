module LibUHD

# ----------------------------------------------------
# --- Dependencies 
# ---------------------------------------------------- 
using USRPHardwareDriver_jll
# export USRPHardwareDriver_jll
using CEnum

# ----------------------------------------------------
# --- Constant
# ---------------------------------------------------- 
const UHD_VERSION_ABI_STRING = "4.1.0"
const UHD_VERSION = 4010099


# ----------------------------------------------------
# --- Enumeration
# ---------------------------------------------------- 
@cenum uhd_error::UInt32 begin
    UHD_ERROR_NONE = 0
    UHD_ERROR_INVALID_DEVICE = 1
    UHD_ERROR_INDEX = 10
    UHD_ERROR_KEY = 11
    UHD_ERROR_NOT_IMPLEMENTED = 20
    UHD_ERROR_USB = 21
    UHD_ERROR_IO = 30
    UHD_ERROR_OS = 31
    UHD_ERROR_ASSERTION = 40
    UHD_ERROR_LOOKUP = 41
    UHD_ERROR_TYPE = 42
    UHD_ERROR_VALUE = 43
    UHD_ERROR_RUNTIME = 44
    UHD_ERROR_ENVIRONMENT = 45
    UHD_ERROR_SYSTEM = 46
    UHD_ERROR_EXCEPT = 47
    UHD_ERROR_BOOSTEXCEPT = 60
    UHD_ERROR_STDEXCEPT = 70
    UHD_ERROR_UNKNOWN = 100
end

@cenum uhd_rx_metadata_error_code_t::UInt32 begin
    UHD_RX_METADATA_ERROR_CODE_NONE = 0
    UHD_RX_METADATA_ERROR_CODE_TIMEOUT = 1
    UHD_RX_METADATA_ERROR_CODE_LATE_COMMAND = 2
    UHD_RX_METADATA_ERROR_CODE_BROKEN_CHAIN = 4
    UHD_RX_METADATA_ERROR_CODE_OVERFLOW = 8
    UHD_RX_METADATA_ERROR_CODE_ALIGNMENT = 12
    UHD_RX_METADATA_ERROR_CODE_BAD_PACKET = 15
end

@cenum uhd_async_metadata_event_code_t::UInt32 begin
    UHD_ASYNC_METADATA_EVENT_CODE_BURST_ACK = 1
    UHD_ASYNC_METADATA_EVENT_CODE_UNDERFLOW = 2
    UHD_ASYNC_METADATA_EVENT_CODE_SEQ_ERROR = 4
    UHD_ASYNC_METADATA_EVENT_CODE_TIME_ERROR = 8
    UHD_ASYNC_METADATA_EVENT_CODE_UNDERFLOW_IN_PACKET = 16
    UHD_ASYNC_METADATA_EVENT_CODE_SEQ_ERROR_IN_BURST = 32
    UHD_ASYNC_METADATA_EVENT_CODE_USER_PAYLOAD = 64
end

@cenum uhd_sensor_value_data_type_t::UInt32 begin
    UHD_SENSOR_VALUE_BOOLEAN = 98
    UHD_SENSOR_VALUE_INTEGER = 105
    UHD_SENSOR_VALUE_REALNUM = 114
    UHD_SENSOR_VALUE_STRING = 115
end

@cenum uhd_tune_request_policy_t::UInt32 begin
    UHD_TUNE_REQUEST_POLICY_NONE = 78
    UHD_TUNE_REQUEST_POLICY_AUTO = 65
    UHD_TUNE_REQUEST_POLICY_MANUAL = 77
end

@cenum uhd_stream_mode_t::UInt32 begin
    UHD_STREAM_MODE_START_CONTINUOUS = 97
    UHD_STREAM_MODE_STOP_CONTINUOUS = 111
    UHD_STREAM_MODE_NUM_SAMPS_AND_DONE = 100
    UHD_STREAM_MODE_NUM_SAMPS_AND_MORE = 109
end

@cenum uhd_log_severity_level_t::UInt32 begin
    UHD_LOG_LEVEL_TRACE = 0
    UHD_LOG_LEVEL_DEBUG = 1
    UHD_LOG_LEVEL_INFO = 2
    UHD_LOG_LEVEL_WARNING = 3
    UHD_LOG_LEVEL_ERROR = 4
    UHD_LOG_LEVEL_FATAL = 5
end
# ----------------------------------------------------
# --- Structures
# ---------------------------------------------------- 
mutable struct uhd_rx_metadata_t end

mutable struct uhd_tx_metadata_t end

mutable struct uhd_async_metadata_t end

const uhd_rx_metadata_handle = Ptr{uhd_rx_metadata_t}

const uhd_tx_metadata_handle = Ptr{uhd_tx_metadata_t}

const uhd_async_metadata_handle = Ptr{uhd_async_metadata_t}

struct uhd_range_t
    start::Cdouble
    stop::Cdouble
    step::Cdouble
end

mutable struct uhd_meta_range_t end

const uhd_meta_range_handle = Ptr{uhd_meta_range_t}


mutable struct uhd_sensor_value_t end

const uhd_sensor_value_handle = Ptr{uhd_sensor_value_t}



mutable struct uhd_string_vector_t end

const uhd_string_vector_handle = Ptr{uhd_string_vector_t}


struct uhd_tune_request_t
    target_freq::Cdouble
    rf_freq_policy::uhd_tune_request_policy_t
    rf_freq::Cdouble
    dsp_freq_policy::uhd_tune_request_policy_t
    dsp_freq::Cdouble
    args::Ptr{Cchar}
end

struct uhd_tune_result_t
    clipped_rf_freq::Cdouble
    target_rf_freq::Cdouble
    actual_rf_freq::Cdouble
    target_dsp_freq::Cdouble
    actual_dsp_freq::Cdouble
end

struct uhd_usrp_rx_info_t
    mboard_id::Ptr{Cchar}
    mboard_name::Ptr{Cchar}
    mboard_serial::Ptr{Cchar}
    rx_id::Ptr{Cchar}
    rx_subdev_name::Ptr{Cchar}
    rx_subdev_spec::Ptr{Cchar}
    rx_serial::Ptr{Cchar}
    rx_antenna::Ptr{Cchar}
end

struct uhd_usrp_tx_info_t
    mboard_id::Ptr{Cchar}
    mboard_name::Ptr{Cchar}
    mboard_serial::Ptr{Cchar}
    tx_id::Ptr{Cchar}
    tx_subdev_name::Ptr{Cchar}
    tx_subdev_spec::Ptr{Cchar}
    tx_serial::Ptr{Cchar}
    tx_antenna::Ptr{Cchar}
end


mutable struct uhd_dboard_eeprom_t end

const uhd_dboard_eeprom_handle = Ptr{uhd_dboard_eeprom_t}

mutable struct uhd_mboard_eeprom_t end

const uhd_mboard_eeprom_handle = Ptr{uhd_mboard_eeprom_t}

struct uhd_subdev_spec_pair_t
    db_name::Ptr{Cchar}
    sd_name::Ptr{Cchar}
end

mutable struct uhd_subdev_spec_t end

const uhd_subdev_spec_handle = Ptr{uhd_subdev_spec_t}

struct uhd_usrp_register_info_t
    bitwidth::Csize_t
    readable::Bool
    writable::Bool
end

struct uhd_stream_args_t
    cpu_format::Ptr{Cchar}
    otw_format::Ptr{Cchar}
    args::Ptr{Cchar}
    channel_list::Ptr{Csize_t}
    n_channels::Cint
end



struct uhd_stream_cmd_t
    stream_mode::uhd_stream_mode_t
    num_samps::Csize_t
    stream_now::Bool
    time_spec_full_secs::Int64
    time_spec_frac_secs::Cdouble
end

mutable struct uhd_rx_streamer end

mutable struct uhd_tx_streamer end

const uhd_rx_streamer_handle = Ptr{uhd_rx_streamer}

const uhd_tx_streamer_handle = Ptr{uhd_tx_streamer}

mutable struct uhd_usrp end

const uhd_usrp_handle = Ptr{uhd_usrp}


mutable struct uhd_usrp_clock end

const uhd_usrp_clock_handle = Ptr{uhd_usrp_clock}
# ----------------------------------------------------
# --- Function calls
# ---------------------------------------------------- 
function uhd_get_last_error(error_out, strbuffer_len)
    ccall((:uhd_get_last_error, libuhd), uhd_error, (Ptr{Cchar}, Csize_t), error_out, strbuffer_len)
end

function uhd_get_abi_string(abi_string_out, buffer_len)
    ccall((:uhd_get_abi_string, libuhd), uhd_error, (Ptr{Cchar}, Csize_t), abi_string_out, buffer_len)
end

function uhd_get_version_string(version_out, buffer_len)
    ccall((:uhd_get_version_string, libuhd), uhd_error, (Ptr{Cchar}, Csize_t), version_out, buffer_len)
end

function uhd_rx_metadata_make(handle)
    ccall((:uhd_rx_metadata_make, libuhd), uhd_error, (Ptr{uhd_rx_metadata_handle},), handle)
end

function uhd_rx_metadata_free(handle)
    ccall((:uhd_rx_metadata_free, libuhd), uhd_error, (Ptr{uhd_rx_metadata_handle},), handle)
end

function uhd_rx_metadata_has_time_spec(h, result_out)
    ccall((:uhd_rx_metadata_has_time_spec, libuhd), uhd_error, (uhd_rx_metadata_handle, Ptr{Bool}), h, result_out)
end

function uhd_rx_metadata_time_spec(h, full_secs_out, frac_secs_out)
    ccall((:uhd_rx_metadata_time_spec, libuhd), uhd_error, (uhd_rx_metadata_handle, Ptr{Int64}, Ptr{Cdouble}), h, full_secs_out, frac_secs_out)
end

function uhd_rx_metadata_more_fragments(h, result_out)
    ccall((:uhd_rx_metadata_more_fragments, libuhd), uhd_error, (uhd_rx_metadata_handle, Ptr{Bool}), h, result_out)
end

function uhd_rx_metadata_fragment_offset(h, fragment_offset_out)
    ccall((:uhd_rx_metadata_fragment_offset, libuhd), uhd_error, (uhd_rx_metadata_handle, Ptr{Csize_t}), h, fragment_offset_out)
end

function uhd_rx_metadata_start_of_burst(h, result_out)
    ccall((:uhd_rx_metadata_start_of_burst, libuhd), uhd_error, (uhd_rx_metadata_handle, Ptr{Bool}), h, result_out)
end

function uhd_rx_metadata_end_of_burst(h, result_out)
    ccall((:uhd_rx_metadata_end_of_burst, libuhd), uhd_error, (uhd_rx_metadata_handle, Ptr{Bool}), h, result_out)
end

function uhd_rx_metadata_out_of_sequence(h, result_out)
    ccall((:uhd_rx_metadata_out_of_sequence, libuhd), uhd_error, (uhd_rx_metadata_handle, Ptr{Bool}), h, result_out)
end

function uhd_rx_metadata_to_pp_string(h, pp_string_out, strbuffer_len)
    ccall((:uhd_rx_metadata_to_pp_string, libuhd), uhd_error, (uhd_rx_metadata_handle, Ptr{Cchar}, Csize_t), h, pp_string_out, strbuffer_len)
end

function uhd_rx_metadata_error_code(h, error_code_out)
    ccall((:uhd_rx_metadata_error_code, libuhd), uhd_error, (uhd_rx_metadata_handle, Ptr{uhd_rx_metadata_error_code_t}), h, error_code_out)
end

function uhd_rx_metadata_strerror(h, strerror_out, strbuffer_len)
    ccall((:uhd_rx_metadata_strerror, libuhd), uhd_error, (uhd_rx_metadata_handle, Ptr{Cchar}, Csize_t), h, strerror_out, strbuffer_len)
end

function uhd_rx_metadata_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_rx_metadata_last_error, libuhd), uhd_error, (uhd_rx_metadata_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end

function uhd_tx_metadata_make(handle, has_time_spec, full_secs, frac_secs, start_of_burst, end_of_burst)
    ccall((:uhd_tx_metadata_make, libuhd), uhd_error, (Ptr{uhd_tx_metadata_handle}, Bool, Int64, Cdouble, Bool, Bool), handle, has_time_spec, full_secs, frac_secs, start_of_burst, end_of_burst)
end

function uhd_tx_metadata_free(handle)
    ccall((:uhd_tx_metadata_free, libuhd), uhd_error, (Ptr{uhd_tx_metadata_handle},), handle)
end

function uhd_tx_metadata_has_time_spec(h, result_out)
    ccall((:uhd_tx_metadata_has_time_spec, libuhd), uhd_error, (uhd_tx_metadata_handle, Ptr{Bool}), h, result_out)
end

function uhd_tx_metadata_time_spec(h, full_secs_out, frac_secs_out)
    ccall((:uhd_tx_metadata_time_spec, libuhd), uhd_error, (uhd_tx_metadata_handle, Ptr{Int64}, Ptr{Cdouble}), h, full_secs_out, frac_secs_out)
end

function uhd_tx_metadata_start_of_burst(h, result_out)
    ccall((:uhd_tx_metadata_start_of_burst, libuhd), uhd_error, (uhd_tx_metadata_handle, Ptr{Bool}), h, result_out)
end

function uhd_tx_metadata_end_of_burst(h, result_out)
    ccall((:uhd_tx_metadata_end_of_burst, libuhd), uhd_error, (uhd_tx_metadata_handle, Ptr{Bool}), h, result_out)
end

function uhd_tx_metadata_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_tx_metadata_last_error, libuhd), uhd_error, (uhd_tx_metadata_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end



function uhd_async_metadata_make(handle)
    ccall((:uhd_async_metadata_make, libuhd), uhd_error, (Ptr{uhd_async_metadata_handle},), handle)
end

function uhd_async_metadata_free(handle)
    ccall((:uhd_async_metadata_free, libuhd), uhd_error, (Ptr{uhd_async_metadata_handle},), handle)
end

function uhd_async_metadata_channel(h, channel_out)
    ccall((:uhd_async_metadata_channel, libuhd), uhd_error, (uhd_async_metadata_handle, Ptr{Csize_t}), h, channel_out)
end

function uhd_async_metadata_has_time_spec(h, result_out)
    ccall((:uhd_async_metadata_has_time_spec, libuhd), uhd_error, (uhd_async_metadata_handle, Ptr{Bool}), h, result_out)
end

function uhd_async_metadata_time_spec(h, full_secs_out, frac_secs_out)
    ccall((:uhd_async_metadata_time_spec, libuhd), uhd_error, (uhd_async_metadata_handle, Ptr{Int64}, Ptr{Cdouble}), h, full_secs_out, frac_secs_out)
end

function uhd_async_metadata_event_code(h, event_code_out)
    ccall((:uhd_async_metadata_event_code, libuhd), uhd_error, (uhd_async_metadata_handle, Ptr{uhd_async_metadata_event_code_t}), h, event_code_out)
end

function uhd_async_metadata_user_payload(h, user_payload_out)
    ccall((:uhd_async_metadata_user_payload, libuhd), uhd_error, (uhd_async_metadata_handle, Ptr{UInt32}), h, user_payload_out)
end

function uhd_async_metadata_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_async_metadata_last_error, libuhd), uhd_error, (uhd_async_metadata_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end

function uhd_range_to_pp_string(range, pp_string_out, strbuffer_len)
    ccall((:uhd_range_to_pp_string, libuhd), uhd_error, (Ptr{uhd_range_t}, Ptr{Cchar}, Csize_t), range, pp_string_out, strbuffer_len)
end

function uhd_meta_range_make(h)
    ccall((:uhd_meta_range_make, libuhd), uhd_error, (Ptr{uhd_meta_range_handle},), h)
end

function uhd_meta_range_free(h)
    ccall((:uhd_meta_range_free, libuhd), uhd_error, (Ptr{uhd_meta_range_handle},), h)
end

function uhd_meta_range_start(h, start_out)
    ccall((:uhd_meta_range_start, libuhd), uhd_error, (uhd_meta_range_handle, Ptr{Cdouble}), h, start_out)
end

function uhd_meta_range_stop(h, stop_out)
    ccall((:uhd_meta_range_stop, libuhd), uhd_error, (uhd_meta_range_handle, Ptr{Cdouble}), h, stop_out)
end

function uhd_meta_range_step(h, step_out)
    ccall((:uhd_meta_range_step, libuhd), uhd_error, (uhd_meta_range_handle, Ptr{Cdouble}), h, step_out)
end

function uhd_meta_range_clip(h, value, clip_step, result_out)
    ccall((:uhd_meta_range_clip, libuhd), uhd_error, (uhd_meta_range_handle, Cdouble, Bool, Ptr{Cdouble}), h, value, clip_step, result_out)
end

function uhd_meta_range_size(h, size_out)
    ccall((:uhd_meta_range_size, libuhd), uhd_error, (uhd_meta_range_handle, Ptr{Csize_t}), h, size_out)
end

function uhd_meta_range_push_back(h, range)
    ccall((:uhd_meta_range_push_back, libuhd), uhd_error, (uhd_meta_range_handle, Ptr{uhd_range_t}), h, range)
end

function uhd_meta_range_at(h, num, range_out)
    ccall((:uhd_meta_range_at, libuhd), uhd_error, (uhd_meta_range_handle, Csize_t, Ptr{uhd_range_t}), h, num, range_out)
end

function uhd_meta_range_to_pp_string(h, pp_string_out, strbuffer_len)
    ccall((:uhd_meta_range_to_pp_string, libuhd), uhd_error, (uhd_meta_range_handle, Ptr{Cchar}, Csize_t), h, pp_string_out, strbuffer_len)
end

function uhd_meta_range_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_meta_range_last_error, libuhd), uhd_error, (uhd_meta_range_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end

function uhd_sensor_value_make(h)
    ccall((:uhd_sensor_value_make, libuhd), uhd_error, (Ptr{uhd_sensor_value_handle},), h)
end

function uhd_sensor_value_make_from_bool(h, name, value, utrue, ufalse)
    ccall((:uhd_sensor_value_make_from_bool, libuhd), uhd_error, (Ptr{uhd_sensor_value_handle}, Ptr{Cchar}, Bool, Ptr{Cchar}, Ptr{Cchar}), h, name, value, utrue, ufalse)
end

function uhd_sensor_value_make_from_int(h, name, value, unit, formatter)
    ccall((:uhd_sensor_value_make_from_int, libuhd), uhd_error, (Ptr{uhd_sensor_value_handle}, Ptr{Cchar}, Cint, Ptr{Cchar}, Ptr{Cchar}), h, name, value, unit, formatter)
end

function uhd_sensor_value_make_from_realnum(h, name, value, unit, formatter)
    ccall((:uhd_sensor_value_make_from_realnum, libuhd), uhd_error, (Ptr{uhd_sensor_value_handle}, Ptr{Cchar}, Cdouble, Ptr{Cchar}, Ptr{Cchar}), h, name, value, unit, formatter)
end

function uhd_sensor_value_make_from_string(h, name, value, unit)
    ccall((:uhd_sensor_value_make_from_string, libuhd), uhd_error, (Ptr{uhd_sensor_value_handle}, Ptr{Cchar}, Ptr{Cchar}, Ptr{Cchar}), h, name, value, unit)
end

function uhd_sensor_value_free(h)
    ccall((:uhd_sensor_value_free, libuhd), uhd_error, (Ptr{uhd_sensor_value_handle},), h)
end

function uhd_sensor_value_to_bool(h, value_out)
    ccall((:uhd_sensor_value_to_bool, libuhd), uhd_error, (uhd_sensor_value_handle, Ptr{Bool}), h, value_out)
end

function uhd_sensor_value_to_int(h, value_out)
    ccall((:uhd_sensor_value_to_int, libuhd), uhd_error, (uhd_sensor_value_handle, Ptr{Cint}), h, value_out)
end

function uhd_sensor_value_to_realnum(h, value_out)
    ccall((:uhd_sensor_value_to_realnum, libuhd), uhd_error, (uhd_sensor_value_handle, Ptr{Cdouble}), h, value_out)
end

function uhd_sensor_value_name(h, name_out, strbuffer_len)
    ccall((:uhd_sensor_value_name, libuhd), uhd_error, (uhd_sensor_value_handle, Ptr{Cchar}, Csize_t), h, name_out, strbuffer_len)
end

function uhd_sensor_value_value(h, value_out, strbuffer_len)
    ccall((:uhd_sensor_value_value, libuhd), uhd_error, (uhd_sensor_value_handle, Ptr{Cchar}, Csize_t), h, value_out, strbuffer_len)
end

function uhd_sensor_value_unit(h, unit_out, strbuffer_len)
    ccall((:uhd_sensor_value_unit, libuhd), uhd_error, (uhd_sensor_value_handle, Ptr{Cchar}, Csize_t), h, unit_out, strbuffer_len)
end

function uhd_sensor_value_data_type(h, data_type_out)
    ccall((:uhd_sensor_value_data_type, libuhd), uhd_error, (uhd_sensor_value_handle, Ptr{uhd_sensor_value_data_type_t}), h, data_type_out)
end

function uhd_sensor_value_to_pp_string(h, pp_string_out, strbuffer_len)
    ccall((:uhd_sensor_value_to_pp_string, libuhd), uhd_error, (uhd_sensor_value_handle, Ptr{Cchar}, Csize_t), h, pp_string_out, strbuffer_len)
end

function uhd_sensor_value_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_sensor_value_last_error, libuhd), uhd_error, (uhd_sensor_value_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end

function uhd_string_vector_make(h)
    ccall((:uhd_string_vector_make, libuhd), uhd_error, (Ptr{uhd_string_vector_handle},), h)
end

function uhd_string_vector_free(h)
    ccall((:uhd_string_vector_free, libuhd), uhd_error, (Ptr{uhd_string_vector_handle},), h)
end

function uhd_string_vector_push_back(h, value)
    ccall((:uhd_string_vector_push_back, libuhd), uhd_error, (Ptr{uhd_string_vector_handle}, Ptr{Cchar}), h, value)
end

function uhd_string_vector_at(h, index, value_out, strbuffer_len)
    ccall((:uhd_string_vector_at, libuhd), uhd_error, (uhd_string_vector_handle, Csize_t, Ptr{Cchar}, Csize_t), h, index, value_out, strbuffer_len)
end

function uhd_string_vector_size(h, size_out)
    ccall((:uhd_string_vector_size, libuhd), uhd_error, (uhd_string_vector_handle, Ptr{Csize_t}), h, size_out)
end

function uhd_string_vector_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_string_vector_last_error, libuhd), uhd_error, (uhd_string_vector_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end


function uhd_tune_result_to_pp_string(tune_result, pp_string_out, strbuffer_len)
    ccall((:uhd_tune_result_to_pp_string, libuhd), Cvoid, (Ptr{uhd_tune_result_t}, Ptr{Cchar}, Csize_t), tune_result, pp_string_out, strbuffer_len)
end

function uhd_usrp_rx_info_free(rx_info)
    ccall((:uhd_usrp_rx_info_free, libuhd), uhd_error, (Ptr{uhd_usrp_rx_info_t},), rx_info)
end

function uhd_usrp_tx_info_free(tx_info)
    ccall((:uhd_usrp_tx_info_free, libuhd), uhd_error, (Ptr{uhd_usrp_tx_info_t},), tx_info)
end

function uhd_dboard_eeprom_make(h)
    ccall((:uhd_dboard_eeprom_make, libuhd), uhd_error, (Ptr{uhd_dboard_eeprom_handle},), h)
end

function uhd_dboard_eeprom_free(h)
    ccall((:uhd_dboard_eeprom_free, libuhd), uhd_error, (Ptr{uhd_dboard_eeprom_handle},), h)
end

function uhd_dboard_eeprom_get_id(h, id_out, strbuffer_len)
    ccall((:uhd_dboard_eeprom_get_id, libuhd), uhd_error, (uhd_dboard_eeprom_handle, Ptr{Cchar}, Csize_t), h, id_out, strbuffer_len)
end

function uhd_dboard_eeprom_set_id(h, id)
    ccall((:uhd_dboard_eeprom_set_id, libuhd), uhd_error, (uhd_dboard_eeprom_handle, Ptr{Cchar}), h, id)
end

function uhd_dboard_eeprom_get_serial(h, serial_out, strbuffer_len)
    ccall((:uhd_dboard_eeprom_get_serial, libuhd), uhd_error, (uhd_dboard_eeprom_handle, Ptr{Cchar}, Csize_t), h, serial_out, strbuffer_len)
end

function uhd_dboard_eeprom_set_serial(h, serial)
    ccall((:uhd_dboard_eeprom_set_serial, libuhd), uhd_error, (uhd_dboard_eeprom_handle, Ptr{Cchar}), h, serial)
end

function uhd_dboard_eeprom_get_revision(h, revision_out)
    ccall((:uhd_dboard_eeprom_get_revision, libuhd), uhd_error, (uhd_dboard_eeprom_handle, Ptr{Cint}), h, revision_out)
end

function uhd_dboard_eeprom_set_revision(h, revision)
    ccall((:uhd_dboard_eeprom_set_revision, libuhd), uhd_error, (uhd_dboard_eeprom_handle, Cint), h, revision)
end

function uhd_dboard_eeprom_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_dboard_eeprom_last_error, libuhd), uhd_error, (uhd_dboard_eeprom_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end

function uhd_mboard_eeprom_make(h)
    ccall((:uhd_mboard_eeprom_make, libuhd), uhd_error, (Ptr{uhd_mboard_eeprom_handle},), h)
end

function uhd_mboard_eeprom_free(h)
    ccall((:uhd_mboard_eeprom_free, libuhd), uhd_error, (Ptr{uhd_mboard_eeprom_handle},), h)
end

function uhd_mboard_eeprom_get_value(h, key, value_out, strbuffer_len)
    ccall((:uhd_mboard_eeprom_get_value, libuhd), uhd_error, (uhd_mboard_eeprom_handle, Ptr{Cchar}, Ptr{Cchar}, Csize_t), h, key, value_out, strbuffer_len)
end

function uhd_mboard_eeprom_set_value(h, key, value)
    ccall((:uhd_mboard_eeprom_set_value, libuhd), uhd_error, (uhd_mboard_eeprom_handle, Ptr{Cchar}, Ptr{Cchar}), h, key, value)
end

function uhd_mboard_eeprom_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_mboard_eeprom_last_error, libuhd), uhd_error, (uhd_mboard_eeprom_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end

function uhd_subdev_spec_pair_free(subdev_spec_pair)
    ccall((:uhd_subdev_spec_pair_free, libuhd), uhd_error, (Ptr{uhd_subdev_spec_pair_t},), subdev_spec_pair)
end

function uhd_subdev_spec_pairs_equal(first, second, result_out)
    ccall((:uhd_subdev_spec_pairs_equal, libuhd), uhd_error, (Ptr{uhd_subdev_spec_pair_t}, Ptr{uhd_subdev_spec_pair_t}, Ptr{Bool}), first, second, result_out)
end

function uhd_subdev_spec_make(h, markup)
    ccall((:uhd_subdev_spec_make, libuhd), uhd_error, (Ptr{uhd_subdev_spec_handle}, Ptr{Cchar}), h, markup)
end

function uhd_subdev_spec_free(h)
    ccall((:uhd_subdev_spec_free, libuhd), uhd_error, (Ptr{uhd_subdev_spec_handle},), h)
end

function uhd_subdev_spec_size(h, size_out)
    ccall((:uhd_subdev_spec_size, libuhd), uhd_error, (uhd_subdev_spec_handle, Ptr{Csize_t}), h, size_out)
end

function uhd_subdev_spec_push_back(h, markup)
    ccall((:uhd_subdev_spec_push_back, libuhd), uhd_error, (uhd_subdev_spec_handle, Ptr{Cchar}), h, markup)
end

function uhd_subdev_spec_at(h, num, subdev_spec_pair_out)
    ccall((:uhd_subdev_spec_at, libuhd), uhd_error, (uhd_subdev_spec_handle, Csize_t, Ptr{uhd_subdev_spec_pair_t}), h, num, subdev_spec_pair_out)
end

function uhd_subdev_spec_to_pp_string(h, pp_string_out, strbuffer_len)
    ccall((:uhd_subdev_spec_to_pp_string, libuhd), uhd_error, (uhd_subdev_spec_handle, Ptr{Cchar}, Csize_t), h, pp_string_out, strbuffer_len)
end

function uhd_subdev_spec_to_string(h, string_out, strbuffer_len)
    ccall((:uhd_subdev_spec_to_string, libuhd), uhd_error, (uhd_subdev_spec_handle, Ptr{Cchar}, Csize_t), h, string_out, strbuffer_len)
end

function uhd_subdev_spec_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_subdev_spec_last_error, libuhd), uhd_error, (uhd_subdev_spec_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end

function uhd_rx_streamer_make(h)
    ccall((:uhd_rx_streamer_make, libuhd), uhd_error, (Ptr{uhd_rx_streamer_handle},), h)
end

function uhd_rx_streamer_free(h)
    ccall((:uhd_rx_streamer_free, libuhd), uhd_error, (Ptr{uhd_rx_streamer_handle},), h)
end

function uhd_rx_streamer_num_channels(h, num_channels_out)
    ccall((:uhd_rx_streamer_num_channels, libuhd), uhd_error, (uhd_rx_streamer_handle, Ptr{Csize_t}), h, num_channels_out)
end

function uhd_rx_streamer_max_num_samps(h, max_num_samps_out)
    ccall((:uhd_rx_streamer_max_num_samps, libuhd), uhd_error, (uhd_rx_streamer_handle, Ptr{Csize_t}), h, max_num_samps_out)
end

function uhd_rx_streamer_recv(h, buffs, samps_per_buff, md, timeout, one_packet, items_recvd)
    ccall((:uhd_rx_streamer_recv, libuhd), uhd_error, (uhd_rx_streamer_handle, Ptr{Ptr{Cvoid}}, Csize_t, Ptr{uhd_rx_metadata_handle}, Cdouble, Bool, Ptr{Csize_t}), h, buffs, samps_per_buff, md, timeout, one_packet, items_recvd)
end

function uhd_rx_streamer_issue_stream_cmd(h, stream_cmd)
    ccall((:uhd_rx_streamer_issue_stream_cmd, libuhd), uhd_error, (uhd_rx_streamer_handle, Ptr{uhd_stream_cmd_t}), h, stream_cmd)
end

function uhd_rx_streamer_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_rx_streamer_last_error, libuhd), uhd_error, (uhd_rx_streamer_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end

function uhd_tx_streamer_make(h)
    ccall((:uhd_tx_streamer_make, libuhd), uhd_error, (Ptr{uhd_tx_streamer_handle},), h)
end

function uhd_tx_streamer_free(h)
    ccall((:uhd_tx_streamer_free, libuhd), uhd_error, (Ptr{uhd_tx_streamer_handle},), h)
end

function uhd_tx_streamer_num_channels(h, num_channels_out)
    ccall((:uhd_tx_streamer_num_channels, libuhd), uhd_error, (uhd_tx_streamer_handle, Ptr{Csize_t}), h, num_channels_out)
end

function uhd_tx_streamer_max_num_samps(h, max_num_samps_out)
    ccall((:uhd_tx_streamer_max_num_samps, libuhd), uhd_error, (uhd_tx_streamer_handle, Ptr{Csize_t}), h, max_num_samps_out)
end

function uhd_tx_streamer_send(h, buffs, samps_per_buff, md, timeout, items_sent)
    ccall((:uhd_tx_streamer_send, libuhd), uhd_error, (uhd_tx_streamer_handle, Ptr{Ptr{Cvoid}}, Csize_t, Ptr{uhd_tx_metadata_handle}, Cdouble, Ptr{Csize_t}), h, buffs, samps_per_buff, md, timeout, items_sent)
end

function uhd_tx_streamer_recv_async_msg(h, md, timeout, valid)
    ccall((:uhd_tx_streamer_recv_async_msg, libuhd), uhd_error, (uhd_tx_streamer_handle, Ptr{uhd_async_metadata_handle}, Cdouble, Ptr{Bool}), h, md, timeout, valid)
end

function uhd_tx_streamer_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_tx_streamer_last_error, libuhd), uhd_error, (uhd_tx_streamer_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end

function uhd_usrp_find(args, strings_out)
    ccall((:uhd_usrp_find, libuhd), uhd_error, (Ptr{Cchar}, Ptr{uhd_string_vector_handle}), args, strings_out)
end

function uhd_usrp_make(h, args)
    ccall((:uhd_usrp_make, libuhd), uhd_error, (Ptr{uhd_usrp_handle}, Ptr{Cchar}), h, args)
end

function uhd_usrp_free(h)
    ccall((:uhd_usrp_free, libuhd), uhd_error, (Ptr{uhd_usrp_handle},), h)
end

function uhd_usrp_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_usrp_last_error, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end

function uhd_usrp_get_rx_stream(h, stream_args, h_out)
    ccall((:uhd_usrp_get_rx_stream, libuhd), uhd_error, (uhd_usrp_handle, Ptr{uhd_stream_args_t}, uhd_rx_streamer_handle), h, stream_args, h_out)
end

function uhd_usrp_get_tx_stream(h, stream_args, h_out)
    ccall((:uhd_usrp_get_tx_stream, libuhd), uhd_error, (uhd_usrp_handle, Ptr{uhd_stream_args_t}, uhd_tx_streamer_handle), h, stream_args, h_out)
end

function uhd_usrp_get_rx_info(h, chan, info_out)
    ccall((:uhd_usrp_get_rx_info, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_usrp_rx_info_t}), h, chan, info_out)
end

function uhd_usrp_get_tx_info(h, chan, info_out)
    ccall((:uhd_usrp_get_tx_info, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_usrp_tx_info_t}), h, chan, info_out)
end

function uhd_usrp_set_master_clock_rate(h, rate, mboard)
    ccall((:uhd_usrp_set_master_clock_rate, libuhd), uhd_error, (uhd_usrp_handle, Cdouble, Csize_t), h, rate, mboard)
end

function uhd_usrp_get_master_clock_rate(h, mboard, clock_rate_out)
    ccall((:uhd_usrp_get_master_clock_rate, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cdouble}), h, mboard, clock_rate_out)
end

function uhd_usrp_get_pp_string(h, pp_string_out, strbuffer_len)
    ccall((:uhd_usrp_get_pp_string, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t), h, pp_string_out, strbuffer_len)
end

function uhd_usrp_get_mboard_name(h, mboard, mboard_name_out, strbuffer_len)
    ccall((:uhd_usrp_get_mboard_name, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cchar}, Csize_t), h, mboard, mboard_name_out, strbuffer_len)
end

function uhd_usrp_get_time_now(h, mboard, full_secs_out, frac_secs_out)
    ccall((:uhd_usrp_get_time_now, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Int64}, Ptr{Cdouble}), h, mboard, full_secs_out, frac_secs_out)
end

function uhd_usrp_get_time_last_pps(h, mboard, full_secs_out, frac_secs_out)
    ccall((:uhd_usrp_get_time_last_pps, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Int64}, Ptr{Cdouble}), h, mboard, full_secs_out, frac_secs_out)
end

function uhd_usrp_set_time_now(h, full_secs, frac_secs, mboard)
    ccall((:uhd_usrp_set_time_now, libuhd), uhd_error, (uhd_usrp_handle, Int64, Cdouble, Csize_t), h, full_secs, frac_secs, mboard)
end

function uhd_usrp_set_time_next_pps(h, full_secs, frac_secs, mboard)
    ccall((:uhd_usrp_set_time_next_pps, libuhd), uhd_error, (uhd_usrp_handle, Int64, Cdouble, Csize_t), h, full_secs, frac_secs, mboard)
end

function uhd_usrp_set_time_unknown_pps(h, full_secs, frac_secs)
    ccall((:uhd_usrp_set_time_unknown_pps, libuhd), uhd_error, (uhd_usrp_handle, Int64, Cdouble), h, full_secs, frac_secs)
end

function uhd_usrp_get_time_synchronized(h, result_out)
    ccall((:uhd_usrp_get_time_synchronized, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Bool}), h, result_out)
end

function uhd_usrp_set_command_time(h, full_secs, frac_secs, mboard)
    ccall((:uhd_usrp_set_command_time, libuhd), uhd_error, (uhd_usrp_handle, Int64, Cdouble, Csize_t), h, full_secs, frac_secs, mboard)
end

function uhd_usrp_clear_command_time(h, mboard)
    ccall((:uhd_usrp_clear_command_time, libuhd), uhd_error, (uhd_usrp_handle, Csize_t), h, mboard)
end

function uhd_usrp_set_time_source(h, time_source, mboard)
    ccall((:uhd_usrp_set_time_source, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t), h, time_source, mboard)
end

function uhd_usrp_get_time_source(h, mboard, time_source_out, strbuffer_len)
    ccall((:uhd_usrp_get_time_source, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cchar}, Csize_t), h, mboard, time_source_out, strbuffer_len)
end

function uhd_usrp_get_time_sources(h, mboard, time_sources_out)
    ccall((:uhd_usrp_get_time_sources, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, mboard, time_sources_out)
end

function uhd_usrp_set_clock_source(h, clock_source, mboard)
    ccall((:uhd_usrp_set_clock_source, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t), h, clock_source, mboard)
end

function uhd_usrp_get_clock_source(h, mboard, clock_source_out, strbuffer_len)
    ccall((:uhd_usrp_get_clock_source, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cchar}, Csize_t), h, mboard, clock_source_out, strbuffer_len)
end

function uhd_usrp_get_clock_sources(h, mboard, clock_sources_out)
    ccall((:uhd_usrp_get_clock_sources, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, mboard, clock_sources_out)
end

function uhd_usrp_set_clock_source_out(h, enb, mboard)
    ccall((:uhd_usrp_set_clock_source_out, libuhd), uhd_error, (uhd_usrp_handle, Bool, Csize_t), h, enb, mboard)
end

function uhd_usrp_set_time_source_out(h, enb, mboard)
    ccall((:uhd_usrp_set_time_source_out, libuhd), uhd_error, (uhd_usrp_handle, Bool, Csize_t), h, enb, mboard)
end

function uhd_usrp_get_num_mboards(h, num_mboards_out)
    ccall((:uhd_usrp_get_num_mboards, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Csize_t}), h, num_mboards_out)
end

function uhd_usrp_get_mboard_sensor(h, name, mboard, sensor_value_out)
    ccall((:uhd_usrp_get_mboard_sensor, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, Ptr{uhd_sensor_value_handle}), h, name, mboard, sensor_value_out)
end

function uhd_usrp_get_mboard_sensor_names(h, mboard, mboard_sensor_names_out)
    ccall((:uhd_usrp_get_mboard_sensor_names, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, mboard, mboard_sensor_names_out)
end

function uhd_usrp_set_user_register(h, addr, data, mboard)
    ccall((:uhd_usrp_set_user_register, libuhd), uhd_error, (uhd_usrp_handle, UInt8, UInt32, Csize_t), h, addr, data, mboard)
end

function uhd_usrp_get_mboard_eeprom(h, mb_eeprom, mboard)
    ccall((:uhd_usrp_get_mboard_eeprom, libuhd), uhd_error, (uhd_usrp_handle, uhd_mboard_eeprom_handle, Csize_t), h, mb_eeprom, mboard)
end

function uhd_usrp_set_mboard_eeprom(h, mb_eeprom, mboard)
    ccall((:uhd_usrp_set_mboard_eeprom, libuhd), uhd_error, (uhd_usrp_handle, uhd_mboard_eeprom_handle, Csize_t), h, mb_eeprom, mboard)
end

function uhd_usrp_get_dboard_eeprom(h, db_eeprom, unit, slot, mboard)
    ccall((:uhd_usrp_get_dboard_eeprom, libuhd), uhd_error, (uhd_usrp_handle, uhd_dboard_eeprom_handle, Ptr{Cchar}, Ptr{Cchar}, Csize_t), h, db_eeprom, unit, slot, mboard)
end

function uhd_usrp_set_dboard_eeprom(h, db_eeprom, unit, slot, mboard)
    ccall((:uhd_usrp_set_dboard_eeprom, libuhd), uhd_error, (uhd_usrp_handle, uhd_dboard_eeprom_handle, Ptr{Cchar}, Ptr{Cchar}, Csize_t), h, db_eeprom, unit, slot, mboard)
end

function uhd_usrp_set_rx_subdev_spec(h, subdev_spec, mboard)
    ccall((:uhd_usrp_set_rx_subdev_spec, libuhd), uhd_error, (uhd_usrp_handle, uhd_subdev_spec_handle, Csize_t), h, subdev_spec, mboard)
end

function uhd_usrp_get_rx_subdev_spec(h, mboard, subdev_spec_out)
    ccall((:uhd_usrp_get_rx_subdev_spec, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, uhd_subdev_spec_handle), h, mboard, subdev_spec_out)
end

function uhd_usrp_get_rx_num_channels(h, num_channels_out)
    ccall((:uhd_usrp_get_rx_num_channels, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Csize_t}), h, num_channels_out)
end

function uhd_usrp_get_rx_subdev_name(h, chan, rx_subdev_name_out, strbuffer_len)
    ccall((:uhd_usrp_get_rx_subdev_name, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cchar}, Csize_t), h, chan, rx_subdev_name_out, strbuffer_len)
end

function uhd_usrp_set_rx_rate(h, rate, chan)
    ccall((:uhd_usrp_set_rx_rate, libuhd), uhd_error, (uhd_usrp_handle, Cdouble, Csize_t), h, rate, chan)
end

function uhd_usrp_get_rx_rate(h, chan, rate_out)
    ccall((:uhd_usrp_get_rx_rate, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cdouble}), h, chan, rate_out)
end

function uhd_usrp_get_rx_rates(h, chan, rates_out)
    ccall((:uhd_usrp_get_rx_rates, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, uhd_meta_range_handle), h, chan, rates_out)
end

function uhd_usrp_set_rx_freq(h, tune_request, chan, tune_result)
    ccall((:uhd_usrp_set_rx_freq, libuhd), uhd_error, (uhd_usrp_handle, Ptr{uhd_tune_request_t}, Csize_t, Ptr{uhd_tune_result_t}), h, tune_request, chan, tune_result)
end

function uhd_usrp_get_rx_freq(h, chan, freq_out)
    ccall((:uhd_usrp_get_rx_freq, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cdouble}), h, chan, freq_out)
end

function uhd_usrp_get_rx_freq_range(h, chan, freq_range_out)
    ccall((:uhd_usrp_get_rx_freq_range, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, uhd_meta_range_handle), h, chan, freq_range_out)
end

function uhd_usrp_get_fe_rx_freq_range(h, chan, freq_range_out)
    ccall((:uhd_usrp_get_fe_rx_freq_range, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, uhd_meta_range_handle), h, chan, freq_range_out)
end

function uhd_usrp_get_rx_lo_names(h, chan, rx_lo_names_out)
    ccall((:uhd_usrp_get_rx_lo_names, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, chan, rx_lo_names_out)
end

function uhd_usrp_set_rx_lo_source(h, src, name, chan)
    ccall((:uhd_usrp_set_rx_lo_source, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Ptr{Cchar}, Csize_t), h, src, name, chan)
end

function uhd_usrp_get_rx_lo_source(h, name, chan, rx_lo_source_out, strbuffer_len)
    ccall((:uhd_usrp_get_rx_lo_source, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, Ptr{Cchar}, Csize_t), h, name, chan, rx_lo_source_out, strbuffer_len)
end

function uhd_usrp_get_rx_lo_sources(h, name, chan, rx_lo_sources_out)
    ccall((:uhd_usrp_get_rx_lo_sources, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, Ptr{uhd_string_vector_handle}), h, name, chan, rx_lo_sources_out)
end

function uhd_usrp_set_rx_lo_export_enabled(h, enabled, name, chan)
    ccall((:uhd_usrp_set_rx_lo_export_enabled, libuhd), uhd_error, (uhd_usrp_handle, Bool, Ptr{Cchar}, Csize_t), h, enabled, name, chan)
end

function uhd_usrp_get_rx_lo_export_enabled(h, name, chan, result_out)
    ccall((:uhd_usrp_get_rx_lo_export_enabled, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, Ptr{Bool}), h, name, chan, result_out)
end

function uhd_usrp_set_rx_lo_freq(h, freq, name, chan, coerced_freq_out)
    ccall((:uhd_usrp_set_rx_lo_freq, libuhd), uhd_error, (uhd_usrp_handle, Cdouble, Ptr{Cchar}, Csize_t, Ptr{Cdouble}), h, freq, name, chan, coerced_freq_out)
end

function uhd_usrp_get_rx_lo_freq(h, name, chan, rx_lo_freq_out)
    ccall((:uhd_usrp_get_rx_lo_freq, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, Ptr{Cdouble}), h, name, chan, rx_lo_freq_out)
end

function uhd_usrp_set_rx_gain(h, gain, chan, gain_name)
    ccall((:uhd_usrp_set_rx_gain, libuhd), uhd_error, (uhd_usrp_handle, Cdouble, Csize_t, Ptr{Cchar}), h, gain, chan, gain_name)
end

function uhd_usrp_set_normalized_rx_gain(h, gain, chan)
    ccall((:uhd_usrp_set_normalized_rx_gain, libuhd), uhd_error, (uhd_usrp_handle, Cdouble, Csize_t), h, gain, chan)
end

function uhd_usrp_set_rx_agc(h, enable, chan)
    ccall((:uhd_usrp_set_rx_agc, libuhd), uhd_error, (uhd_usrp_handle, Bool, Csize_t), h, enable, chan)
end

function uhd_usrp_get_rx_gain(h, chan, gain_name, gain_out)
    ccall((:uhd_usrp_get_rx_gain, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cchar}, Ptr{Cdouble}), h, chan, gain_name, gain_out)
end

function uhd_usrp_get_normalized_rx_gain(h, chan, gain_out)
    ccall((:uhd_usrp_get_normalized_rx_gain, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cdouble}), h, chan, gain_out)
end

function uhd_usrp_get_rx_gain_range(h, name, chan, gain_range_out)
    ccall((:uhd_usrp_get_rx_gain_range, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, uhd_meta_range_handle), h, name, chan, gain_range_out)
end

function uhd_usrp_get_rx_gain_names(h, chan, gain_names_out)
    ccall((:uhd_usrp_get_rx_gain_names, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, chan, gain_names_out)
end

function uhd_usrp_set_rx_antenna(h, ant, chan)
    ccall((:uhd_usrp_set_rx_antenna, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t), h, ant, chan)
end

function uhd_usrp_get_rx_antenna(h, chan, ant_out, strbuffer_len)
    ccall((:uhd_usrp_get_rx_antenna, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cchar}, Csize_t), h, chan, ant_out, strbuffer_len)
end

function uhd_usrp_get_rx_antennas(h, chan, antennas_out)
    ccall((:uhd_usrp_get_rx_antennas, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, chan, antennas_out)
end

function uhd_usrp_get_rx_sensor_names(h, chan, sensor_names_out)
    ccall((:uhd_usrp_get_rx_sensor_names, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, chan, sensor_names_out)
end

function uhd_usrp_set_rx_bandwidth(h, bandwidth, chan)
    ccall((:uhd_usrp_set_rx_bandwidth, libuhd), uhd_error, (uhd_usrp_handle, Cdouble, Csize_t), h, bandwidth, chan)
end

function uhd_usrp_get_rx_bandwidth(h, chan, bandwidth_out)
    ccall((:uhd_usrp_get_rx_bandwidth, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cdouble}), h, chan, bandwidth_out)
end

function uhd_usrp_get_rx_bandwidth_range(h, chan, bandwidth_range_out)
    ccall((:uhd_usrp_get_rx_bandwidth_range, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, uhd_meta_range_handle), h, chan, bandwidth_range_out)
end

function uhd_usrp_get_rx_sensor(h, name, chan, sensor_value_out)
    ccall((:uhd_usrp_get_rx_sensor, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, Ptr{uhd_sensor_value_handle}), h, name, chan, sensor_value_out)
end

function uhd_usrp_set_rx_dc_offset_enabled(h, enb, chan)
    ccall((:uhd_usrp_set_rx_dc_offset_enabled, libuhd), uhd_error, (uhd_usrp_handle, Bool, Csize_t), h, enb, chan)
end

function uhd_usrp_set_rx_iq_balance_enabled(h, enb, chan)
    ccall((:uhd_usrp_set_rx_iq_balance_enabled, libuhd), uhd_error, (uhd_usrp_handle, Bool, Csize_t), h, enb, chan)
end

function uhd_usrp_set_tx_subdev_spec(h, subdev_spec, mboard)
    ccall((:uhd_usrp_set_tx_subdev_spec, libuhd), uhd_error, (uhd_usrp_handle, uhd_subdev_spec_handle, Csize_t), h, subdev_spec, mboard)
end

function uhd_usrp_get_tx_subdev_spec(h, mboard, subdev_spec_out)
    ccall((:uhd_usrp_get_tx_subdev_spec, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, uhd_subdev_spec_handle), h, mboard, subdev_spec_out)
end

function uhd_usrp_get_tx_num_channels(h, num_channels_out)
    ccall((:uhd_usrp_get_tx_num_channels, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Csize_t}), h, num_channels_out)
end

function uhd_usrp_get_tx_subdev_name(h, chan, tx_subdev_name_out, strbuffer_len)
    ccall((:uhd_usrp_get_tx_subdev_name, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cchar}, Csize_t), h, chan, tx_subdev_name_out, strbuffer_len)
end

function uhd_usrp_set_tx_rate(h, rate, chan)
    ccall((:uhd_usrp_set_tx_rate, libuhd), uhd_error, (uhd_usrp_handle, Cdouble, Csize_t), h, rate, chan)
end

function uhd_usrp_get_tx_rate(h, chan, rate_out)
    ccall((:uhd_usrp_get_tx_rate, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cdouble}), h, chan, rate_out)
end

function uhd_usrp_get_tx_rates(h, chan, rates_out)
    ccall((:uhd_usrp_get_tx_rates, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, uhd_meta_range_handle), h, chan, rates_out)
end

function uhd_usrp_set_tx_freq(h, tune_request, chan, tune_result)
    ccall((:uhd_usrp_set_tx_freq, libuhd), uhd_error, (uhd_usrp_handle, Ptr{uhd_tune_request_t}, Csize_t, Ptr{uhd_tune_result_t}), h, tune_request, chan, tune_result)
end

function uhd_usrp_get_tx_freq(h, chan, freq_out)
    ccall((:uhd_usrp_get_tx_freq, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cdouble}), h, chan, freq_out)
end

function uhd_usrp_get_tx_freq_range(h, chan, freq_range_out)
    ccall((:uhd_usrp_get_tx_freq_range, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, uhd_meta_range_handle), h, chan, freq_range_out)
end

function uhd_usrp_get_fe_tx_freq_range(h, chan, freq_range_out)
    ccall((:uhd_usrp_get_fe_tx_freq_range, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, uhd_meta_range_handle), h, chan, freq_range_out)
end

function uhd_usrp_get_tx_lo_names(h, chan, tx_lo_names_out)
    ccall((:uhd_usrp_get_tx_lo_names, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, chan, tx_lo_names_out)
end

function uhd_usrp_set_tx_lo_source(h, src, name, chan)
    ccall((:uhd_usrp_set_tx_lo_source, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Ptr{Cchar}, Csize_t), h, src, name, chan)
end

function uhd_usrp_get_tx_lo_source(h, name, chan, tx_lo_source_out, strbuffer_len)
    ccall((:uhd_usrp_get_tx_lo_source, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, Ptr{Cchar}, Csize_t), h, name, chan, tx_lo_source_out, strbuffer_len)
end

function uhd_usrp_get_tx_lo_sources(h, name, chan, tx_lo_sources_out)
    ccall((:uhd_usrp_get_tx_lo_sources, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, Ptr{uhd_string_vector_handle}), h, name, chan, tx_lo_sources_out)
end

function uhd_usrp_set_tx_lo_export_enabled(h, enabled, name, chan)
    ccall((:uhd_usrp_set_tx_lo_export_enabled, libuhd), uhd_error, (uhd_usrp_handle, Bool, Ptr{Cchar}, Csize_t), h, enabled, name, chan)
end

function uhd_usrp_get_tx_lo_export_enabled(h, name, chan, result_out)
    ccall((:uhd_usrp_get_tx_lo_export_enabled, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, Ptr{Bool}), h, name, chan, result_out)
end

function uhd_usrp_set_tx_lo_freq(h, freq, name, chan, coerced_freq_out)
    ccall((:uhd_usrp_set_tx_lo_freq, libuhd), uhd_error, (uhd_usrp_handle, Cdouble, Ptr{Cchar}, Csize_t, Ptr{Cdouble}), h, freq, name, chan, coerced_freq_out)
end

function uhd_usrp_get_tx_lo_freq(h, name, chan, tx_lo_freq_out)
    ccall((:uhd_usrp_get_tx_lo_freq, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, Ptr{Cdouble}), h, name, chan, tx_lo_freq_out)
end

function uhd_usrp_set_tx_gain(h, gain, chan, gain_name)
    ccall((:uhd_usrp_set_tx_gain, libuhd), uhd_error, (uhd_usrp_handle, Cdouble, Csize_t, Ptr{Cchar}), h, gain, chan, gain_name)
end

function uhd_usrp_set_normalized_tx_gain(h, gain, chan)
    ccall((:uhd_usrp_set_normalized_tx_gain, libuhd), uhd_error, (uhd_usrp_handle, Cdouble, Csize_t), h, gain, chan)
end

function uhd_usrp_get_tx_gain_range(h, name, chan, gain_range_out)
    ccall((:uhd_usrp_get_tx_gain_range, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, uhd_meta_range_handle), h, name, chan, gain_range_out)
end

function uhd_usrp_get_tx_gain(h, chan, gain_name, gain_out)
    ccall((:uhd_usrp_get_tx_gain, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cchar}, Ptr{Cdouble}), h, chan, gain_name, gain_out)
end

function uhd_usrp_get_normalized_tx_gain(h, chan, gain_out)
    ccall((:uhd_usrp_get_normalized_tx_gain, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cdouble}), h, chan, gain_out)
end

function uhd_usrp_get_tx_gain_names(h, chan, gain_names_out)
    ccall((:uhd_usrp_get_tx_gain_names, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, chan, gain_names_out)
end

function uhd_usrp_set_tx_antenna(h, ant, chan)
    ccall((:uhd_usrp_set_tx_antenna, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t), h, ant, chan)
end

function uhd_usrp_get_tx_antenna(h, chan, ant_out, strbuffer_len)
    ccall((:uhd_usrp_get_tx_antenna, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cchar}, Csize_t), h, chan, ant_out, strbuffer_len)
end

function uhd_usrp_get_tx_antennas(h, chan, antennas_out)
    ccall((:uhd_usrp_get_tx_antennas, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, chan, antennas_out)
end

function uhd_usrp_set_tx_bandwidth(h, bandwidth, chan)
    ccall((:uhd_usrp_set_tx_bandwidth, libuhd), uhd_error, (uhd_usrp_handle, Cdouble, Csize_t), h, bandwidth, chan)
end

function uhd_usrp_get_tx_bandwidth(h, chan, bandwidth_out)
    ccall((:uhd_usrp_get_tx_bandwidth, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{Cdouble}), h, chan, bandwidth_out)
end

function uhd_usrp_get_tx_bandwidth_range(h, chan, bandwidth_range_out)
    ccall((:uhd_usrp_get_tx_bandwidth_range, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, uhd_meta_range_handle), h, chan, bandwidth_range_out)
end

function uhd_usrp_get_tx_sensor(h, name, chan, sensor_value_out)
    ccall((:uhd_usrp_get_tx_sensor, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Csize_t, Ptr{uhd_sensor_value_handle}), h, name, chan, sensor_value_out)
end

function uhd_usrp_get_tx_sensor_names(h, chan, sensor_names_out)
    ccall((:uhd_usrp_get_tx_sensor_names, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, chan, sensor_names_out)
end

function uhd_usrp_get_gpio_banks(h, mboard, gpio_banks_out)
    ccall((:uhd_usrp_get_gpio_banks, libuhd), uhd_error, (uhd_usrp_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, mboard, gpio_banks_out)
end

function uhd_usrp_set_gpio_attr(h, bank, attr, value, mask, mboard)
    ccall((:uhd_usrp_set_gpio_attr, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Ptr{Cchar}, UInt32, UInt32, Csize_t), h, bank, attr, value, mask, mboard)
end

function uhd_usrp_get_gpio_attr(h, bank, attr, mboard, attr_out)
    ccall((:uhd_usrp_get_gpio_attr, libuhd), uhd_error, (uhd_usrp_handle, Ptr{Cchar}, Ptr{Cchar}, Csize_t, Ptr{UInt32}), h, bank, attr, mboard, attr_out)
end


function uhd_usrp_clock_find(args, devices_out)
    ccall((:uhd_usrp_clock_find, libuhd), uhd_error, (Ptr{Cchar}, Ptr{uhd_string_vector_t}), args, devices_out)
end

function uhd_usrp_clock_make(h, args)
    ccall((:uhd_usrp_clock_make, libuhd), uhd_error, (Ptr{uhd_usrp_clock_handle}, Ptr{Cchar}), h, args)
end

function uhd_usrp_clock_free(h)
    ccall((:uhd_usrp_clock_free, libuhd), uhd_error, (Ptr{uhd_usrp_clock_handle},), h)
end

function uhd_usrp_clock_last_error(h, error_out, strbuffer_len)
    ccall((:uhd_usrp_clock_last_error, libuhd), uhd_error, (uhd_usrp_clock_handle, Ptr{Cchar}, Csize_t), h, error_out, strbuffer_len)
end

function uhd_usrp_clock_get_pp_string(h, pp_string_out, strbuffer_len)
    ccall((:uhd_usrp_clock_get_pp_string, libuhd), uhd_error, (uhd_usrp_clock_handle, Ptr{Cchar}, Csize_t), h, pp_string_out, strbuffer_len)
end

function uhd_usrp_clock_get_num_boards(h, num_boards_out)
    ccall((:uhd_usrp_clock_get_num_boards, libuhd), uhd_error, (uhd_usrp_clock_handle, Ptr{Csize_t}), h, num_boards_out)
end

function uhd_usrp_clock_get_time(h, board, clock_time_out)
    ccall((:uhd_usrp_clock_get_time, libuhd), uhd_error, (uhd_usrp_clock_handle, Csize_t, Ptr{UInt32}), h, board, clock_time_out)
end

function uhd_usrp_clock_get_sensor(h, name, board, sensor_value_out)
    ccall((:uhd_usrp_clock_get_sensor, libuhd), uhd_error, (uhd_usrp_clock_handle, Ptr{Cchar}, Csize_t, Ptr{uhd_sensor_value_handle}), h, name, board, sensor_value_out)
end

function uhd_usrp_clock_get_sensor_names(h, board, sensor_names_out)
    ccall((:uhd_usrp_clock_get_sensor_names, libuhd), uhd_error, (uhd_usrp_clock_handle, Csize_t, Ptr{uhd_string_vector_handle}), h, board, sensor_names_out)
end

function uhd_set_thread_priority(priority, realtime)
    ccall((:uhd_set_thread_priority, libuhd), uhd_error, (Cfloat, Bool), priority, realtime)
end

# Skipping MacroDefinition: UHD_EXPORT __attribute__ ( ( visibility ( "default" ) ) )

# Skipping MacroDefinition: UHD_IMPORT __attribute__ ( ( visibility ( "default" ) ) )

# Skipping MacroDefinition: UHD_INLINE inline __attribute__ ( ( always_inline ) )

# Skipping MacroDefinition: UHD_DEPRECATED __attribute__ ( ( deprecated ) )

# const UHD_API = UHD_IMPORT
# exports
const PREFIXES = ["UHD_","uhd_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module

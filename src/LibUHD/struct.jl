# ----------------------------------------------------
# --- Metadata
# ---------------------------------------------------- 
mutable struct uhd_rx_metadata_t end

mutable struct uhd_tx_metadata_t end

mutable struct uhd_async_metadata_t end

const uhd_rx_metadata_handle = Ptr{uhd_rx_metadata_t}

const uhd_tx_metadata_handle = Ptr{uhd_tx_metadata_t}

const uhd_async_metadata_handle = Ptr{uhd_async_metadata_t}

# ----------------------------------------------------
# --- Ranges
# ---------------------------------------------------- 
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

# ----------------------------------------------------
# --- Tune request (board managment)
# ---------------------------------------------------- 
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


# ----------------------------------------------------
# --- EEPROM
# ---------------------------------------------------- 
mutable struct uhd_dboard_eeprom_t end
const uhd_dboard_eeprom_handle = Ptr{uhd_dboard_eeprom_t}

mutable struct uhd_mboard_eeprom_t end
const uhd_mboard_eeprom_handle = Ptr{uhd_mboard_eeprom_t}

# ----------------------------------------------------
# --- Subdev
# ---------------------------------------------------- 
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

# ----------------------------------------------------
# --- Streamers
# ---------------------------------------------------- 
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
const uhd_rx_streamer_handle = Ptr{uhd_rx_streamer}

mutable struct uhd_tx_streamer end
const uhd_tx_streamer_handle = Ptr{uhd_tx_streamer}


# ----------------------------------------------------
# --- Core USRP
# ---------------------------------------------------- 
mutable struct uhd_usrp end
const uhd_usrp_handle = Ptr{uhd_usrp}

mutable struct uhd_usrp_clock end
const uhd_usrp_clock_handle = Ptr{uhd_usrp_clock}


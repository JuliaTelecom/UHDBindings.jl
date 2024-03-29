# Define all enumeration of UHD 


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


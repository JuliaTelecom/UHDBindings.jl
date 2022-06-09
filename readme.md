<div align="center">
<img src="docs/src/assets/logo.png" alt="UHDBindings.jl" width="380">
</div>

# UHDBindings.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://juliatelecom.github.io/UHDBindings.jl/dev/index.html)


## Purpose 

This package proposes some bindings to UHD, the C driver of the Universal Software Radio Peripheral [USRP](https://files.ettus.com/manual/) 

The package is heavily dependent on libUHD the open source driver from Ettus research. The library is shipped in the package through Artifacts, and the current implementation uses libUHD.4.0.0

The purpose is to able to instantiate the radio peripheral inside a Julia session and to be able to send and receive complex samples directly within a Julia session. 

For instance, in order to get 4096 samples at 868MHz with a instantaneous bandwidth of 16MHz, with a 30dB Rx Gain, the following Julia code will do the trick and returns a vector with type Complex{Cfloat} with 4096 samples.

	function main()
		# ---------------------------------------------------- 
		# --- Physical layer and RF parameters 
		# ---------------------------------------------------- 

		carrierFreq		= 868e6;	# --- The carrier frequency 	
		samplingRate		= 16e6;         # --- Targeted bandwdith 
		rxGain			= 30.0;         # --- Rx gain 
		nbSamples		= 4096;         # --- Desired number of samples
	
		# ---------------------------------------------------- 
		# --- Getting all system with function calls  
		# ---------------------------------------------------- 
		# --- Creating the radio ressource 
		radio	= openUHD(carrierFreq,samplingRate,rxGain);
		# --- Display the current radio configuration
		# Both Tx and Rx sides.
		print(radio);
		# --- Getting a buffer from the radio 
		sig	= recv(radio,nbSamples);
		# This also can be done with pre-allocation 
		buffer = zeros(Complex{Cfloat},nbSamples);
		recv!(buffer,radio);
		# --- Release the radio ressources
		close(radio); 
		# --- Output to signal 
		return sig;
	end


## Installation

The package can be installed with the Julia package manager.
From the Julia REPL, type `]` to enter the Pkg REPL mode and run:

```
pkg> add UHDBindings 
```

Or, equivalently, via the `Pkg` API:

```julia
julia> import Pkg; Pkg.add("UHDBindings")

```

## Note for Linux // MacOs 

Installation is automatic, it means that you do not require to have a fully manually installed version of UHD. 


## Notes for Window installation 

We have some struggle to automatize installation for windows. At the moment, it is possible to have UHDBindings only through a manual installation 
- First install UHD. You can find the lastest release on [UHD website](https://files.ettus.com/manual/page_install.html). It contains an installer that creates a bunch of files. We will need the `.dll` file. You can also run one of the executable (for instance `uhd_find_devices.exe`) to be sure you have a functional version of UHD (for instance no issue with `lib-usb`).

Now on Julia side 
- Add UHDBindings with  `]add UHDBindings`
- Run `using UHDBindings`. It should lead to several info/warning messages 



            julia> using UHDBindings
            [ Info: Precompiling UHDBindings [4d90b16f-829e-4b78-80d9-fb9bcf8c06e0]
            ┌ Warning: Unable to load libUHD using Yggdrasil. It probably means that the platform you use is not supported by artifact generated through Yggdrasil.
            └ @ UHDBindings C:\Users\Robin\.julia\dev\UHDBindings\src\UHDBindings.jl:51
            [ Info: We fallback to local provider. It means that UHDBindings will work if you have installed a functionnal version of UHD on your system
            [ Info: New provider set; restart your Julia session for this change to take effect!
            ┌ Warning: Unable to load the lib, the path should be updated to be the appropriate one using `set_lib_path`.
            └ @ UHDBindings C:\Users\Robin\.julia\dev\UHDBindings\src\UHDBindings.jl:63
            
- It means a local installation is required (see UHD notes regarding UHD installation) and that you need to point the UHD lib to UHDBindings. Assuming installation went Ok, let's focus on binding the UHD lib path to Julia.
- In the REPL type 




        julia> UHDBindings.set_lib_path("C:\\Users\\Robin\\Documents\\UHD\\bin\\uhd.dll") 

- Note that the path is complete and should contain the DLL extension. 
- Restart a fresh Julia session and type `using UHDBindings`. It should works ! 


        julia> using UHDBindings
        [ Info: Precompiling UHDBindings [4d90b16f-829e-4b78-80d9-fb9bcf8c06e0]
        
        julia> uhd_find_devices()
        [INFO] [UHD] Win32; Microsoft Visual C++ version 1925; Boost_107000; UHD_4.2.0.0-release
        [ Info: No UHD devices found. Try with "addr=xxx.xxx.x.x" to specify the USRP IP address
        String[]


## Documentation

- [**STABLE**](https://juliatelecom.github.io/UHDBindings.jl/dev/index.html) &mdash; **documentation of the most recently tagged version.**

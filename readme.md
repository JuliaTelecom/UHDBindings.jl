<div align="center">
<img src="docs/src/assets/logo.png" alt="UHDBindings.jl" width="380">
</div>

# UHDBindings.jl

[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://rgerzaguet.github.io/UHD.jl/dev/index.html)


## Purpose 

This package proposes some bindings to UHD, the C driver of the Universal Software Radio Peripheral [USRP](https://files.ettus.com/manual/) 

The purpose is to able to see the radio peripheral inside a Julia session and to be able to send and receive complex samples direclty within a Julia session. 

For instance, in order to get 4096 samples at 868MHz with a instantaneous bandwidth of 16MHz, with a 30dB Rx Gain, the following Julia code will do the trick. 

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
		# The first parameter is to tune the Rx board
		radio	= openUHD("Rx",carrierFreq,samplingRate,rxGain);
		# --- Display the current radio configuration
		print(radio);
		# --- Getting a buffer from the radio 
		sig	= recv(radio,nbSamples);
		# --- Release the radio ressources
		close(radio); 
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

## Documentation

- [**STABLE**](https://rgerzaguet.github.io/UHDBindings.jl/dev/index.html) &mdash; **documentation of the most recently tagged version.**

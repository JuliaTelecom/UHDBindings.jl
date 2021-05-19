# UHDBindings.jl


## Purpose 

This simple package proposes some bindings to the UHD, the C driver of the Universal Software Radio Peripheral [USRP](https://files.ettus.com/manual/) 

The package is heavily dependent on libUHD the open source driver from Ettus research. The library is shipped in the package through Artifacts, and the current implementation uses libUHD.4.0.0

The purpose is to able to instantiate the radio peripheral inside a Julia session and to be able to send and receive complex samples directly within a Julia session. 

The package introduces the `UHDBinding` structure which pilots and controls the radio. This structure has two important fields namely `tx` and `rx` that are respectively related to transmitter and receiver stages.
The function can takes `UHDBinding` as input parameter or `UHDBinding.rx`,`UHDBinding.tx`. In the latter case, the configuration will be set to both Tx and Rx stages.

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


- The base documentation with the different functions can be found [in the base section](base.md)
- Different examples are described in [in the example section](examples.md). Other examples are provided in the example subfolder of the project. 

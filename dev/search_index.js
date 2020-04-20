var documenterSearchIndex = {"docs":
[{"location":"base/#Common-functions-1","page":"Function list","title":"Common functions","text":"","category":"section"},{"location":"base/#","page":"Function list","title":"Function list","text":"Modules = [UHD]\nPages   = [\"UHD.jl\"]\nOrder   = [:function, :type]\nDepth\t= 1","category":"page"},{"location":"base/#Receiver-functions-1","page":"Function list","title":"Receiver functions","text":"","category":"section"},{"location":"base/#","page":"Function list","title":"Function list","text":"Modules = [UHD]\nPages   = [\"Rx.jl\"]\nOrder   = [:function, :type]\nDepth\t= 1","category":"page"},{"location":"base/#Transmitter-functions-1","page":"Function list","title":"Transmitter functions","text":"","category":"section"},{"location":"base/#","page":"Function list","title":"Function list","text":"Modules = [UHD]\nPages   = [\"Tx.jl\"]\nOrder   = [:function, :type]\nDepth\t= 1","category":"page"},{"location":"Examples/example_parameters/#Update-parameters-of-the-radio-1","page":"Update parameters of the radio","title":"Update parameters of the radio","text":"","category":"section"},{"location":"Examples/example_parameters/#","page":"Update parameters of the radio","title":"Update parameters of the radio","text":"It is possible to update the radio parameter such as the gain, the bandwidth and the sampling rate.  In this function, we change the carrier frequency to 2400MHz, the bandwidth from 16MHz to 100MHz and the Rx gain from 10 to 30dB. In some cases, the desired parameters cannot be obtained. In such a case, we let UHD decide what is the most appropriate value. A warning is raised and the output of the functions used to change the  the radio parameters corresponds to the effective values of the radio. ","category":"page"},{"location":"Examples/example_parameters/#","page":"Update parameters of the radio","title":"Update parameters of the radio","text":"function main()\n\t# ---------------------------------------------------- \n\t# --- Physical layer and RF parameters \n\t# ---------------------------------------------------- \n\tcarrierFreq\t= 868e6; \t# --- The carrier frequency (Hz)\t\n\tsamplingRate\t= 16e6;         # --- Targeted bandwidth (Hz)\n\trxGain\t\t= 30.0;         # --- Rx gain (dB)\n\tnbSamples\t= 4096;         # --- Desired number of samples\n\n\t# ---------------------------------------------------- \n\t# --- Getting all system with function calls  \n\t# ---------------------------------------------------- \n\t# --- Creating the radio resource \n\t# The first parameter is for specific parameter (FPGA bitstream, IP address)\n\tradio\t= openUHD(\"Rx\",carrierFreq,samplingRate,rxGain);\n\t# --- Display the current radio configuration\n\tprint(radio);\n\t# --- We what to change the parameters ! \n\tupdateSamplingFreq!(radio,100e6);\n\tupdateCarrierFreq!(radio,2400e6);\n\tupdateGain!(radio,30)\n\t# --- Print the new radio configuration \n\tprint(radio);\n\t# --- Release the radio resources\n\tclose(radio); \nend","category":"page"},{"location":"Examples/example_benchmark/#Benchmark-for-Rx-link-1","page":"Benchmark for Rx link","title":"Benchmark for Rx link","text":"","category":"section"},{"location":"Examples/example_benchmark/#","page":"Benchmark for Rx link","title":"Benchmark for Rx link","text":"The following script allows to benchmark the effective rate from the receiver. To do so we compute the number of samples received in a given time. The timing is measured fro the timestamp obtained from the radio. ","category":"page"},{"location":"Examples/example_benchmark/#","page":"Benchmark for Rx link","title":"Benchmark for Rx link","text":"module Benchmark \n# ---------------------------------------------------- \n# --- Modules & Utils\n# ---------------------------------------------------- \n# --- External modules \nusing UHDBindings \n# --- Functions \n\"\"\"\nCalculate rate based on UHD timestamp\n\"\"\"\nfunction getRate(tInit,tFinal,nbSamples)\n\tsDeb = tInit.intPart + tInit.fracPart;\n\tsFin = tFinal.intPart + tFinal.fracPart; \n\ttiming = sFin - sDeb; \n\treturn nbSamples / timing;\nend\n\"\"\"\nMain call to monitor Rx rate\n\"\"\"\nfunction main(samplingRate)\t\n\t# ---------------------------------------------------- \n\t# --- Physical layer and RF parameters \n\t# ---------------------------------------------------- \n\t# --- Create the radio object in function\n\tcarrierFreq\t\t= 770e6;\t\t\n\tgain\t\t\t= 50.0; \n\tradio\t\t\t= openUHD(\"Rx\",carrierFreq,samplingRate,gain); \n\t# --- Print the configuration\n\tprint(radio);\n\t# --- Init parameters \n\t# Get the radio size for buffer pre-allocation\n\tnbSamples \t\t= radio.packetSize;\n\t# We will get complex samples from recv! method\n\tsig\t\t  = zeros(Complex{Cfloat},nbSamples); \n\t# --- Targeting 2 seconds acquisition\n\t# Init counter increment\n\tnS\t\t  = 0;\n\t# Max counter definition\n\tnbBuffer  = 2*samplingRate;\n\t# --- Timestamp init \n\tp \t\t\t= recv!(sig,radio);\n\tnS\t\t\t+= p;\n\ttimeInit  \t= Timestamp(getTimestamp(radio)...);\n\twhile true\n\t\t# --- Direct call to avoid allocation \n\t\tp = recv!(sig,radio);\n\t\t# --- Ensure packet is OK\n\t\terr \t= getError(radio);\n\t\t# --- Update counter\n\t\tnS\t\t+= p;\n\t\t# --- Interruption \n\t\tif nS > nbBuffer\n\t\t\tbreak \n\t\tend\n\tend\n\t# --- Last timeStamp and rate \n\ttimeFinal = Timestamp(getTimestamp(radio)...);\n\t# --- Getting effective rate \n\tradioRate\t  = radio.samplingRate;\n    effectiveRate = getRate(timeInit,timeFinal,nS);\n\t# --- Free all and return\n\tclose(radio);\n\treturn (radioRate,effectiveRate);\n    end\nend","category":"page"},{"location":"#UHDBindings.jl-1","page":"Introduction to UHDBindings","title":"UHDBindings.jl","text":"","category":"section"},{"location":"#Purpose-1","page":"Introduction to UHDBindings","title":"Purpose","text":"","category":"section"},{"location":"#","page":"Introduction to UHDBindings","title":"Introduction to UHDBindings","text":"This simple package proposes some bindings to the UHD, the C driver of the Universal Software Radio Peripheral USRP ","category":"page"},{"location":"#","page":"Introduction to UHDBindings","title":"Introduction to UHDBindings","text":"The purpose is to able to see the radio peripheral inside a Julia session and to be able to send and receive complex samples direclty within a Julia session. ","category":"page"},{"location":"#Installation-1","page":"Introduction to UHDBindings","title":"Installation","text":"","category":"section"},{"location":"#","page":"Introduction to UHDBindings","title":"Introduction to UHDBindings","text":"The package can be installed with the Julia package manager. From the Julia REPL, type ] to enter the Pkg REPL mode and run:","category":"page"},{"location":"#","page":"Introduction to UHDBindings","title":"Introduction to UHDBindings","text":"pkg> add UHDBindings","category":"page"},{"location":"#","page":"Introduction to UHDBindings","title":"Introduction to UHDBindings","text":"Or, equivalently, via the Pkg API:","category":"page"},{"location":"#","page":"Introduction to UHDBindings","title":"Introduction to UHDBindings","text":"julia> import Pkg; Pkg.add(\"UHDBindings\")","category":"page"},{"location":"#Documentation-1","page":"Introduction to UHDBindings","title":"Documentation","text":"","category":"section"},{"location":"#","page":"Introduction to UHDBindings","title":"Introduction to UHDBindings","text":"The base documentation with the different functions can be found in the base section\nDifferent examples are described in in the example section. Other examples are provided in the example subfolder of the project. ","category":"page"},{"location":"Examples/example_setup/#Set-up-a-Radio-Link-and-get-some-samples-1","page":"Set up a Radio Link and get some samples","title":"Set up a Radio Link and get some samples","text":"","category":"section"},{"location":"Examples/example_setup/#","page":"Set up a Radio Link and get some samples","title":"Set up a Radio Link and get some samples","text":"In order to get 4096 samples at 868MHz with a instantaneous bandwidth of 16MHz, with a 30dB Rx Gain, the following Julia code should do the trick. ","category":"page"},{"location":"Examples/example_setup/#","page":"Set up a Radio Link and get some samples","title":"Set up a Radio Link and get some samples","text":"function main()\n\t# ---------------------------------------------------- \n\t# --- Physical layer and RF parameters \n\t# ---------------------------------------------------- \n\tcarrierFreq\t= 868e6; \t# --- The carrier frequency (Hz)\t\n\tsamplingRate\t= 16e6;         # --- Targeted bandwidth (Hz)\n\trxGain\t\t= 30.0;         # --- Rx gain (dB)\n\tnbSamples\t= 4096;         # --- Desired number of samples\n\n\t# ---------------------------------------------------- \n\t# --- Getting all system with function calls  \n\t# ---------------------------------------------------- \n\t# --- Creating the radio resource \n\t# The first parameter is for specific parameter (FPGA bitstream, IP address)\n\tradio\t= openUHD(\"Rx\",carrierFreq,samplingRate,rxGain);\n\t# --- Display the current radio configuration\n\tprint(radio);\n\t# --- Getting a buffer from the radio \n\tsigAll\t= getBuffer(radio,nbSamples);\n\t# --- Release the radio resources\n\tclose(radio); \nend","category":"page"}]
}

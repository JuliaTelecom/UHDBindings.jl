module TestTxRx

using UHDBindings 



function mainCarrierFreq()

    # --- Initial mode 
    carrierFreq     = 868e6;
    samplingRate    = 4e6;
    gain            = 12;
    # 
    radio = openUHD(carrierFreq,samplingRate,gain);
    #
    print(radio.tx);
    # 
    updateCarrierFreq!(radio.rx,2400e6);
    #
    updateCarrierFreq!(radio.tx,1200e6);
    print(radio) 
    #
    close(radio)

end



function mainSamplingRate()

    # --- Initial mode 
    carrierFreq     = 868e6;
    samplingRate    = 4e6;
    gain            = 12;
    # 
    radio = openUHD(carrierFreq,samplingRate,gain);
    #
    print(radio.tx);
    # 
    updateSamplingRate!(radio.rx,2e6);
    #
    updateSamplingRate!(radio.tx,6e6);
    print(radio) 
    #
    close(radio)

end



end

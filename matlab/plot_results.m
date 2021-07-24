% This script must be run after the completion of DelayEst_Test_f.m

nRow = length(subcs) * length(subcs);
plot_count = 1;
for nFFT_i = 1 : length(nFFTs)
    nFFT = nFFTs(nFFT_i);
    for subc_i = 1 : length(subcs)
        subc = subcs(subc_i);
        
        subplot(nRow, 2, plot_count);
        plot_count = plot_count + 1;
        plot(d, SNR_avg{nFFT_i}{subc_i}, '-+');
        grid on;
        if nFFT_i == length(nFFTs) && subc_i == length(subcs)
            xlabel('distance (meter)');
            ylabel('SNR (dB)');
        end
        title(sprintf('SNR (nFFT=%d,subc=%dkHz)', nFFT, subc/1000));        

        subplot(nRow, 2, plot_count);
        plot_count = plot_count + 1;
        plot(d, Time_Err_Var_sec{nFFT_i}{subc_i} * 1e9, '-o'); % plot the performance curve
        grid on;
        if nFFT_i == length(nFFTs) && subc_i == length(subcs)
            xlabel('distance (meter)');
            ylabel('mean(Estimation error) [ns]');
        end
       
        title(sprintf('delay RMS (nFFT=%d,subc=%dkHz)', nFFT, subc/1000));  
    end
end
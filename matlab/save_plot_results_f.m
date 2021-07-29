
function save_plot_results_f(file_name, nFFTs, subcs, d, SNR_avg, Time_Err_Mean_sec, Time_Err_Var_sec)
close('all')

legends = {};
for nFFT_i = 1 : length(nFFTs)
    nFFT = nFFTs(nFFT_i);
    for subc_i = 1 : length(subcs)
        subc = subcs(subc_i);
        
        subplot(3, 1, 1);
        plot(d, SNR_avg{nFFT_i}{subc_i}, '-+');
        grid on;

        xlabel('distance (meter)');
        ylabel('SNR (dB)');
        legends{numel(legends) + 1} = (sprintf('FFT=%d, Subcarrier=%dkHz', nFFT, subc/1000));
        title(sprintf('SNR vs. distance'));  
        hold on;

        subplot(3, 1, 2);
        plot(d, Time_Err_Mean_sec{nFFT_i}{subc_i} * 1e9, '-o'); % plot the performance curve
        grid on;        
        xlabel('distance (meter)');
        ylabel('mean delay residual error [ns]');
        title(sprintf('mean delay residual error vs. distance'));  
        hold on;
        
        subplot(3, 1, 3);
        plot(d, Time_Err_Var_sec{nFFT_i}{subc_i} * 1e9, '-o'); % plot the performance curve
        grid on;        
        xlabel('distance (meter)');
        ylabel('RMS [ns]');
        title(sprintf('delay RMS vs. distance'));  
        hold on;        
    end
end
subplot(3, 1, 1);
legend(legends, 'Location', 'northeast');
hold off;
subplot(3, 1, 2);
legend(legends, 'Location', 'southeast');
hold off;
subplot(3, 1, 3);
legend(legends, 'Location', 'southeast');
hold off;
saveas(gcf, file_name, 'png');

% Test delay estimator in DL

num_of_sim = 10;       % number of simulation per SNR working point

Gtx = 0;
Grx = 0;
d = [100 : -10 : 50 ];    % distance between base station and the UE in meters
f = 3e9;                % center frequency in Hz 
c = 3e8;                % light speed m/s
h_s = 35;  % height of the base station
h_u = 1.5;  % 

debug_flag = 0;

nFFTs = [2048, 4096];
subcs = [15e3, 30e3]; %, 30e3]; 

SNR_avg = cell(length(nFFTs), length(subcs));
Time_Err_Var_sec = cell(length(nFFTs), length(subcs));
Time_Err_Mean_sec = cell(length(nFFTs), length(subcs));

for nFFT_i = 1 : length(nFFTs)
    nFFT = nFFTs(nFFT_i);
    for subc_i = 1 : length(subcs)
        subc = subcs(subc_i);
        Tx_max_power = 50; % 40dBm = 10W, 50dBm = 100W
        Ts_sec = (1/(subc * nFFT));                                     % For example, when cell bandwidth = 20MHz, 1Ts = (1/(15e3 * 2048)) second       
        Tx_pwr_dBm = Tx_max_power + 10 * log10(nFFT / min(nFFTs) * subc / min(subcs)) ;         % 20dBm = 100mW for 20MHz as the baseline. The larger the cell bandwidth, the higher of the transmission power.
        Tx_power_scaling_dB = -40;                                      % Tx power scaling in PSS signal
        Tx_Gain = 90;                                                   % Tx gain in the DAC conversion
        Fft_Scale_dB = 10 * log10(nFFT / min(nFFTs));
                % channel gain     

        TimeErr_sec = zeros(num_of_sim, length(channels_gains));
        SNR_dB = zeros(num_of_sim, length(channels_gains));
        TimeEst_Err_Ts = zeros(num_of_sim, length(channels_gains));

        for h_idx = 1 : length(channels_gains)
            fprintf('d=%d meter:\n', d(h_idx))
            
            r = d(h_idx);
            theta_s = atan2(r, (h_s + h_u));
            r_s = h_s * tan(theta_s);
            r_u = r - r_s;
            r1 = sqrt((h_s - h_u) * (h_s - h_u) + r * r);
            r2 = sqrt(h_s * h_s + r_s * r_s);
            r3 = sqrt(h_u * h_u + r_u * r_u);           
            FSPL_r1 = 20 * log10(r1) + 20 * log10(f) + 20 * log10(4*pi/c)- Gtx - Grx;   % refer to https://www.everythingrf.com/rf-calculators/free-space-path-loss-calculator
            channels_gains_dBm_r1 = Tx_pwr_dBm + Tx_power_scaling_dB + Tx_Gain + Fft_Scale_dB - FSPL_r1;
            channels_gains_r1 = 10 .^((channels_gains_dBm_r1)/20);   
            
            FSPL_r2r3 = 20 * log10(r2 + r3) + 20 * log10(f) + 20 * log10(4*pi/c)- Gtx - Grx; 
            channels_gains_dBm_r2r3 = Tx_pwr_dBm + Tx_power_scaling_dB + Tx_Gain + Fft_Scale_dB - FSPL_r2r3;
            channels_gains_r2r3 = 10 .^((channels_gains_dBm_r2r3)/20) * -1;  % the sign of the electric field is reversed, so -1 is multiplied to channel gain in r2r3
            
            
            h = channels_gains_r1 + channels_gains_r2r3;  
            for idx = 1 : num_of_sim
                
%                 if (mod(idx, 1) == 0)
%                     fprintf('.');
%                 end
%                 if (mod(idx, 1) == 0)
%                     fprintf('\n');                
%                 end
                seed = idx;
                ideal_delay_second = d(h_idx) / c; % calculate the delay by distance (in second)
                ideal_delay_Ts = ceil(ideal_delay_second / Ts_sec); % calculate the delay by distance (in Ts, i.e., sample)
                ideal_delay_second_quantized = ideal_delay_Ts * Ts_sec;
                [SNRdB, TimeEstTs] = DelayEst_f(nFFT, subc, h, ideal_delay_Ts, seed, debug_flag); % execute delay estimation in UE side
                SNR_dB(idx, h_idx) = SNRdB;
                TimeEst_Err_Ts(idx, h_idx) = TimeEstTs - ideal_delay_Ts;
                TimeErr_sec(idx, h_idx) = (TimeEstTs * Ts_sec - ideal_delay_second_quantized);

                if (mod(idx, 1) == 0)
                    TimeEst_second = TimeEstTs * Ts_sec;
                    fprintf('ideal delay = %f(us), Estimated delay = %f(us), error = %f(us)\n', ideal_delay_second_quantized * 1e6,  TimeEst_second * 1e6, (TimeEst_second - ideal_delay_second_quantized) * 1e6);
                end

            end
        end


        Threshold_second = 5 * Ts_sec * nFFT / min(nFFTs); % A threshold to decide wheter an timing estimation is valid or not. If an timing estimation error is larger than this threshold, it should be dropped.
        SNR_avg{nFFT_i}{subc_i} = mean(SNR_dB, 1);
        % TimeErr_avg = mean(TimeErr_sec, 1);
        Time_Err_Var_second = zeros(length(d), 1);
        Time_Err_Mean_second = zeros(length(d), 1);
        for idx = 1 : length(d)
            Reliable_Estimation = abs(TimeErr_sec(:, idx)) < Threshold_second; % only keep those estimation error within the threshold as the reliables ones for RMS calculation
            Time_Err_Var_second(idx) = sqrt(var(abs(TimeErr_sec(Reliable_Estimation, idx))));
            Time_Err_Mean_second(idx) = mean(TimeErr_sec(Reliable_Estimation, idx));
        end
        Time_Err_Var_sec{nFFT_i}{subc_i} = Time_Err_Var_second;
        Time_Err_Mean_sec{nFFT_i}{subc_i} = Time_Err_Mean_second;
        fprintf('when nFFT = %d, subcarrier = %fkHz, distance (meter) : RMS(delay_error) (ns)\n', nFFT, subc/1000);
        for idx = 1 : length(d)
            fprintf('    %.2f : %f\n', d(idx), Time_Err_Var_sec{nFFT_i}{subc_i}(idx) * 1e9)
        end
    end
end


run('plot_results_v2');


    
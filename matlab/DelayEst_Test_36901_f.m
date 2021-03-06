% Test delay estimator in DL

num_of_sim = 50;       % number of simulation per SNR working point

Gtx = 0;
Grx = 0;
d = [200 : -50 : 100 ];    % distance between base station and the UE in meters
f = 3e9;                % center frequency in Hz 
c = 3e8;                % light speed m/s
h_BS = 35;  % height of the base station
h_UT = 1.5;  % 
W = 20; % avg. street width
h = 5; % avg. building height 
f_c = 3.5e9; % 3.5GHz

% initial the random seed
seed = 1;
s = RandStream('mt19937ar','Seed', seed);
RandStream.setGlobalStream(s);

debug_flag = 0;


channel_models  = {'3GPP38.901'};
scenario = 'RMa';
hasShadowing = true;
incorporate_O2I = true;
O2I_wall_materials = {'glass', 'IIRglass', 'concrete', 'wood'};


    
nFFTs = [2048, 4096];
subcs = [15e3, 30e3]; %, 30e3];

SNR_avg = cell(length(nFFTs), length(subcs));
Time_Err_Var_sec = cell(length(nFFTs), length(subcs));
Time_Err_Mean_sec = cell(length(nFFTs), length(subcs));
TimeEst_sec = cell(length(nFFTs), length(subcs));

for n_material = 1 : length(O2I_wall_materials)
    O2I_wall_material = O2I_wall_materials{n_material};

    for nFFT_i = 1 : length(nFFTs)
        nFFT = nFFTs(nFFT_i);
        for subc_i = 1 : length(subcs)
            subc = subcs(subc_i);
            Tx_max_power = 20; % 20dBm = 100mW, 40dBm = 10W, 50dBm = 100W
            Ts_sec = (1/(subc * nFFT));                                     % For example, when cell bandwidth = 20MHz, 1Ts = (1/(15e3 * 2048)) second
            Tx_pwr_dBm = Tx_max_power + 10 * log10(nFFT / min(nFFTs) * subc / min(subcs)) ;         % 20dBm = 100mW for 20MHz as the baseline. The larger the cell bandwidth, the higher of the transmission power.
            Tx_power_scaling_dB = -40;                                      % Tx power scaling in PSS signal
            Tx_Gain = 90;                                                   % Tx gain in the DAC conversion
            Fft_Scale_dB = 10 * log10(nFFT / min(nFFTs));

            TimeErr_sec = zeros(num_of_sim, length(d));
            SNR_dB = zeros(num_of_sim, length(d));
            TimeEst_Err_Ts = zeros(num_of_sim, length(d));
            Time_Est_sec = zeros(num_of_sim, length(d));

            for d_idx = 1 : length(d)
                fprintf('d=%d meter:\n', d(d_idx))
                d_2D = d(d_idx);

                for sim_i = 1 : num_of_sim
                    FSPL = getPathLoss_f(h_BS, h_UT, d_2D, f_c, scenario, hasShadowing, h, W); %20 * log10(r1) + 20 * log10(f) + 20 * log10(4*pi/c)- Gtx - Grx;   % refer to https://www.everythingrf.com/rf-calculators/free-space-path-loss-calculator

                    if(incorporate_O2I)
                        FSPL = FSPL + getO2I_PenetrationLoss_f(scenario, O2I_wall_material, f_c);
                    end


                    channels_gains_dBm = Tx_pwr_dBm + Tx_power_scaling_dB + Tx_Gain + Fft_Scale_dB - FSPL;
                    channels_gains = 10 .^((channels_gains_dBm)/20);
                    h = channels_gains;

                    ideal_delay_second = d(d_idx) / c; % calculate the delay by distance (in second)
                    ideal_delay_Ts = ceil(ideal_delay_second / Ts_sec); % calculate the delay by distance (in Ts, i.e., sample)
                    ideal_delay_second_quantized = ideal_delay_Ts * Ts_sec;
                    [SNRdB, TimeEstTs] = DelayEst_f(nFFT, subc, h, ideal_delay_Ts, debug_flag); % execute delay estimation in UE side
                    SNR_dB(sim_i, d_idx) = SNRdB;
                    TimeEst_Err_Ts(sim_i, d_idx) = TimeEstTs - ideal_delay_Ts;
                    TimeErr_sec(sim_i, d_idx) = (TimeEstTs * Ts_sec - ideal_delay_second_quantized);
                    Time_Est_sec(sim_i, d_idx) = TimeEstTs * Ts_sec;

                    if (mod(sim_i, 1) == 0)
                        TimeEst_second = TimeEstTs * Ts_sec;
                        fprintf('ideal delay = %f(us), Estimated delay = %f(us), error = %f(us) SNR=%f (dB) FSPL=%f\n', ...
                            ideal_delay_second_quantized * 1e6,  TimeEst_second * 1e6, (TimeEst_second - ideal_delay_second_quantized) * 1e6, SNRdB, FSPL);
                    end
                end
            end


            Threshold_second = 5 * Ts_sec * nFFT / min(nFFTs); % A threshold to decide wheter an timing estimation is valid or not. If an timing estimation error is larger than this threshold, it should be dropped.
            SNR_avg{nFFT_i}{subc_i} = mean(SNR_dB, 1);
            % TimeErr_avg = mean(TimeErr_sec, 1);
            Time_Err_Var_second = zeros(length(d), 1);
            Time_Err_Mean_second = zeros(length(d), 1);
            Time_Est_second = zeros(length(d), 1);
            for d_i = 1 : length(d)
                Reliable_Estimation = abs(TimeErr_sec(:, d_i)) < Threshold_second; % only keep those estimation error within the threshold as the reliables ones for RMS calculation
                Time_Err_Var_second(d_i) = sqrt(var(abs(TimeErr_sec(Reliable_Estimation, d_i))));
                Time_Err_Mean_second(d_i) = mean(TimeErr_sec(Reliable_Estimation, d_i));
                Time_Est_second(d_i) = mean(Time_Est_sec(Reliable_Estimation, d_i));
            end
            Time_Err_Var_sec{nFFT_i}{subc_i} = Time_Err_Var_second;
            Time_Err_Mean_sec{nFFT_i}{subc_i} = Time_Err_Mean_second;
            TimeEst_sec{nFFT_i}{subc_i} = Time_Est_second;
            fprintf('when nFFT = %d, subcarrier = %fkHz, distance (meter) : mean(delay) mean(delay error) RMS(delay_error) (ns)\n', nFFT, subc/1000);
            for d_i = 1 : length(d)
                fprintf('    %.2f : %.05f %.05f %.05f\n', d(d_i), TimeEst_sec{nFFT_i}{subc_i}(d_i) * 1e9, Time_Err_Mean_sec{nFFT_i}{subc_i}(d_i) * 1e9, Time_Err_Var_sec{nFFT_i}{subc_i}(d_i) * 1e9)
            end
        end
    end

    if (hasShadowing)
        tag = 'shadowing';
    else
        tag = 'noshadowing';
    end
    file_name = sprintf('%s_%s_%s', O2I_wall_material, scenario, tag);
    save_plot_results_f(file_name, nFFTs, subcs, d, SNR_avg, TimeEst_sec, Time_Err_Mean_sec, Time_Err_Var_sec);
end





    
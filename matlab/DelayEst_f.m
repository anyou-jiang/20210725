function [SNRdB_o, TimeEstTs_o] = DelayEst_f(nFFT_i, subc_i, h_i, DelayTs_i, debug_i)

nFFT = nFFT_i;
subc = subc_i;
pss_len = 127; % length of the pss sequence
ofdm_len = nFFT; % length of an ofdm symbol

cell_bandwidth = 20e6;
if subc_i == 15e3 && nFFT_i == 2048
    cell_bandwidth = 20e6; % 20MHz
elseif subc_i == 15e3 && nFFT_i == 4096
    cell_bandwidth = 40e6;
elseif subc_i == 30e3 && nFFT_i == 2048
    cell_bandwidth = 40e6;
elseif subc_i == 30e3 && nFFT_i == 4096
    cell_bandwidth = 80e6;
else
    error('currently only supporting FFT length = 2048, 4096, and subcarrier = 15kHz and 30kHz.')
end

N_ID_2 = 2; 
pss_d_n = pss_sequence(N_ID_2); % generate PSS sequence according to 3GPP 38.211 section 7

ofdm_pss = [pss_d_n ; zeros(ofdm_len - pss_len, 1)]; % padding with zero subcarriers
ofdm_pss_time = ifft(ofdm_pss) * sqrt(length(ofdm_pss)); % transform from frequency domain to time domain by IFFT

% plot(abs(ofdm_pss_time))
avg_signal_pwr = mean(abs(ofdm_pss_time).^2); % estimate pss signal power in time domain within an ofdm symbol
if (debug_i)
    fprintf('average pss power = %.9f\n', avg_signal_pwr);
end

% noise
Rx_Gain = 90; % the Rx Gain in ADC converter
K = (1.3807) * 10^(-23);
T = 290;

B = cell_bandwidth; 
ThermalNoise_dBm = 10 * log10(K * T * B) + 30; % https://www.rfcafe.com/references/electrical/noise-power.htm
No = 10^ ((ThermalNoise_dBm + Rx_Gain) / 10);

nsymbols = 4;
tx_signal_len = nFFT * nsymbols;  % In this simulation, it is to simulation 4 ofdm symbol length signal, this doesn't impact final the performance
noise_real = normrnd(0, sqrt(No / 2), tx_signal_len, 1);
noise_imag = normrnd(0, sqrt(No / 2), tx_signal_len, 1);

noise = noise_real + 1i * noise_imag;  % create complex noise
avg_noise_pwr = mean(abs(noise).^2);  % estimate noise power per sample


% LOS channel with delay T (integer of Ts)
delay_Ts = DelayTs_i;
Ts_sec = (1/(subc * nFFT));  % 1Ts, depending on sampling rate = subc * nFFT
h = h_i; % channel gain in AWGN mode
tx_signal = [ofdm_pss_time; zeros(tx_signal_len - ofdm_len, 1)]; % tx signal transmitted by Base station

if (debug_i)
    subplot(3, 1, 1);
    plot([1 : length(tx_signal)] * Ts_sec * 1000,20 * log10( abs(tx_signal)));
    xlim([1 length(tx_signal)] * Ts_sec * 1000)
    grid on;
    xlabel('time (ms)');
    ylabel('signal power (dB)')
    title('Tx signal from Base Station')
end

tx_signal_delayed = [zeros(delay_Ts, 1); ofdm_pss_time; zeros(tx_signal_len - delay_Ts - ofdm_len, 1)]; % delayed Tx signal that the UE will receive
% plot(abs(tx_signal))

rx_signal_noise = h * tx_signal_delayed + noise; % UE received signal after channel gain and noise

if (debug_i)
    subplot(3, 1, 2);
    plot([1 : length(rx_signal_noise)] * Ts_sec * 1000,20 * log10( abs(rx_signal_noise)));
    xlim([1  length(rx_signal_noise)] * Ts_sec * 1000)
    grid on;
    xlabel('time (ms)');
    ylabel('signal power (dB)')
    title('delayed Tx signal that UE will receive')
end

% timing estimation by correlation with the reference signal
pss_ref = conj(ofdm_pss_time);  % conjugate of the original pss sequence as the local base sequence
res_corr = zeros(length(rx_signal_noise) - length(ofdm_pss_time), 1);
for idx = 1 : length(rx_signal_noise) - length(ofdm_pss_time) % step by step correlation between the local base sequence to get the corrections
    rx_signal_corr = rx_signal_noise(idx : idx + length(pss_ref) - 1);
    res_corr(idx) = abs(mean(rx_signal_corr .* pss_ref));
end

if (debug_i)
    subplot(3, 1, 3);
    plot([1 : length(res_corr)] * Ts_sec * 1000,  abs(res_corr));
    xlim([1  length(rx_signal_noise)] * Ts_sec * 1000)
    grid on;
    xlabel('time (ms)');
    ylabel('correlation');
    title('correlation peak the UE has detected');
end

[~, peak_idx] = max(res_corr); % detect the correlation peak, the location of the peak is the DL delay

est_time_delay_Ts = peak_idx - 1; % shift by one because in matlab the indexing is starting from 1
est_time_delay_second = est_time_delay_Ts * Ts_sec; % convert from Ts to second
est_SNR = 10 * log10(avg_signal_pwr * abs(h)^2 / avg_noise_pwr);

if (debug_i)
    fprintf('SNR = %.9f (dB) \n', est_SNR);
    fprintf('estimated delay = %.9f (Ts)\n', est_time_delay_Ts)
    fprintf('estimated delay = %.9f (sec)\n', est_time_delay_second)
end

SNRdB_o = est_SNR;
TimeEstTs_o = est_time_delay_Ts;











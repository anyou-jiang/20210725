
seed = 1;
d = 300; % m
c = 3e8; % light speed m/s
Ts_sec = (1/(15e3 * 2048));
ideal_delay_Ts = ceil((d / c) / Ts_sec);
h = 1.0 * exp(1i * pi/4); % the channel gain in AWGN LOS channel
[SNRdB, TimeEstTs] = DelayEst_f(h, ideal_delay_Ts, seed, 1);
ideal_delay_second = ideal_delay_Ts * Ts_sec;
TimeEst_second = TimeEstTs * Ts_sec;
fprintf('ideal delay = %f(us), Estimated delay = %f(us), error = %f(us)\n', ideal_delay_second * 1e6,  TimeEst_second * 1e6, (TimeEst_second - ideal_delay_second) * 1e6);


function PL = getPathLoss_f(h_BS, h_UT, d_2D, f_c, scenario, LosOrNlos, h, W)
% get the path loss according to 3GPP TR38.901, table 7.4.1-1 Pathloss
% models
c = 3.0 * 1e8;
f_c_GHz = f_c / 1e9; % In the footnote [6] of table 7.4.1-1, fc denotes the center frequency normalized by 1GHz

switch scenario
    case 'RMa'
        d_BP = 2 * pi * h_BS * h_UT * f_c / c; % In the footnote [5] of table 7.4.1-1, Break point distance dBP = 2π hBS hUT fc/c, where fc is the centre frequency in Hz
        d_3D = sqrt(d_2D ^2 + (h_BS - h_UT)^2);
        PL_1 = 20 * log10(40 * pi * d_3D * f_c_GHz / 3) + min(0.03 * h ^ 1.72, 10) * log10(d_3D) - min(0.044 * h ^ 1.72, 14.77) + 0.002 * log10(h) * d_3D;
        
        d_3D_BP = sqrt(d_BP ^2 + (h_BS - h_UT)^2);
        PL_1_BP = 20 * log10(40 * pi * d_3D_BP * f_c_GHz / 3) + min(0.03 * h ^ 1.72, 10) * log10(d_3D_BP) - min(0.044 * h ^ 1.72, 14.77) + 0.002 * log10(h) * d_3D_BP;
        
        PL_2 = PL_1_BP + 40 * log10(d_3D / d_BP);
        
        if d_2D <= d_BP
            PL_RMa_LOS = PL_1;
            Sigma_SF = 4;
        else
            PL_RMa_LOS = PL_2;
            Sigma_SF = 6;
        end
        
        PL_prime_RMa_NLOS = 161.04 - 7.1 * log10(W) + 7.5 * log10(h) - (24.37 - 3.7 * (h/h_BS)^2) * log10(h_BS) + (43.42 - 3.1 * log10(h_BS)) * (log10(d_3D) - 3) + 20 * log10(f_c_GHz) - (3.2 * (log10(11.75 * h_UT))^2 - 4.97);
        PL_RMa_NLOS = max(PL_RMa_LOS, PL_prime_RMa_NLOS);
        
        switch LosOrNlos
            case 'LOS'
                PL = PL_RMa_LOS + normrnd(0, Sigma_SF); % \Sigma_SF = 4 dB/6 dB in shadow fading
            case 'NLOS'
                Sigma_SF = 8;
                PL = PL_RMa_NLOS + normrnd(0, Sigma_SF); % \Sigma_SF = 8 dB in shado fading
            otherwise
                error('Only LOS or NLOS is supported.\n');
        end
    
    otherwise
        error('Only RMa is supported.\n');

end
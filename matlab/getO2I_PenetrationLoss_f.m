function Penetration_Loss = getO2I_PenetrationLoss_f(scenario, O2I_wall_material, f_Hz)

f_GHz = f_Hz / 1e9;

switch scenario
    case 'RMa'
        switch O2I_wall_material
            case 'glass'
                L_material = 2 + 0.2 * f_GHz;
            case 'IIRglass'
                L_material = 23 + 0.3 * f_GHz;
            case 'concrete'
                L_material = 5 + 4 * f_GHz;
            case 'wood'
                L_material = 4.85 + 0.12 * f_GHz;      
            otherwise
                error('Only Standard multi-pane glass, IRR glass, Concrete, Wood are supported in O2I penetration.\n');   
        end
        
        % Only the low-loss model is applicable to RMa. 
        sigma_p = 4.4;
        d_2D_in = min(rand() * 10, rand() * 10);  % d_2D_in is minimum of two independently generated uniformly distributed variables between 0 and 10 m for RMa.
        PL_in = 0.5 * d_2D_in;
        PL_tw = 5 - 10 * log10(1.0 * 10 ^ (-L_material/10));
        Penetration_Loss = PL_tw + PL_in + normrnd(0, sigma_p);
        
    otherwise
        error('Only RMa is supported in O2I penetration.\n');   
end

end
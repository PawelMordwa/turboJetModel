%% Parametric Compressor and Turbine Maps for Simulink + Plots
% Nred in [0,1], Compressor input: (Wc, Nred) -> (PR, eta)
% Turbine input: (PR, Nred) -> (Wc, eta)

%% Grids
Nred_vec = linspace(0.0,1.0,51);   % reduced speed [0..1]
Wc_vec   = linspace(6.0,18.0,121); % corrected flow for compressor
PR_vec   = linspace(1.2,4.6,111);  % pressure ratio for turbine

%% Compressor map generation
[Wc_grid,Nred_grid] = meshgrid(Wc_vec,Nred_vec);
PR_grid  = zeros(size(Wc_grid));
eta_grid = zeros(size(Wc_grid));
for i = 1:numel(Nred_grid)
    [PR_grid(i), eta_grid(i)] = compressor_fun(Wc_grid(i), Nred_grid(i));
end

Compressor_Wc   = Wc_vec;
Compressor_Nred = Nred_vec;
Compressor_PR   = PR_grid;   % size [length(Nred) x length(Wc)]
Compressor_eta  = eta_grid;

%% Turbine map generation
[PR_grid_t,Nred_grid_t] = meshgrid(PR_vec,Nred_vec);
WcT_grid  = zeros(size(PR_grid_t));
etaT_grid = zeros(size(PR_grid_t));
for i = 1:numel(Nred_grid_t)
    [WcT_grid(i), etaT_grid(i)] = turbine_fun(PR_grid_t(i), Nred_grid_t(i));
end

Turbine_PR   = PR_vec;
Turbine_Nred = Nred_vec;
Turbine_Wc   = WcT_grid;
Turbine_eta  = etaT_grid;

%% --- PLOTS ---
figure; surf(Wc_grid,Nred_grid,PR_grid);
xlabel('Wc corr'); ylabel('N_{red}'); zlabel('PR');
title('Compressor Pressure Ratio Surface'); shading interp; colorbar;

figure; surf(Wc_grid,Nred_grid,eta_grid);
xlabel('Wc corr'); ylabel('N_{red}'); zlabel('\eta');
title('Compressor Efficiency Surface'); shading interp; colorbar;

figure; surf(PR_grid_t,Nred_grid_t,WcT_grid);
xlabel('PR'); ylabel('N_{red}'); zlabel('Wc corr');
title('Turbine Flow Surface'); shading interp; colorbar;

figure; surf(PR_grid_t,Nred_grid_t,etaT_grid);
xlabel('PR'); ylabel('N_{red}'); zlabel('\eta');
title('Turbine Efficiency Surface'); shading interp; colorbar;

%% Example helper functions (same as before)
function [PR, eta] = compressor_fun(Wc, Nred)
    [~, Wc_ref, PR_peak, slope_low, slope_high, eta_max, width, Wc_peak_eta] = comp_params(Nred);
    PR  = comp_PR_shape(Wc, Wc_ref, PR_peak, slope_low, slope_high);
    eta = eff_dome(Wc, Wc_peak_eta, width, eta_max, -0.1);
end
function [Wc, eta] = turbine_fun(PR, Nred)
    [~, Wc_choke, PR_cap, eta_max, eta_peak_PR, eta_width] = turb_params(Nred);
    Wc  = turb_Wc_vs_PR(PR, PR_cap, Wc_choke);
    eta = eff_dome(PR, eta_peak_PR, eta_width, eta_max, 0.0);
end
function eta = eff_dome(x,xp,w,etamax,skew)
    z = (x - xp)/w;
    base = exp(-0.5*z.^2);
    skew_term = 1 + skew*(z.^3)/3.0;
    eta = max(min(etamax .* base .* skew_term,0.95),0.4);
end
function PR = comp_PR_shape(Wc,Wc_ref,PR_peak,sl,sh)
    PR = PR_peak - sl*tanh((Wc - Wc_ref)/0.7) ...
                 - sh*tanh((Wc - (Wc_ref+1.5))/0.8);
end
function Wc = turb_Wc_vs_PR(PR,PR_cap,Wc_choke)
    x = (PR-1.0)/max(PR_cap-1.0,1e-6);
    x = min(max(x,0),1.2);
    Wc = Wc_choke*(0.6 + 0.6*sqrt(min(max(x,0),1))) .* (1.0 - 0.15*(x-0.8).^2);
end
function [Nc,Wc_ref,PR_peak,sl,sh,etamax,w,Wc_peak_eta] = comp_params(Nred)
    Nc = 0.75 + 0.30*Nred;
    Wc_ref = 8.5 + 4.5*Nred;
    PR_peak = 2.6 + 1.9*(0.8 + 0.2*Nred);
    sl = 1.0 + 0.3*(1-Nred);
    sh = 0.7 + 0.3*Nred;
    etamax = 0.78 + 0.08*Nred;
    w = 2.4 - 0.6*Nred;
    Wc_peak_eta = Wc_ref + (0.0 + 0.3*Nred);
end
function [Nt,Wc_choke,PR_cap,etamax,eta_peak_PR,eta_width] = turb_params(Nred)
    Nt = 0.70 + 0.35*Nred;
    Wc_choke = 7.2 + 2.0*Nred;
    PR_cap = 3.8 + 0.6*Nred;
    etamax = 0.82 - 0.02*(1 - Nred);
    eta_peak_PR = 2.9 + 0.7*Nred;
    eta_width = 0.85;
end

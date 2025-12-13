% --- KONFIGURACJA ROZDZIELCZOŚCI ---
n_points = 10; % Liczba linii obrotów (było 5, jest 10)
beta_points = 10; % Liczba punktów na linii beta

%% 1. MAPA SPRĘŻARKI (Compressor Map)
% Zakresy
C_Nc_vec = linspace(0.5, 1.05, n_points); % Obroty skorygowane (0.5 do 1.05)
C_Beta_vec = linspace(0, 1, beta_points); % Beta (0=Surge, 1=Choke)

% Inicjalizacja macierzy
C_PR_map = zeros(n_points, beta_points);
C_Wc_map = zeros(n_points, beta_points);
C_Eff_map = zeros(n_points, beta_points);

% Generowanie proceduralne (Fizyka zjawiska)
for i = 1:length(C_Nc_vec)
    N = C_Nc_vec(i);
    for j = 1:length(C_Beta_vec)
        B = C_Beta_vec(j);
        
        % Model Sprężu: Rośnie z N^2, maleje wraz z Betą (krzywa opadająca)
        % PR_nom = 5.8 (skalowanie nastąpi w Simulinku, tu są wartości znormalizowane)
        max_pr_at_speed = 1 + (1.25 - 1) * N^2.5; % Peak PR dla danej prędkości
        drop_factor = 0.25 * B^2; % Zakrzywienie charakterystyki
        C_PR_map(i,j) = max_pr_at_speed * (1 - drop_factor);
        
        % Model Przepływu: Rośnie liniowo z N, rośnie z Betą (odtykanie)
        base_flow = N; 
        flow_spread = 0.15 * N * B; % Przepływ rośnie wzdłuż linii stałych obrotów
        C_Wc_map(i,j) = (base_flow * 0.85) + flow_spread;
        
        % Model Sprawności: Parabola z wierzchołkiem w środku (Beta=0.5)
        % Sprawność spada dla niskich obrotów
        peak_eff = 1.0 - (1-N)^2; % Niższa sprawność na wolnych obrotach
        off_design_penalty = 0.2 * (B - 0.55)^2; % Kara za bycie poza "sercem" mapy
        C_Eff_map(i,j) = max(0.6, peak_eff - off_design_penalty);
    end
end

%% 2. MAPA TURBINY (Turbine Map)
% Turbina w małym silniku szybko się zatyka (choked flow)
T_Nc_vec = linspace(0.5, 1.05, n_points);
T_PR_vec = linspace(1.2, 3.5, n_points); % Spręż turbiny (Pressure Ratio)

T_Wc_map = zeros(n_points, n_points);
T_Eff_map = zeros(n_points, n_points);

for i = 1:length(T_Nc_vec)
    N = T_Nc_vec(i);
    for j = 1:length(T_PR_vec)
        PR = T_PR_vec(j);
        
        % Model Przepływu: Charakterystyka dyszowa (pierwiastek) z nasyceniem
        % Wzór Saint-Venant-Wantzel (uproszczony)
        choke_limit = 1.0 + (N-1)*0.02; % Lekka zależność od obrotów
        flow_raw = 1.4 * sqrt(1 - (1/PR)^1.8); % Fizyka przepływu
        T_Wc_map(i,j) = min(choke_limit, flow_raw); % Saturacja (Zatkanie)
        
        % Model Sprawności: Zależy głównie od u/c (velocity ratio), tu uproszczone
        eff_base = 1.0 - 0.3*(1-N)^2;
        eff_pr_factor = 1.0 - 0.05*(PR-2.5)^2;
        T_Eff_map(i,j) = max(0.5, eff_base * eff_pr_factor);
    end
end

%% --- RYSOWANIE CHARAKTERYSTYK (MATLAB) ---

% Ustawienia ogólne wykresów
colors = lines(length(C_Nc_vec)); % Generowanie palety kolorów dla linii obrotów

%% 1. WYKRESY 2D - SPRĘŻARKA
hfig1 = figure('Name', 'compressor pr', 'Color', 'w');

% A) Mapa Pracy (Spręż vs Przepływ)
hold on;
%grid on;
xlabel('Corrected air flow ($\dot{m}_{corr}$)');
ylabel('Corrected compressor preasure ratio ($\pi_{c,corr}$)');

% Rysowanie linii stałych obrotów (Speed lines)
for i = 1:length(C_Nc_vec)
    digits(2);
    plot(C_Wc_map(i, :), C_PR_map(i, :), '-o', ...
        'Color', colors(i, :), ...
        'DisplayName', ['$n_{corr} = $' num2str(C_Nc_vec(i), '%.2f')]);
end


% Rysowanie Linii Pompażu (Surge Line) - punkty dla Beta=0 (pierwsza kolumna)
plot(C_Wc_map(:, 1), C_PR_map(:, 1), '--r', 'LineWidth', 2, 'DisplayName', 'Surge line');
legend('Location', 'best');
hold off;
xlim([0, 1.1]);

hfig2 = figure('Name', 'compressor eta', 'Color', 'w');
% B) Mapa Sprawności (Sprawność vs Przepływ)
hold on;
%grid on;
xlabel('Corrected air flow ($dot{m}_{corr}$)');
ylabel('Corrected compressor efficiency ($\eta_{c,corr}$)');

for i = 1:length(C_Nc_vec)
    plot(C_Wc_map(i, :), C_Eff_map(i, :), '-o', ...
        'Color', colors(i, :), ...
        'DisplayName', ['$n_{corr}$ = ' num2str(C_Nc_vec(i), '%.2f')]);
end
legend('Location', 'best');
hold off;
xlim([0, 1.1]);

%% 2. WYKRESY 2D - TURBINA
hfig3 = figure('Name', 'Charakterystyki Turbiny W_corr', 'Color', 'w');

% A) Charakterystyka przepływowa (Przepływ vs Spręż)
hold on;
%grid on;
xlabel('Turbine presure ratio ($\pi_t$)');
ylabel("Corrected exhaust gas flow  ($\dot{m}'_{corr}$)");

% Oś X dla turbiny jest stała (T_PR_vec), oś Y się zmienia (T_Wc_map)
    plot(T_PR_vec, T_Wc_map(1, :), '-s', ...
        'Color', colors(i, :), ...
        'DisplayName', ['$n_{corr}$ = ' num2str(T_Nc_vec(i), '%.2f')]);
legend('Location', 'best');
hold off;
xlim([0, 3.5]);

hfig4 = figure('Name', 'Charakterystyki Turbiny eta', 'Color', 'w');
% B) Sprawność Turbiny (Sprawność vs Spręż)
hold on;
%grid on;
xlabel('Turbine presure ratio ($\pi_t$)');
ylabel('Corrected turbine efficiency ($\eta_{t,corr}$)');

for i = 1:length(T_Nc_vec)
    plot(T_PR_vec, T_Eff_map(i, :), '-s', ...
        'Color', colors(i, :), ...
        'DisplayName', ['$n_{corr}$ = ' num2str(T_Nc_vec(i), '%.2f')]);
end
legend('Location', 'best');
hold off;
xlim([0, 3.5]);

hfig = [hfig1, hfig2, hfig3, hfig4,hfig5, hfig6, hfig7, hfig8, hfig9];
picturewidth = 20;
hw_ratio = 0.65;
set(findall(hfig, '-property', 'FontSize'),'FontSize', 15);
set(findall(hfig,'-property', 'Box'),'Box', 'off');
set(findall(hfig, '-property', 'Interpreter'), 'Interpreter','latex');
set(findall(hfig, '-property', 'TickLabelInterpreter'), 'TickLabelInterpreter','latex');
set(hfig,'Units', 'centimeters', 'Position', [3 3 picturewidth hw_ratio*picturewidth]);

pos = get(hfig5,'Position');
set(hfig5, 'PaperPositionMode', 'Auto', 'PaperUnits', 'centimeters', 'PaperSize', [pos(3), pos(4)]);
print(hfig5,'png_figure','-dpng', '-vector');
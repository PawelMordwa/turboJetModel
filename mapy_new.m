% --- DANE MAPY SPRĘŻARKI (ZNORMALIZOWANE) ---
% Wektory wejściowe (indeksy tabeli)
C_Nc_vec = [0.5, 0.8, 0.9, 1.0, 1.05]; % Skorygowana prędkość obrotowa (n / sqrt(T))
C_Beta_vec = [0, 0.25, 0.5, 0.75, 1.0]; % Współrzędna pomocnicza (0=pompaż, 1=zatkanie/praca jałowa)

% 1. Mapa Sprężu (Pressure Ratio / PR_des)
% Wartości > 1.0 oznaczają, że dla wyższych obrotów spręż rośnie ponad nominalny
C_PR_map = [
    0.25, 0.24, 0.22, 0.20, 0.18;  % n=0.5
    0.65, 0.62, 0.58, 0.52, 0.45;  % n=0.8
    0.85, 0.82, 0.78, 0.70, 0.60;  % n=0.9
    1.10, 1.05, 1.00, 0.92, 0.80;  % n=1.0 (DP przy Beta=0.5)
    1.25, 1.18, 1.12, 1.05, 0.90   % n=1.05
];

% 2. Mapa Przepływu Skorygowanego (W_corr / W_des)
C_Wc_map = [
    0.30, 0.32, 0.34, 0.35, 0.36;
    0.68, 0.70, 0.72, 0.73, 0.74;
    0.85, 0.88, 0.90, 0.91, 0.92;
    0.96, 0.98, 1.00, 1.01, 1.02; % Punkt pracy (1.0, 1.0)
    1.02, 1.04, 1.06, 1.07, 1.08
];

% 3. Mapa Sprawności (Eff / Eff_des)
% Sprawność spada przy oddalaniu się od linii współpracy (Beta ok. 0.5)
C_Eff_map = [
    0.70, 0.75, 0.78, 0.70, 0.60;
    0.85, 0.90, 0.92, 0.85, 0.75;
    0.92, 0.96, 0.98, 0.92, 0.80;
    0.94, 0.98, 1.00, 0.94, 0.85; % Max sprawność w DP
    0.90, 0.94, 0.96, 0.90, 0.80
];

% --- DANE MAPY TURBINY (ZNORMALIZOWANE) ---
T_Nc_vec = [0.5, 0.8, 0.9, 1.0, 1.05];
T_PR_vec = [1.5, 2.0, 2.5, 3.0, 3.5]; % Spręż turbiny (P_in / P_out)

% 1. Mapa Przepływu Skorygowanego Turbiny (W_corr / W_des)
% Zauważ "wypłaszczenie" - efekt zatkania (choking)
T_Wc_map = [
    0.60, 0.75, 0.85, 0.88, 0.90; % n=0.5
    0.70, 0.85, 0.95, 0.98, 0.99;
    0.72, 0.88, 0.98, 1.00, 1.01;
    0.73, 0.89, 0.99, 1.00, 1.01; % n=1.0
    0.73, 0.89, 0.99, 1.00, 1.01
];

% 2. Mapa Sprawności Turbiny (Eff / Eff_des)
% Turbina ma szersze "pole" wysokiej sprawności niż sprężarka
T_Eff_map = [
    0.80, 0.85, 0.88, 0.89, 0.88;
    0.85, 0.90, 0.92, 0.93, 0.92;
    0.88, 0.94, 0.96, 0.97, 0.96;
    0.90, 0.96, 0.99, 1.00, 0.99; % DP
    0.90, 0.96, 0.98, 0.99, 0.98
];

%% --- RYSOWANIE CHARAKTERYSTYK (MATLAB) ---

% Ustawienia ogólne wykresów
set(0, 'DefaultLineLineWidth', 1.5);
set(0, 'DefaultAxesFontSize', 10);
colors = lines(length(C_Nc_vec)); % Generowanie palety kolorów dla linii obrotów

%% 1. WYKRESY 2D - SPRĘŻARKA
figure('Name', 'Charakterystyki Sprężarki (2D)', 'Color', 'w');

% A) Mapa Pracy (Spręż vs Przepływ)
subplot(1, 2, 1); hold on; grid on;
title('Mapa Pracy Sprężarki');
xlabel('Skorygowany przepływ masy (W_{corr})');
ylabel('Spręż (PR)');

% Rysowanie linii stałych obrotów (Speed lines)
for i = 1:length(C_Nc_vec)
    plot(C_Wc_map(i, :), C_PR_map(i, :), '-o', ...
        'Color', colors(i, :), ...
        'DisplayName', ['n_{corr} = ' num2str(C_Nc_vec(i))]);
end

% Rysowanie Linii Pompażu (Surge Line) - punkty dla Beta=0 (pierwsza kolumna)
plot(C_Wc_map(:, 1), C_PR_map(:, 1), '--r', 'LineWidth', 2, 'DisplayName', 'Linia Pompażu');
legend('Location', 'best');

% B) Mapa Sprawności (Sprawność vs Przepływ)
subplot(1, 2, 2); hold on; grid on;
title('Sprawność Sprężarki');
xlabel('Skorygowany przepływ masy (W_{corr})');
ylabel('Sprawność adiabatyczna (\eta)');

for i = 1:length(C_Nc_vec)
    plot(C_Wc_map(i, :), C_Eff_map(i, :), '-o', ...
        'Color', colors(i, :), ...
        'DisplayName', ['n_{corr} = ' num2str(C_Nc_vec(i))]);
end
legend('Location', 'best');

%% 2. WYKRESY 2D - TURBINA
figure('Name', 'Charakterystyki Turbiny (2D)', 'Color', 'w');

% A) Charakterystyka przepływowa (Przepływ vs Spręż)
subplot(1, 2, 1); hold on; grid on;
title('Charakterystyka Przepływowa Turbiny');
xlabel('Spręż Turbiny (PR)');
ylabel('Skorygowany przepływ masy (W_{corr})');

% Oś X dla turbiny jest stała (T_PR_vec), oś Y się zmienia (T_Wc_map)
for i = 1:length(T_Nc_vec)
    plot(T_PR_vec, T_Wc_map(i, :), '-s', ...
        'Color', colors(i, :), ...
        'DisplayName', ['n_{corr} = ' num2str(T_Nc_vec(i))]);
end
legend('Location', 'best');

% B) Sprawność Turbiny (Sprawność vs Spręż)
subplot(1, 2, 2); hold on; grid on;
title('Sprawność Turbiny');
xlabel('Spręż Turbiny (PR)');
ylabel('Sprawność (\eta)');

for i = 1:length(T_Nc_vec)
    plot(T_PR_vec, T_Eff_map(i, :), '-s', ...
        'Color', colors(i, :), ...
        'DisplayName', ['n_{corr} = ' num2str(T_Nc_vec(i))]);
end
legend('Location', 'best');

%% 3. WIZUALIZACJA 3D (POWIERZCHNIE)
figure('Name', 'Mapy 3D Sprawności spręzarki', 'Color', 'w');

% Używamy surf do wyrysowania powierzchni
surf(C_Wc_map, C_PR_map, C_Eff_map, 'FaceAlpha', 0.8);
title('Sprężarka: Powierzchnia Sprawności');
xlabel('Przepływ (W_{corr})');
ylabel('Spręż (PR)');
zlabel('Sprawność (\eta)');
colormap(jet); colorbar;
view(-30, 30); % Ustawienie kąta kamery
grid on;

figure('Name', 'Mapy 3D Sprawności spręzarki', 'Color', 'w');
% B) Powierzchnia Sprawności Turbiny
% Dla turbiny musimy stworzyć siatkę dla osi X (PR), bo T_PR_vec to wektor
[T_PR_grid, T_Nc_grid] = meshgrid(T_PR_vec, T_Nc_vec);

% Rysujemy: Oś X=PR, Oś Y=Przepływ, Oś Z=Sprawność
surf(T_PR_grid, T_Wc_map, T_Eff_map, 'FaceAlpha', 0.8);
title('Turbina: Powierzchnia Sprawności');
xlabel('Spręż (PR)');
ylabel('Przepływ (W_{corr})');
zlabel('Sprawność (\eta)');
colormap(jet); colorbar;
view(30, 30);
grid on;
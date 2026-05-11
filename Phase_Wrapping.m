clc; clear; close all;

set(groot,'DefaultAxesFontSize',24);
set(groot,'DefaultTextFontSize',24);

%% =========================
% 1. 时间轴
%% =========================
t = linspace(0, 1000, 2000);

%% =========================
% 2. 原始相位
%% =========================
phi_raw = 3*pi - 0.006*pi .* t;

%% =========================
% 3. 缠绕相位（CORDIC输出）
%% =========================
phi_wrap = mod(phi_raw + pi, 2*pi) - pi;

%% =========================
% 4. 一阶差分
%% =========================
dphi = diff(phi_wrap);
t_diff = t(1:end-1);

%% =========================================================
% 图1：相位缠绕现象
%% =========================================================
figure('Color','w','Position',[100 100 1000 500]); hold on;

plot(t, phi_raw, 'b', 'LineWidth', 4);
plot(t, phi_wrap, '--', 'Color', [0 0.6 0], 'LineWidth', 4);

yline(pi, '--k', 'LineWidth', 1);
yline(-pi, '--k', 'LineWidth', 1);

jump_idx = find(abs(diff(phi_wrap)) > pi);
for i = 1:min(4, length(jump_idx))
    x = t(jump_idx(i));
    plot([x x], [-pi pi], 'k--', 'LineWidth', 3);
end

ylim([-3*pi 3*pi]);
yticks([-3*pi -2*pi -pi 0 pi 2*pi 3*pi]);
yticklabels({'-3\pi','-2\pi','-\pi','0','\pi','2\pi','3\pi'});

ylabel('相位');
title('相位缠绕现象');

legend({'原始相位','缠绕相位'}, 'Location','northeast');
grid on; box on;

% ❗ 去掉横轴
set(gca,'XTickLabel',[]);

%% =========================================================
% 图2：差分结果（未处理）
%% =========================================================
figure('Color','w','Position',[200 200 1000 500]); hold on;

plot(t_diff, dphi, 'r', 'LineWidth', 4);
yline(mean(dphi), '--k', 'LineWidth', 1);

ylabel('差分相位');
title('一阶差分结果（未解缠绕）');

grid on; box on;

% ❗ 去掉横轴
set(gca,'XTickLabel',[]);

%% =========================================================
% 图3：差分解缠绕
%% =========================================================
dphi_unwrap = dphi;

for i = 2:length(dphi_unwrap)
    if dphi_unwrap(i) > pi
        dphi_unwrap(i) = dphi_unwrap(i) - 2*pi;
    elseif dphi_unwrap(i) < -pi
        dphi_unwrap(i) = dphi_unwrap(i) + 2*pi;
    end
end

%% =========================
% 图3绘制
%% =========================
figure('Color','w','Position',[300 300 1000 500]); hold on;

plot(t_diff(2:end), dphi_unwrap(2:end), 'm', 'LineWidth', 4);

ylabel('差分相位解缠绕结果');
title('差分域相位解缠绕结果');

grid on; box on;
ylim([-0.1 0.1]);
% ❗ 去掉横轴（关键）
set(gca,'XTickLabel',[]);
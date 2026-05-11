clc; clear; close all;

%% 1. 参数设置
Fs = 100e6;             % 采样率 100 MHz
N = 4096;               % FFT 点数
t = (0:N-1)'/Fs;        % 时间轴

F_sig = 10e6+1000000;   % 输入信号频率 11 MHz
F_lo = 10e6;            % 本振频率 10 MHz

%% 2. 生成信号
% 输入信号
x = cos(2*pi*F_sig*t);

% 本振信号 (I/Q 正交)
lo_I = cos(2*pi*F_lo*t);
lo_Q = sin(2*pi*F_lo*t);

%% 3. 混频 (时域相乘)
y_I = x .* lo_I;
y_Q = x .* lo_Q;

%% 4. 计算频谱 (FFT)
% 归一化 FFT
X_fft = fft(x, N)/N;
LO_I_fft = fft(lo_I, N)/N;
LO_Q_fft = fft(lo_Q, N)/N;
Y_I_fft = fft(y_I, N)/N;
Y_Q_fft = fft(y_Q, N)/N;

% 频率轴
f = (0:N-1)*(Fs/N);

% 只取正频率部分 (0 到 Fs/2)
half_N = floor(N/2) + 1;
f_plot = f(1:half_N);

% 提取幅度
X_mag = abs(X_fft(1:half_N));
LO_I_mag = abs(LO_I_fft(1:half_N));
LO_Q_mag = abs(LO_Q_fft(1:half_N));
Y_I_mag = abs(Y_I_fft(1:half_N));
Y_Q_mag = abs(Y_Q_fft(1:half_N));

% 设置绘图范围 (0 到 30MHz)
xlim_range = [0 30e6];

%% 5. 绘图展示 (原有的图)

% --- 图 1：输入信号频谱 ---
figure('Name', '输入信号频谱', 'Color', 'w');
plot(f_plot/1e6, X_mag, 'LineWidth', 4);
grid on;
title('输入信号频谱');
xlabel('频率 (MHz)');
ylabel('幅度');
xlim(xlim_range/1e6);

% --- 图 2：本振信号频谱 ---
figure('Name', '本振信号频谱', 'Color', 'w');
plot(f_plot/1e6, LO_I_mag, 'LineWidth', 4, 'DisplayName', 'I路 (Cos)');
hold on;
plot(f_plot/1e6, LO_Q_mag, '--', 'LineWidth', 4, 'DisplayName', 'Q路 (Sin)');
hold off;
grid on;
title('本振信号频谱');
xlabel('频率 (MHz)');
ylabel('幅度');
legend;
xlim(xlim_range/1e6);

% --- 图 3：混频后信号频谱 ---
figure('Name', '混频后信号频谱', 'Color', 'w');
plot(f_plot/1e6, Y_I_mag, 'LineWidth', 4, 'DisplayName', 'I路混频输出');
hold on;
plot(f_plot/1e6, Y_Q_mag, '--', 'LineWidth', 4, 'DisplayName', 'Q路混频输出');
hold off;
grid on;
title('混频后频谱 ');
xlabel('频率 (MHz)');
ylabel('幅度');
legend;
xlim(xlim_range/1e6);

%% 6. 滤除和频分量 (低通滤波) 并画图
% 设计低通滤波器
% 截止频率设为 5MHz (大于差频1MHz，小于和频21MHz)
fc = 5e6; 
[b, a] = butter(5, fc/(Fs/2), 'low'); 

% 对混频后的信号进行滤波
y_I_filtered = filter(b, a, y_I);
y_Q_filtered = filter(b, a, y_Q);

% 计算滤波后信号的频谱
Y_I_filt_fft = fft(y_I_filtered, N)/N;
Y_Q_filt_fft = fft(y_Q_filtered, N)/N;

Y_I_filt_mag = abs(Y_I_filt_fft(1:half_N));
Y_Q_filt_mag = abs(Y_Q_filt_fft(1:half_N));

% --- 图 4：滤除和频后的频谱 ---
figure('Name', '滤波后频谱 ', 'Color', 'w');
plot(f_plot/1e6, Y_I_filt_mag, 'LineWidth', 4, 'DisplayName', 'I路滤波后');
hold on;
plot(f_plot/1e6, Y_Q_filt_mag, '--', 'LineWidth', 4, 'DisplayName', 'Q路滤波后');
hold off;
grid on;
title('滤除和频后的频谱 ');
xlabel('频率 (MHz)');
ylabel('幅度');
legend;
xlim(xlim_range/1e6);

% 在图中标注
% text(1, max(Y_I_filt_mag)*0.8, '  1 MHz (差频)', 'VerticalAlignment', 'bottom', 'FontSize', 10, 'Color', 'b');
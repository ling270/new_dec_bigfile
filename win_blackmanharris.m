%% 1. 参数设置与信号生成
clc; clear; close all;

N = 8192;             % FFT 点数
Fs = 10000;           % 采样率 10kHz
T = 1/Fs;             % 采样间隔
t = (0:N-1)*T;        % 时间向量

% --- 构造测试信号 ---
% 使用非整数频率以模拟真实情况
f1 = 50;
f2 = 123.45; 
x = sin(2*pi*f1*t) + 0.5*sin(2*pi*f2*t);

%% 2. 生成 Blackman-Harris 窗并加窗
w = blackmanharris(N); 
x_windowed = x .* w'; % 加窗处理

%% 3. 计算频谱 (FFT)
X_raw = fft(x);
X_win = fft(x_windowed);

% 计算单边频谱幅度 (dB)
P2_raw = abs(X_raw/N);
P2_win = abs(X_win/N);

P1_raw = P2_raw(1:N/2+1);
P1_win = P2_win(1:N/2+1);

P1_raw(2:end-1) = 2*P1_raw(2:end-1);
P1_win(2:end-1) = 2*P1_win(2:end-1);

% 转换为 dB
P1_raw_db = 20*log10(P1_raw + eps);
P1_win_db = 20*log10(P1_win + eps);

f = Fs*(0:(N/2))/N;

%% 4. 全局字体设置 (Times New Roman, 24号)
% 设置所有后续图形的默认字体属性
set(0, 'DefaultAxesFontName', 'Times New Roman');
set(0, 'DefaultAxesFontSize', 24);
set(0, 'DefaultTextFontName', 'Times New Roman');
set(0, 'DefaultTextFontSize', 24);
set(0, 'DefaultLegendFontName', 'Times New Roman');
set(0, 'DefaultLegendFontSize', 24);
set(0, 'DefaultLineLineWidth', 1.5); % 稍微加粗线条以适应大图

%% 5. 绘图 A：总图 (包含三个子图)
figure('Name', 'Master Plot: All Views', 'Color', 'w', 'Position', [50, 50, 1200, 1000]);

% --- 子图 1: 宏观时域 ---
subplot(3, 1, 1);
plot(t, x, 'Color', [0.5 0.5 0.5]); hold on;
plot(t, x_windowed, 'b');
plot(t, 0.5*w', 'r--');
title('Time Domain Comparison (Macro View)');
xlabel('Time (s)'); ylabel('Amp');
legend('Original', 'Windowed', 'Window Ref', 'Location', 'NorthEast');
grid on; axis([0 0.8 -1.5 1.5]);

% --- 子图 2: 细节时域 ---
subplot(3, 1, 2);
plot(t, x_windowed, 'b');
title('Windowed Signal Detail (Spindle Shape)');
xlabel('Time (s)'); ylabel('Amp');
grid on; ylim([-1.5 1.5]);

% --- 子图 3: 频域 ---
subplot(3, 1, 3);
plot(f, P1_raw_db, 'Color', [0.5 0.5 0.5]); hold on;
plot(f, P1_win_db, 'b');
title('Frequency Spectrum Comparison');
xlabel('Freq (Hz)'); ylabel('Mag (dB)');
legend('Original', 'Windowed', 'Location', 'NorthEast');
grid on; axis([0 500 -120 20]);


%% 6. 绘图 B, C, D：三张独立的详细图
% 为了避免窗口重叠，稍微错开位置

% --- 独立图 1 ---
figure('Name', '1. Time Domain (Macro)', 'Color', 'w', 'Position', [100, 100, 1000, 400]);
plot(t, x, 'Color', [0.5 0.5 0.5]); hold on;
plot(t, x_windowed, 'b');
plot(t, 0.5*w', 'r--');
title('Time Domain Comparison (Macro View)');
xlabel('Time (s)'); ylabel('Amplitude');
legend('Original Signal', 'Windowed Signal', 'Window Contour', 'Location', 'NorthEast');
grid on; axis([0 0.8 -1.5 1.5]);

% --- 独立图 2 ---
figure('Name', '2. Time Domain (Detail)', 'Color', 'w', 'Position', [100, 550, 1000, 400]);
plot(t, x_windowed, 'b');
title('Windowed Signal Detail (Spindle Shape)');
xlabel('Time (s)'); ylabel('Amplitude');
grid on; ylim([-1.5 1.5]);

% --- 独立图 3 ---
figure('Name', '3. Frequency Domain', 'Color', 'w', 'Position', [100, 1000, 1000, 400]);
plot(f, P1_raw_db, 'Color', [0.5 0.5 0.5]); hold on;
plot(f, P1_win_db, 'b');
title('Frequency Spectrum Comparison (Blackman-Harris)');
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
legend('Original (Rectangular)', 'Windowed Signal', 'Location', 'NorthEast');
grid on; axis([0 500 -120 20]);
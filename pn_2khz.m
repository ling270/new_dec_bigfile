clc; clear; close all;

%% ===================== 1. 文件 =====================
file1 = "datasource4/phase_decimated/phi12_stage_3_2078Hz.dat";
file2 = "datasource4/phase_decimated/phi34_stage_3_2078Hz.dat";
% 采样率配置 (必须与 decimation 代码中的最终输出采样率一致)
FS = 133e6;        % 原始采样率
CIC_R = 64;        % CIC 抽取率
DecFactor = 10;    % FIR 抽取率
TotalStages = 3;   % 总级数

% 计算最终采样率: 133MHz / 64 / 10^4 ≈ 207.8 Hz
Fs_final = FS / CIC_R / (DecFactor^TotalStages); 

% 绘图与导出设置
plotTitle = 'Phase Noise Measurement (Stage 3)';
outFile = "phase_noise_result_stage3.dat";

%% ===================== 1. 读取数据 =====================
fprintf('正在读取数据...\n');
fid1 = fopen(file1, 'rb');
fid2 = fopen(file2, 'rb');

if fid1 == -1 || fid2 == -1
    error('无法打开文件，请检查文件路径是否正确。');
end

data1 = fread(fid1, 'double');
data2 = fread(fid2, 'double');

fclose(fid1);
fclose(fid2);

fprintf('读取完成。文件1长度: %d, 文件2长度: %d\n', length(data1), length(data2));

%% ===================== 2. 数据预处理 =====================
% 对齐长度
N = min(length(data1), length(data2));
data1 = data1(1:N);
data2 = data2(1:N);

% 去趋势 (Detrend) - 关键步骤：去除线性漂移，防止低频泄漏
data1 = detrend(data1);
data2 = detrend(data2);

% 归一化功率 (可选，视具体物理单位而定，这里假设数据已经是相位弧度)
% 如果数据单位是电压，需要转换为相位，这里假设已经是处理好的相位数据

%% ===================== 3. Welch 参数设置 =====================
% 频率分辨率 df = Fs / Nfft. 
% 为了看到低频 (如 0.1Hz)，Nfft 需要足够大，或者使用分段平均
nfft = 2^nextpow2(N); % 使用全部数据做高分辨率谱，或者限制最大点数
maxNfft = 2^14;       % 限制最大点数防止内存溢出或过度平滑
if nfft > maxNfft
    nfft = maxNfft;
end

win = hann(nfft, 'periodic');
noverlap = floor(nfft * 0.5); % 50% 重叠

fprintf('FFT点数: %d, 频率分辨率: %.4f Hz\n', nfft, Fs_final/nfft);

%% ===================== 4. 频谱计算 =====================
% 自功率谱密度 (Auto PSD)
[Pxx, f] = pwelch(data1, win, noverlap, nfft, Fs_final);
[Pyy, ~] = pwelch(data2, win, noverlap, nfft, Fs_final);

% 互功率谱密度 (Cross PSD)
% 注意：cpsd 返回复数，包含相位信息
[Pxy, ~] = cpsd(data1, data2, win, noverlap, nfft, Fs_final);

%% ===================== 5. 相位噪声计算 =====================
% 单边带相位噪声 L(f) 定义
% 对于自谱：L(f) ≈ S_phi(f) / 2 (如果数据是相位弧度) 或者直接 10*log10(PSD)
% 此处我们直接绘制 PSD 的 dB 值作为相对噪声水平

L_auto1 = 10*log10(Pxx + eps);
L_auto2 = 10*log10(Pyy + eps);

% 互谱法相位噪声
% 取实部是因为相位噪声主要关注同相分量，且取实部可以消除部分非相关虚部噪声
% 公式：L_cross = 10*log10( |Re{Pxy}| )
L_cross = 10*log10(abs(real(Pxy)) + eps);

%% ===================== 6. 绘图 =====================
figure('Color', 'w', 'Position', [100, 100, 800, 600]);

semilogx(f, L_auto1, 'b', 'LineWidth', 1, 'DisplayName', 'Auto CH1 (Raw)'); hold on;
semilogx(f, L_auto2, 'g', 'LineWidth', 1, 'DisplayName', 'Auto CH2 (Raw)');
semilogx(f, L_cross, 'r', 'LineWidth', 2, 'DisplayName', 'Cross Spectrum (Clean)');

grid on;
xlabel('Frequency (Hz)', 'FontSize', 12, 'FontName', 'Times New Roman');
ylabel('Phase Noise (dBc/Hz)', 'FontSize', 12, 'FontName', 'Times New Roman');
title(plotTitle, 'FontSize', 14, 'FontWeight', 'bold');

legend('Location', 'SouthWest');
set(gca, 'FontSize', 11, 'FontName', 'Times New Roman');
xlim([min(f) Fs_final/2]);

% 标注底噪差异
text(1, max(L_auto1)-5, sprintf('Raw Noise Floor: %.1f dBc/Hz', max(L_auto1)), 'Color', 'b');
text(1, max(L_cross)-5, sprintf('Cross Noise Floor: %.1f dBc/Hz', max(L_cross)), 'Color', 'r');

%% ===================== 7. 导出数据 =====================
fid = fopen(outFile, 'w');
fprintf(fid, '%% Phase Noise Result\n');
fprintf(fid, '%% Fs = %.4f Hz\n', Fs_final);
fprintf(fid, '%% Frequency(Hz)\tCross_PhaseNoise(dBc/Hz)\tAuto_CH1\tAuto_CH2\n');

for i = 1:length(f)
    fprintf(fid, '%.6e\t%.6f\t%.6f\t%.6f\n', f(i), L_cross(i), L_auto1(i), L_auto2(i));
end
fclose(fid);

fprintf('✅ 处理完成！结果已导出至: %s\n', outFile);
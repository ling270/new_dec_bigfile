clc; clear; close all;

%% ===================== 1. 参数配置 =====================
FS        = 133e6;      % 系统时钟
CIC_R     = 64;         % CIC抽取倍数
DecFactor = 10;         % FIR抽取倍数
TotalStages = 4;        % 级联级数

% 计算每一级的输入采样率
Fs_list = zeros(1, TotalStages);
Fs_list(1) = FS / CIC_R;
for k = 2:TotalStages
    Fs_list(k) = Fs_list(k-1) / DecFactor;
end

%% ===================== 2. 滤波器设计与绘图 =====================
Hd = cell(1, TotalStages);

% 设置全局默认字号
set(0, 'DefaultAxesFontSize', 24); 

fprintf('正在生成 %d 张滤波器频响图...\n', TotalStages);

for k = 1:TotalStages
    % --- 设计滤波器 ---
    [Hd{k}, ~] = design_decimator(Fs_list(k), DecFactor, k);
    
    % --- 获取当前采样率的合适单位 ---
    [unit_str, scale_factor] = get_engineering_unit(Fs_list(k));
    
    % --- 计算频响 ---
    [H, f] = freqz(Hd{k}.Numerator, 1, 8192, Fs_list(k));
    mag = 20*log10(abs(H) + 1e-12); % 防止log(0)
    
    % --- 独立绘图 ---
    figure('Color', 'w', ...
           'Name', sprintf('Stage %d Response', k), ...
           'Position', [100, 100, 1000, 600]);
           
    plot(f/scale_factor, mag, 'LineWidth', 2);
    grid on;
    box on;
    
    % --- 设置标签与标题 ---
    xlabel(['频率 (' unit_str ')'], 'FontSize', 24, 'Interpreter', 'none');
    ylabel('幅度 (dB)', 'FontSize', 24, 'Interpreter', 'none');
    title(['第 ' num2str(k) ' 级滤波器频响'], ...
          'FontSize', 24, 'Interpreter', 'none');
           
    % --- 设置坐标轴刻度字号 ---
    set(gca, 'FontSize', 24, 'LineWidth', 1.2);
    
    % ================= 修改部分：动态Y轴适应 =================
    % 1. 找到通带内的最大值（通常接近 0dB）
    max_val = max(mag);
    
    % 2. 找到阻带的最小值（或者设定一个下限，防止数值过小导致轴太长）
    min_val = min(mag);
    
    % 3. 策略：
    %    如果阻带衰减非常大（例如 < -120dB），强制将下限设为 -140dB 或 -150dB，
    %    这样可以让 0dB 的通带看起来更清晰，不会被拉得太扁。
    %    如果阻带衰减较小（例如 -60dB），则自动适应到底部。
    
    y_lower_limit = max(-140, min_val); % 至少留一点余量，或者固定到-140
    
    % 4. 应用Y轴范围
    %    上限设为最大值的 1.1 倍（留点头部空间），下限根据上面逻辑设定
    ylim([y_lower_limit, 10]);
    % =======================================================
end

%% ===================== 3. 滤波器设计函数 =====================
function [Hd, Fstop] = design_decimator(Fs, R, stage)
    Fstop = (Fs / R) / 2;
    Fpass = 0.65 * Fstop;

    Fn = Fs / 2;
    Wp = Fpass / Fn;
    Ws = Fstop / Fn;

    Astop = 120 - (stage-1)*20; 
    Astop = max(Astop, 60);

    d = designfilt('lowpassfir',...
        'PassbandFrequency', Wp,...
        'StopbandFrequency', Ws,...
        'PassbandRipple', 0.1,...
        'StopbandAttenuation', Astop);

    Hd = dsp.FIRDecimator(R, d.Coefficients);
end

%% ===================== 4. 自动单位判断函数 =====================
function [unit, factor] = get_engineering_unit(freq_val)
    if freq_val >= 1e6
        unit = 'MHz';
        factor = 1e6;
    elseif freq_val >= 1e3
        unit = 'kHz';
        factor = 1e3;
    else
        unit = 'Hz';
        factor = 1;
    end
end
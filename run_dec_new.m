clc; clear; close all;

%% ===================== 1. 参数（全部可调） =====================
filename = 'datasource4/phase_file/phi34.dat';

FS = 133e6;
CIC_R = 64;
Fs0 = FS / CIC_R;

DecFactor = 10;
TotalStages = 4;

skipPoints = 5000;          % ⭐ 可调：跳过前多少点
saveLastNStages = 4;        % ⭐ 可调：保存最后几级

chunkSize = 2e6;            % ⭐ 分块大小（控制内存）

plotSeconds = 3;            % ⭐ 前3秒显示

%% ===================== 2. 文件信息 =====================
fid = fopen(filename,'rb');
fseek(fid,0,'eof');
fileSize = ftell(fid);
totalSamples = fileSize / 8; % double
fseek(fid,0,'bof');

fprintf("总数据点: %.3e\n", totalSamples);

%% ===================== 3. 采样率 =====================
Fs_list = Fs0 ./ (DecFactor.^(0:TotalStages));

%% ===================== 4. 滤波器 =====================
Hd = cell(1, TotalStages);
for k = 1:TotalStages
    Hd{k} = design_decimator(Fs_list(k), DecFactor, k);
end

%% ===================== 5. 瞬态长度 =====================
TransientGuard = zeros(1, TotalStages);

for k = 1:TotalStages
    impulse = [1; zeros(5000,1)];
    y = Hd{k}(impulse);

    [~, peak] = max(abs(y));
    group_delay = peak - 1;

    threshold = max(abs(y))*1e-6;
    idx = find(abs(y)>threshold,1,'last');

    TransientGuard(k) = group_delay + idx;
end

%% ===================== 6. 输出文件 =====================
outDir = 'datasource4/phase_decimated';
if ~exist(outDir,'dir'), mkdir(outDir); end

startSaveStage = TotalStages - saveLastNStages + 1;

fid_out = cell(1, TotalStages);

for k = startSaveStage:TotalStages
    fname = fullfile(outDir,...
        sprintf('phi34_stage_%d_%.0fHz.dat', k, Fs_list(k+1)));

    fid_out{k} = fopen(fname,'wb');
end

%% ===================== 7. 初始化 =====================
buffer = [];
processed = 0;

tStart = tic;

% ⭐ 用于绘图抽样
plotData_all = cell(1, TotalStages);
plotData_short = cell(1, TotalStages);

%% ===================== 8. 主循环（流式处理） =====================
while ~feof(fid)

    data = fread(fid, chunkSize, 'double');
    if isempty(data), break; end

    % ===== 拼接缓冲区 =====
    x = [buffer; data];

    % ===== 跳过前 skipPoints =====
    if processed == 0
        if length(x) > skipPoints
            x = x(skipPoints+1:end);
        else
            buffer = x;
            continue;
        end
    end

    % ===== 多级降采样 =====
    for k = 1:TotalStages

        y = Hd{k}(x);

        guard = TransientGuard(k);

        if length(y) > guard
            y_valid = y(guard+1:end);
        else
            y_valid = [];
        end

        % ===== 保存 =====
        if k >= startSaveStage && ~isempty(y_valid)
            fwrite(fid_out{k}, y_valid, 'double');
        end

        % ===== 用于绘图（抽样）=====
        if ~isempty(y_valid)

            % ⭐ 全局抽样（避免爆内存）
            step = max(1, floor(length(y_valid)/10000));
            plotData_all{k} = [plotData_all{k}; y_valid(1:step:end)];

            % ⭐ 前3秒
            fs = Fs_list(k+1);
            maxN = round(plotSeconds * fs);

            if length(plotData_short{k}) < maxN
                need = maxN - length(plotData_short{k});
                plotData_short{k} = [plotData_short{k}; y_valid(1:min(need,end))];
            end

        end

        x = y_valid;
    end

    % ===== 更新buffer（保证连续）=====
    maxGuard = max(TransientGuard);
    if length(data) > maxGuard
        buffer = data(end-maxGuard:end);
    else
        buffer = data;
    end

    processed = processed + length(data);

    %% ===== 进度 + ETA =====
    progress = processed / totalSamples;
    elapsed = toc(tStart);
    eta = elapsed * (1/progress - 1);

    fprintf('进度: %.2f%% | ETA: %.1f s\r', progress*100, eta);

end

fprintf('\n处理完成\n');

fclose(fid);
for k = startSaveStage:TotalStages
    fclose(fid_out{k});
end

%% ===================== 9. 绘图（前3秒） =====================
figure('Color','w','Name','前3秒');

for k = startSaveStage:TotalStages
    subplot(saveLastNStages,1,k-startSaveStage+1);

    fs = Fs_list(k+1);
    y = plotData_short{k};

    t = (0:length(y)-1)/fs;

    plot(t,y);
    grid on;

    title(sprintf('Stage %d (%.0f Hz)',k,fs));
end

%% ===================== 10. 绘图（全局抽样） =====================
figure('Color','w','Name','全数据（抽样）');

for k = startSaveStage:TotalStages
    subplot(saveLastNStages,1,k-startSaveStage+1);

    plot(plotData_all{k});
    grid on;

    title(sprintf('Stage %d（抽样）',k));
end

%% ===================== 11. 滤波器频响 =====================
figure('Color','w','Name','滤波器频响');

for k = 1:TotalStages
    subplot(TotalStages,1,k);
    plot_filter_response(Hd{k}, Fs_list(k));
    title(sprintf('Stage %d Filter',k));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function Hd = design_decimator(Fs, R, stage)

    Fstop = (Fs / R) / 2;
    Fpass = 0.8 * Fstop;

    Fn = Fs / 2;
    Wp = Fpass / Fn;
    Ws = Fstop / Fn;

    Astop = 120 - (stage-1)*20;
    Astop = max(Astop, 60);

    Apass = 0.1;

    d = designfilt('lowpassfir', ...
        'PassbandFrequency', Wp, ...
        'StopbandFrequency', Ws, ...
        'PassbandRipple', Apass, ...
        'StopbandAttenuation', Astop);

    Hd = dsp.FIRDecimator( ...
        'DecimationFactor', R, ...
        'Numerator', d.Coefficients);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_filter_response(Hd, Fs)

    [H,f] = freqz(Hd.Numerator,1,4096,Fs);

    plot(f,20*log10(abs(H)),'LineWidth',1);
    grid on;
    ylim([-160 5]);

    xlabel('Frequency (Hz)');
    ylabel('Magnitude (dB)');
end
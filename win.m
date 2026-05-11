%% Part 1: Time Domain Comparison
clc; clear; close all;

% 1. Parameters
N = 256;                     % Window Length
t = (0:N-1)';               % Sample Index

% 2. Generate Windows
w_hamming = hamming(N);     % Hamming Window
w_bh = blackmanharris(N);   % Blackman-Harris Window

% 3. Plotting
figure('Name', 'Time Domain Comparison', 'Color', 'w', 'NumberTitle', 'off', 'Position', [100, 100, 800, 600]);
plot(t, w_hamming, 'b', 'LineWidth', 2); hold on;
plot(t, w_bh, 'r', 'LineWidth', 2);
grid on;

% 4. Formatting (English & Times New Roman)
title(['Time Domain Waveforms '], 'FontSize', 24, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
xlabel('Sample Index', 'FontSize', 24, 'FontName', 'Times New Roman');
ylabel('Amplitude', 'FontSize', 24, 'FontName', 'Times New Roman');

% Set Legend
lgd = legend('Hamming', 'Blackman-Harris', 'Location', 'NorthEast');
lgd.FontSize = 24;
lgd.FontName = 'Times New Roman';

% Set Axes Font
set(gca, 'FontSize', 24, 'FontName', 'Times New Roman');
axis tight;

%% Part 2: Frequency Domain Comparison
% Note: For high resolution frequency analysis, we usually use a larger N.
% If you want to keep N=64 from above, keep it. 
% If you want to analyze N=8192 as discussed previously, change N below.


% Regenerate windows for the new N
w_hamming = hamming(N);
w_bh = blackmanharris(N);

% 1. Compute Spectrum
NFFT = 4 * N;                     % Zero-padding for smooth curve
f = (0:NFFT/2)*(1/NFFT);          % Normalized Frequency (0 to 0.5)

% FFT Calculation
H_hamming = fft(w_hamming, NFFT);
H_bh = fft(w_bh, NFFT);

% Convert to dB
mag_hamming = 20*log10(abs(H_hamming(1:NFFT/2+1)));
mag_bh = 20*log10(abs(H_bh(1:NFFT/2+1)));

% Normalize to 0dB peak
mag_hamming = mag_hamming - max(mag_hamming);
mag_bh = mag_bh - max(mag_bh);

% 2. Plotting
figure('Name', 'Frequency Response Comparison', 'Color', 'w', 'NumberTitle', 'off', 'Position', [100, 100, 800, 600]);
plot(f, mag_hamming, 'b', 'LineWidth', 2); hold on;
plot(f, mag_bh, 'r', 'LineWidth', 2);
grid on;

% 3. Formatting (English & Times New Roman)
title(['Frequency Response '], 'FontSize', 24, 'FontName', 'Times New Roman', 'FontWeight', 'bold');
xlabel('Normalized Frequency (\times\pi rad/sample)', 'FontSize', 24, 'FontName', 'Times New Roman');
ylabel('Magnitude (dB)', 'FontSize', 24, 'FontName', 'Times New Roman');

% Set Legend
lgd = legend('Hamming', 'Blackman-Harris', 'Location', 'NorthEast');
lgd.FontSize = 24;
lgd.FontName = 'Times New Roman';

% Set Axes Font
set(gca, 'FontSize', 24, 'FontName', 'Times New Roman');

% 4. Axis Limits
ylim([-160 20]); % Show deep sidelobes
xlim([0 0.5]);   % From DC to Nyquist
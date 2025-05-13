clc; clear; close all;

%% **Step 1: Define SAR System Parameters**
Vr = 150;            % Sensor velocity (m/s)
fc = 1.2e9;          % SAR central frequency (Hz)
PRF = 1000;          % Pulse repetition frequency (Hz)
fs = 10e9;           % Range sampling frequency (Hz)
swst = 0;            % Sampling window start time (s)
ch_R = 2e12;         % Range chirp rate (Hz/s)
ch_T = 1e-6;         % Chirp duration (s)
num_pulses = 128;    % Number of azimuth pulses
num_samples = 512;   % Number of range samples

%% **Step 2: Generate Bandlimited White Gaussian Noise (WGN)**
T = 1e-6;                % Pulse width (1 µs)
B = 1 / T;               % Bandwidth
time_duration = 5 * T;   % Total simulation time
t = 0:1/fs:time_duration - 1/fs;  % Time vector

% Generate White Gaussian Noise
wgn_signal = randn(size(t));  

% Apply a Bandpass Filter to limit noise bandwidth
bpFilt = designfilt('bandpassfir', ...
    'FilterOrder', 100, ...
    'CutoffFrequency1', fc - B/2, ...
    'CutoffFrequency2', fc + B/2, ...
    'SampleRate', fs);
bandlimited_wgn = filter(bpFilt, wgn_signal);

% Normalize the signal to match the energy of the previous signals
bandlimited_wgn = bandlimited_wgn / max(abs(bandlimited_wgn));

%% **Step 3: Simulate SAR Raw Data with Noisy Reflections**
raw = zeros(num_pulses, num_samples);
for i = 1:num_pulses
    delay = 2 * sqrt((i - num_pulses/2)^2 + 50^2) / 3e8;  % Distance to target
    delayed_signal = circshift(bandlimited_wgn, round(delay * fs)); % Apply time shift
    raw(i, 1:length(delayed_signal)) = delayed_signal; % Store noisy signal in raw matrix
end

%% **Step 4: Process SAR Data Using SAR_focus Function**
slc = SAR_focus(raw, Vr, fc, PRF, fs, swst, ch_R, ch_T);

%% **Step 5: Display SAR Image**
figure;
imagesc(abs(slc));
colormap('gray');
title('SAR Image (Focused) - Bandlimited WGN');
xlabel('Range Samples');
ylabel('Azimuth Samples');
colorbar;

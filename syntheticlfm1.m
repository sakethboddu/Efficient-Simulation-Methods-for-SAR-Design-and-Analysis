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

%% **Step 2: Generate LFM Chirp Signal**
T = 1e-6;                % Pulse width (1 µs)
B = 1 / T;               % Bandwidth
time_duration = 5 * T;   % Total simulation time
t = 0:1/fs:time_duration - 1/fs;  % Time vector

% Generate LFM Chirp Signal
lfm_chirp = chirp(t, fc - B/2, time_duration, fc + B/2, 'linear');

% Normalize the signal
lfm_chirp = lfm_chirp / max(abs(lfm_chirp));

%% **Step 3: Simulate SAR Raw Data with LFM Chirp Reflections**
raw = zeros(num_pulses, num_samples);
for i = 1:num_pulses
    delay = 2 * sqrt((i - num_pulses/2)^2 + 50^2) / 3e8;  % Distance to target
    delayed_signal = circshift(lfm_chirp, round(delay * fs)); % Apply time shift
    raw(i, 1:length(delayed_signal)) = delayed_signal; % Store chirp signal in raw matrix
end

%% **Step 4: Process SAR Data Using SAR_focus Function**
slc = SAR_focus(raw, Vr, fc, PRF, fs, swst, ch_R, ch_T);

%% **Step 5: Display SAR Image**
figure;
imagesc(abs(slc));
colormap('gray');
title('SAR Image (Focused) - LFM Chirp');
xlabel('Range Samples');
ylabel('Azimuth Samples');
colorbar;

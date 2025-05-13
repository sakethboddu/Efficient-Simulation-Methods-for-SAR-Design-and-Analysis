% Fixed SAR Parameters
sar_params.x = 100;     % x-coordinate of target (m)
sar_params.y = 50;      % y-coordinate of target (m)
sar_params.z = 0;       % z-coordinate of target (m)

% Parameters
fs = 10e9;               % Sampling frequency (10 GHz for accurate representation)
fc = 1.2e9;              % Center frequency (1.2 GHz)
B = 200e6;               % Bandwidth of the chirp (200 MHz)
T = 1e-6;                % Duration of the chirp (1 microsecond)
time_duration = T;       % Total time duration for simulation

% Time vector
t = 0:1/fs:time_duration - 1/fs;

% Generate LFM chirp signal
f_start = fc - B/2;      % Start frequency of the chirp
f_end = fc + B/2;        % End frequency of the chirp
k = B / T;               % Chirp rate (slope)
lfm_chirp = cos(2*pi*(f_start*t + 0.5*k*t.^2));  % LFM chirp signal

% Simulate reflection from SAR target
distance = sqrt(sar_params.x^2 + sar_params.y^2 + sar_params.z^2);
delay_samples = round((2 * distance / 3e8) * fs); % Delay in samples due to reflection
reflected_signal = [zeros(1, delay_samples), lfm_chirp(1:end-delay_samples)]; % Apply delay

% Add noise to the received signal
noise = randn(size(reflected_signal)) * 0.05; % Gaussian noise
received_signal = reflected_signal + noise;

% Apply bandpass filtering to remove noise
bpFilt = designfilt('bandpassfir', ...
    'FilterOrder', 100, ...
    'CutoffFrequency1', fc - B/2, ...
    'CutoffFrequency2', fc + B/2, ...
    'SampleRate', fs);
filtered_signal = filter(bpFilt, received_signal);

% Compute the spectrum of the filtered signal
nfft = 2^nextpow2(length(filtered_signal));  % Next power of 2 for efficient FFT
freq = fs * (0:nfft/2-1) / nfft;            % Positive frequency vector
spectrum = abs(fft(filtered_signal, nfft)) / length(filtered_signal);  % Normalize
spectrum = spectrum(1:nfft/2);              % Retain only the positive frequencies

% Plot the time-domain signal
figure;
subplot(3,1,1);
plot(t*1e6, lfm_chirp);
xlabel('Time (\mus)');
ylabel('Amplitude');
title('LFM Chirp Signal (Time Domain)');
grid on;

% Plot the received noisy signal
subplot(3,1,2);
plot(t*1e6, received_signal(1:length(t))); % Match time vector length for display
xlabel('Time (\mus)');
ylabel('Amplitude');
title('Received Signal with Noise');
grid on;

% Plot the positive frequency spectrum
figure;
plot(freq/1e9, spectrum);
xlabel('Frequency (GHz)');
ylabel('Magnitude');
title('Spectrum of LFM chirp Signal');
grid on;
realPart = real(spectrum);        % Real part of the signal
imagPart = imag(spectrum);        % Imaginary part of the signal
csvData = [realPart', imagPart'];  % Combine real and imaginary parts

csvwrite('C:\Users\DEAN_ACADEMIC-PC\Documents\My Workspaces\CXA LFM chirp.csv', csvData); 
disp('LFM waveform saved as CXA LFM chirp.csv');

% Step 9: Convert CSV to ARB Format
% ARB format is essentially a binary file where each sample is represented in float32 format.
% We will read the CSV and save the data in ARB format (binary).

% Read the CSV file
csvDataRead = csvread('C:\Users\DEAN_ACADEMIC-PC\Documents\My Workspaces\CXA LFM chirp.csv'); 

% Create a binary file to store the ARB data
arbFilePath = 'C:\Users\DEAN_ACADEMIC-PC\Documents\My Workspaces\CXA LFM chirp.arb';
fid = fopen(arbFilePath, 'wb');  % Open file in write-binary mode

% Write the real and imaginary parts as float32
fwrite(fid, csvDataRead, 'float32'); 
fclose(fid);
disp(['ARB file saved at: ', 'ftp://192.168.0.2/USER/WAVEFORM/CXA LFM chirp.arb']);

% Step 10: VSG Integration using ARB functions
% Use the same VSG address as in Program 2
vsg = visa('Agilent','USB0::0x0957::0x1F01::MY57280515::0::INSTR');  % Example VISA address
fopen(vsg);

% Set VSG Parameters
fprintf(vsg, 'FREQ 50e6');  % Set output frequency (1 MHz)
fprintf(vsg, 'POW -10');   % Set output power (example: -10 dBm)

% Load the ARB file into the VSG's arbitrary waveform memory
fprintf(vsg, ['ARBITRARY:FUNCTION:LOAD:INTERNAL', char("ftp://192.168.0.2/USER/WAVEFORM/CXA LFM chirp.arb")]);  % Command for loading ARB file into memory

% Set the VSG to generate the arbitrary waveform
fprintf(vsg, ['ARBITRARY:FUNCTION', char("ftp://192.168.0.2/USER/WAVEFORM/CXA LFM chirp.arb")]);  % Select the ARB waveform for output

% Enable the RF output to send the signal
fprintf(vsg, 'OUTP ON');    % Turn on RF output

% Step 11: VSA Integration (Optional)
% Capture and analyze the waveform using the VSA.
% Example: Load captured data and perform FFT analysis in the VSA software.

% Close VSG connection
fclose(vsg);
delete(vsg);
clear vsg;
disp('Waveform loaded and RF output enabled.');
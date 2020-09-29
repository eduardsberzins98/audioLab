% Code for a FIR Comb filter (single echo audio effect)

% Edinburgh University Electronics & Electrical Engineering Society
% October 2020

clc;
clear all;

% Set up audio I/O
deviceReader = audioDeviceReader; % Audio input object
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate); % Send output to your mic
%deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate,'Device','CABLE Input (VB-Audio Virtual Cable)'); % Send output to virtual cable
fileWriter = dsp.AudioFileWriter('testAudio.wav','SampleRate',deviceReader.SampleRate); % Save resulting audio to .wav

% Fetch relevant I/O parameters
sampleRate = deviceReader.SampleRate; % Hz
frameSize = deviceReader.SamplesPerFrame; % In samples

% Set up DSP algorithm
delaySeconds = 120E-3; % Desired echo delay in seconds (>100ms)
gain = 0.7; % Gain for echo (< 1)

% Set up circular buffer
R = round(sampleRate*delaySeconds); % Delay in samples aka buffer size
circBuffer = zeros(1,R+1); % Circular buffer
newest = 0; % Buffer index for newest incoming audio sample
oldest = 0; % Buffer index for oldest saved audio sample in buffer
frameOut = zeros(1,frameSize); % Output audio frame

% Run realtime effect
disp('Start speaking')
tic
while toc < 20 % How long to run the code
    frameIn = deviceReader(); % Fetch input audio frame
    
    for n = 1:frameSize
        newest = oldest;
        oldest = oldest + 1; % Oldest idx is one infront of the newest index
        oldest = mod(oldest,R+1); % Circular buffer 
        circBuffer(newest+1) = frameIn(n); % Load in newst sample
        frameOut(n)= frameIn(n) + gain*circBuffer(oldest+1); % Effect + FIFO
    end
    
    deviceWriter(frameOut'); % Output audio frame
    fileWriter(frameOut'); % Also save to .wav file
end
disp('Stop speaking')

% Release audio I/O objects
release(deviceReader)
release(deviceWriter)
release(fileWriter)
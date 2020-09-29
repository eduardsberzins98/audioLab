% This code implements 2 effects at the same time IIR flange and IIR echo.

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

% Set up circular buffer
maxDelaySeconds = 5E-3; % Desired echo delay in seconds (1 to 10ms)
R = round(sampleRate*maxDelaySeconds); % Delay in samples aka buffer size
circBuffer=zeros(1,R+1); % Circular buffer
newest = 0; % Buffer index for newest incoming audio sample
oldest = 0; % Buffer index for oldest saved audio sample in buffer
frameOut = zeros(1,frameSize); % Output audio frame

% Set up Flanger
gain = 0.8; % Gain for echo
f0 = 0.7; % Flange frequency in Hz (around 1 Hz)
beta = @(n) round((R/2)*(1 - cos(2*pi*(f0/sampleRate).*n))); %LFO variable delay function
idxLFO = 0; % Index for LFO

% Set up IIR echo
delaySecondsEcho = 100E-3; % Desired echo delay in seconds (>100ms)
gainEcho = 0.6; % Gain for echo (< 1)
REcho = round(sampleRate*delaySecondsEcho); % Delay in samples aka buffer size
circBufferEcho=zeros(1,REcho+1); % Circular buffer
newestEcho = 0; % Buffer index for newest incoming audio sample
oldestEcho = 0; % Buffer index for oldest saved audio sample in buffer

% Run realtime effect
disp('Start speaking')
tic
while toc < 20 % How long to run the code
    frameIn = deviceReader();  % Fetch input audio frame
    
    for n = 1:frameSize
        % Add flange
        idxLFO = idxLFO + 1; % Keep track of total sample count for LFO
        newest=oldest;
        oldest=oldest + 1; % Oldest idx is one infront of the newest
        oldest=mod(oldest,R+1);  % Circular buffer 
        circBuffer(newest+1)= frameIn(n) + gain*circBuffer(mod(newest - beta(idxLFO),R+1)+1); % Load in newst sample + effect
        intermediate = circBuffer(oldest+1);
        
        % Add echo
        newestEcho=oldestEcho;
        oldestEcho=oldestEcho + 1; % Oldest idx is one infront of the newest
        oldestEcho=mod(oldestEcho,REcho+1);  % Circular buffer 
        circBufferEcho(newestEcho+1)=intermediate + gainEcho*circBufferEcho(oldestEcho+1); % Load in newst sample + effect
        frameOut(n)= circBufferEcho(oldestEcho+1); % FIFO
    end
    
    deviceWriter(frameOut'); % Output audio frame
    fileWriter(frameOut'); % Also save to .wav file
end
disp('Stop speaking')

% Release audio I/O objects
release(deviceReader)
release(deviceWriter)
release(fileWriter)
% Code for a tremelo effect

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
alpha = 0.7; % Tremelo depth (from 0 to 1)
f0 = 5; % LFO frequency (around below 20 Hz)
beta = @(n) (1/2)*(1 - cos(2*pi*(f0/sampleRate).*n)); % Tremelo modulation
idxLFO = 0; % Index for LFO

frameOut = zeros(1,frameSize); % Output audio frame

% Run realtime effect
disp('Start speaking')
tic
while toc < 20 % How long to run the code
    frameIn = deviceReader(); % Fetch input audio frame
    
    for n = 1:frameSize
        idxLFO = idxLFO + 1; % Keep track of total sample count for LFO
        frameOut(n) = (1-alpha)*frameIn(n) + alpha*beta(idxLFO)*frameIn(n);
    end
    
    deviceWriter(frameOut'); % Output audio frame
    fileWriter(frameOut'); % Also save to .wav file
end
disp('Stop speaking')

% Release audio I/O objects
release(deviceReader)
release(deviceWriter)
release(fileWriter)
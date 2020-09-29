% Code for a IIR Chorus effect

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

% IIR #1
dSec1 = 20E-3; % Desired echo delay in seconds (20 to 30ms)
G1 = 0.75; % Gain for echo (< 1)
R1 = round(sampleRate*dSec1); % Delay in samples aka buffer size
circBuffer1 = zeros(1,R1+1); % Circular buffer
new1 = 0; % Buffer index for newest incoming audio sample
old1 = 0; % Buffer index for oldest saved audio sample in buffer
f01 = 1.1;
beta1 = @(n) round((R1/2)*(1 - cos(2*pi*(f01/sampleRate).*n))); %LFO variable delay function

% IIR #2
dSec2 = 25E-3; % Desired echo delay in seconds (20 to 30ms)
G2 = 0.8; % Gain for echo (< 1)
R2 = round(sampleRate*dSec2); % Delay in samples aka buffer size
circBuffer2 = zeros(1,R2+1); % Circular buffer
new2 = 0; % Buffer index for newest incoming audio sample
old2 = 0; % Buffer index for oldest saved audio sample in buffer
f02 = 0.5;
beta2 = @(n) round((R2/2)*(1 - cos(2*pi*(f02/sampleRate).*n))); %LFO variable delay function

% IIR #3
dSec3 = 30E-3; % Desired echo delay in seconds (20 to 30ms)
G3 = 0.7; % Gain for echo (< 1)
R3 = round(sampleRate*dSec3); % Delay in samples aka buffer size
circBuffer3 = zeros(1,R3+1); % Circular buffer
new3 = 0; % Buffer index for newest incoming audio sample
old3 = 0; % Buffer index for oldest saved audio sample in buffer
f03 = 0.7;
beta3 = @(n) round((R3/2)*(1 - cos(2*pi*(f03/sampleRate).*n))); %LFO variable delay function

idxLFO = 0; % Index for LFO
frameOut = zeros(1,frameSize); % Output audio frame

% Run realtime effect
disp('Start speaking')
tic
while toc < 20 % How long to run the code
    frameIn = deviceReader(); % Fetch input audio frame
    
    for n = 1:frameSize
        idxLFO = idxLFO + 1; % Keep track of total sample count for LFO
        new1 = old1; new2 = old2; new3 = old3;
        old1 = old1 + 1; old2 = old2 + 1; old3 = old3 + 1;
        old1 = mod(old1,R1+1); old2 = mod(old2,R2+1); old3 = mod(old3,R3+1);
        circBuffer1(new1+1) = frameIn(n) + G1*circBuffer1(mod(new1 - beta1(idxLFO),R1+1)+1); 
        circBuffer2(new2+1) = frameIn(n) + G2*circBuffer2(mod(new2 - beta2(idxLFO),R2+1)+1); 
        circBuffer3(new3+1) = frameIn(n) + G3*circBuffer3(mod(new3 - beta3(idxLFO),R3+1)+1);
        
        frameOut(n)= circBuffer1(old1+1) + circBuffer2(old2+1) + circBuffer3(old3+1); % FIFO
    end
    
    deviceWriter(frameOut'); % Output audio frame
    fileWriter(frameOut'); % Also save to .wav file
end
disp('Stop speaking')

% Release audio I/O objects
release(deviceReader)
release(deviceWriter)
release(fileWriter)
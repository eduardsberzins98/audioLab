% Code for a reverb
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

% IIR Comb 1
dS1 = 15E-3; % Desired echo delay in seconds (>100ms)
g1 = 0.7; % Gain for echo (< 1)
R1 = round(sampleRate*dS1); % Delay in samples aka buffer size
cB1=zeros(1,R1+1); % Circular buffer
n1 = 0; % Buffer index for newest incoming audio sample
o1 = 0; % Buffer index for oldest saved audio sample in buffer

% IIR Comb 2
dS2 = 19E-3; % Desired echo delay in seconds (>100ms)
g2 = 0.8; % Gain for echo (< 1)
R2 = round(sampleRate*dS2); % Delay in samples aka buffer size
cB2=zeros(1,R2+1); % Circular buffer
n2 = 0; % Buffer index for newest incoming audio sample
o2 = 0; % Buffer index for oldest saved audio sample in buffer

% IIR Comb 3
dS3 = 20E-3; % Desired echo delay in seconds (>100ms)
g3 = 0.75; % Gain for echo (< 1)
R3 = round(sampleRate*dS3); % Delay in samples aka buffer size
cB3=zeros(1,R3+1); % Circular buffer
n3 = 0; % Buffer index for newest incoming audio sample
o3 = 0; % Buffer index for oldest saved audio sample in buffer

% IIR Comb 4
dS4 = 17E-3; % Desired echo delay in seconds (>100ms)
g4 = 0.8; % Gain for echo (< 1)
R4 = round(sampleRate*dS4); % Delay in samples aka buffer size
cB4=zeros(1,R4+1); % Circular buffer
n4 = 0; % Buffer index for newest incoming audio sample
o4 = 0; % Buffer index for oldest saved audio sample in buffer

% Allpass 5
dS5 = 20E-3; % Desired echo delay in seconds (>100ms)
g5 = 0.67; % Gain for echo (< 1)
R5 = round(sampleRate*dS5); % Delay in samples aka buffer size
cB5=zeros(1,R5+1); % Circular buffer
n5 = 0; % Buffer index for newest incoming audio sample
o5 = 0; % Buffer index for oldest saved audio sample in buffer

% Allpass 6
dS6 = 16E-3; % Desired echo delay in seconds (>100ms)
g6 = 0.78; % Gain for echo (< 1)
R6 = round(sampleRate*dS6); % Delay in samples aka buffer size
cB6=zeros(1,R6+1); % Circular buffer
n6 = 0; % Buffer index for newest incoming audio sample
o6 = 0; % Buffer index for oldest saved audio sample in buffer

g7 = 0.9;


frameOut = zeros(1,frameSize); % Output audio frame

% Run realtime effect
disp('Start speaking')
tic
while toc < 20 % How long to run the code
    frameIn = deviceReader(); % Fetch input audio frame
    
    for n = 1:frameSize
        
        % IIR Comb in parallel
        n1=o1; n2=o2; n3=o3; n4=o4;
        o1=o1 + 1; o2=o2 + 1; o3=o3 + 1; o4=o4 + 1;
        o1=mod(o1,R1+1); o2=mod(o2,R2+1); o3=mod(o3,R3+1); o4=mod(o4,R4+1);
        cB1(n1+1)=frameIn(n) + g1*cB1(o1+1);
        cB2(n2+1)=frameIn(n) + g2*cB2(o2+1);
        cB3(n3+1)=frameIn(n) + g3*cB3(o3+1);
        cB4(n4+1)=frameIn(n) + g4*cB4(o4+1);        
        interSample1 = cB1(o1+1) + cB2(o2+1) + cB3(o3+1) + cB4(o4+1);
        
        % First allpass
        n5=o5;
        o5=o5 + 1; 
        o5=mod(o5,R5+1);
        cB5(n5+1)= interSample1 - g5*(cB5(o5+1) + interSample1);     
        interSample2 = cB5(o5+1) + g5*(cB5(o5+1) + interSample1);
        
        % Second allpass
        n6=o6;
        o6=o6 + 1; 
        o6=mod(o6,R6+1);
        cB6(n6+1)= interSample2 - g6*(cB6(o6+1) + interSample2);     
        interSample3 = cB6(o6+1) + g6*(cB6(o6+1) + interSample2);
        
        % Combine with input
        frameOut(n) = interSample3*g7 + frameIn(n);
    end
    
    deviceWriter(frameOut'); % Output audio frame
    fileWriter(frameOut'); % Also save to .wav file
end
disp('Stop speaking')

% Release audio I/O objects
release(deviceReader)
release(deviceWriter)
release(fileWriter)
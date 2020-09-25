% This is an example on how to perform realtime audio processing. In this
% particular case an echo is added, speak into your mic to hear the effect
% when prompted.

clc;

% Set up audio I/O
deviceReader = audioDeviceReader;
deviceWriter = audioDeviceWriter('SampleRate',deviceReader.SampleRate);

% Set up audio buffer for continuous filtering
bufferSize = 5; 
sampleRate = deviceReader.SampleRate;
frameSize = deviceReader.SamplesPerFrame;
FIFO = zeros(bufferSize*frameSize,1);

% Set up scope
scope = dsp.SpectrumAnalyzer('ViewType', "Spectrogram",...
                            'SampleRate', sampleRate);
    
% Run realtime effect
disp('Start speaking (scope may take some time to load)')
tic
while toc<50
    frameIn = deviceReader(); % Fetch audio frame
    
    frameOut = FIFO(end-frameSize+1:end);% Fetch last frame out
    FIFO = [zeros(frameSize,1);FIFO(1:end-frameSize)];% Shift buffer
    FIFO(1:frameSize) = frameIn; % Load newest
    
    FIFO(1:frameSize) = FIFO(1:frameSize) + 0.6*frameOut; % Add echo
    
    deviceWriter(frameOut); % Output audio frame
    
    scope(frameOut)
end
disp('Stop speaking')

% Release audio I/O objects
release(deviceReader)
release(deviceWriter)

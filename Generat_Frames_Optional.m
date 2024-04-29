% 清除环境并关闭所有窗口
clear;
close all
clc;

% 定义调制类型 
modulationTypes = categorical(sort(["BPSK", "QPSK", "8PSK", ...
  "16QAM", "64QAM", "PAM4", "GFSK", "CPFSK", ...
  "B-FM", "DSB-AM", "SSB-AM"]));

%% 设置控制变量
runChannelInterference = true; % 设置为 true 以运行通道干扰
runClockOffset = true; % 设置为 true 以运行时钟偏移
runFrequencyOffset = true; % 设置为 true 以运行频率偏移
runSampleRateOffset = true; % 设置为 true 以运行采样率偏移
SNR = 18;%设置信噪比
%% 生成用于训练的波形
numFramesPerModType = 10000;
percentTrainingSamples = 80;   %训练百分比
percentValidationSamples = 10; %验证百分比
percentTestSamples = 10;       %测试百分比
sps = 8;                     % 每个符号样本数
spf = 1024;                 %仿真时隙
symbolsPerFrame = spf / sps;
fs = 200e3;                    %采样率
fc = [900e3 100e3];            % 中心频率
% RRADAR 波形的起始百分
rangeFc = [fs/7, fs/5]; % Center frequency (Hz) range

%% 创建通道干扰
std = sqrt(10.^(SNR/10));

awgnChannel = comm.AWGNChannel(...
    'NoiseMethod', 'Signal to noise ratio (SNR)', ...
    'SignalPower', 0.5, ...
    'SNR', SNR);

multipathChannel = comm.RicianChannel(...
    'SampleRate', fs, ...
    'PathDelays', [0 1.8 3.4]/fs, ...
    'AveragePathGains', [0 -2 -10]./2, ...
    'KFactor', 2, ...
    'MaximumDopplerShift', 2);

%% Clock Offset
maxDeltaOff = 2;%5
deltaOff = (rand()*2*maxDeltaOff) - maxDeltaOff;
C = 1 + (deltaOff/1e6);

%% 频率偏移
offset = -(C-1)*fc(1);
frequencyShifter = comm.PhaseFrequencyOffset(...
    'SampleRate', fs, ...
    'FrequencyOffset', offset);

%% 采样率偏移
channel = ModClassTestChannel(...
    'SampleRate', fs, ...
    'SNR', SNR, ...
    'PathDelays', [0 1.8 3.4] / fs, ...
    'AveragePathGains', [0 -2 -10]./2, ...
    'KFactor', 2, ...
    'MaximumDopplerShift', 2, ...
    'MaximumClockOffset', 2, ...
    'CenterFrequency', 900e3);

chInfo = info(channel);

%% 波形生成
rng(12375)
tic

numModulationTypes = length(modulationTypes);

channelInfo = info(channel);
frameStore = ModClassFrameStore(...
    numFramesPerModType*numModulationTypes,spf,modulationTypes);
transDelay = 20;

for modType = 1:numModulationTypes
    fprintf('%s - 正在生成 %s \n', ...
        datestr(toc/86400,'HH:MM:SS'), modulationTypes(modType))
    numSymbols = (numFramesPerModType / sps);
    dataSrc = getSource(modulationTypes(modType), sps, 2*spf, fs);
    modulator = ModClassGetModulator(modulationTypes(modType), sps, fs);
    
    if contains(char(modulationTypes(modType)), {'B-FM','DSB-AM','SSB-AM'})
        channel.CenterFrequency = 100e3;
    else
        channel.CenterFrequency = 900e3;
    end

    for p=1:numFramesPerModType
        x = dataSrc();
        y = modulator(x);
        
        % 添加通道干扰
        if runChannelInterference
            rxSamples = multipathChannel(y); % 多径衰落通道
            rxSamples = awgnChannel(rxSamples); % AWGN 通道
        else
            rxSamples = y; % 不添加通道干扰
        end
        
        % 添加时钟偏移
        if runClockOffset
            deltaOff = (rand()*2*maxDeltaOff) - maxDeltaOff;
            C = 1 + (deltaOff/1e6);
        else
            C = 1; % 不添加时钟偏移
        end
        
        % 添加频率偏移
        if runFrequencyOffset
            offset = -(C-1)*fc(1);
            rxSamples = frequencyShifter(rxSamples); % 频率偏移
        end
        
        % 添加采样率偏移
        if runSampleRateOffset
            channel.SampleRate = fs * C; % 采样率偏移
        end
        
        frame = ModClassFrameGenerator(rxSamples, spf, spf, transDelay, sps);
        add(frameStore, frame, modulationTypes(modType)); % 添加到框架存储
    end
end

%% 数据划分
[mcfsTraining,mcfsValidation,mcfsTest] = splitData(frameStore,...
[percentTrainingSamples,percentValidationSamples,percentTestSamples]);

mcfsTraining.OutputFormat = "IQAsPages";
[rxTraining,rxTrainingLabel] = get(mcfsTraining);

mcfsValidation.OutputFormat = "IQAsPages";
[rxValidation,rxValidationLabel] = get(mcfsValidation);

mcfsTest.OutputFormat = "IQAsPages";
[rxTest,rxTestLabel] = get(mcfsTest);

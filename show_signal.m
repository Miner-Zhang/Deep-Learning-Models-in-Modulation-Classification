% 清除环境并关闭所有窗口
clear;
close all
clc;

% 定义调制类型 
modulationTypes = categorical(sort(["BPSK", "QPSK", "8PSK", ...
  "16QAM", "64QAM", "PAM4", "GFSK", "CPFSK", ...
  "B-FM", "DSB-AM", "SSB-AM"]));

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
% 每帧通过一个通道，AWGN，Rician 多径衰落，
% 时钟偏移，导致中心频率偏移和采样时间漂移
SNR = 30;
std = sqrt(10.^(SNR/10));

awgnChannel = comm.AWGNChannel(...
    'NoiseMethod', 'Signal to noise ratio (SNR)', ...
    'SignalPower', 0.5, ...
    'SNR', SNR);

%% Rician平坦衰落信道
% 通道使用
% 通信。RicianChannel System 对象。假设 [0 1.8 3.4] 个样本的延迟曲线
% 对应的平均路径增益为 [0 -2 -10] dB。K 因子为 4，最大值为
% 多普勒频移为 2 Hz
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
% 使每个帧具有基于时钟偏移因子 C 和中心的频率偏移
% 频率
offset = -(C-1)*fc(1);
frequencyShifter = comm.PhaseFrequencyOffset(...
    'SampleRate', fs, ...
    'FrequencyOffset', offset);


%% 采样率偏移
%使每个帧受到基于时钟偏移因子 C 的采样率偏移
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
% 将随机数生成器设置为已知状态以便能够重新生成
% 每次运行模拟时相同帧数的百分比
rng(20010611)
tic

numModulationTypes = length(modulationTypes);

channelInfo = info(channel);
frameStore = ModClassFrameStore(...
    numFramesPerModType*numModulationTypes,spf,modulationTypes);
transDelay = 20;

% 创建用于绘制波形的图形
figure('Name', '各种信号的时域波形');
for modType = 1:numModulationTypes
    fprintf('%s - 正在生成 %s 的时域波形\n', ...
        datestr(toc/86400,'HH:MM:SS'), modulationTypes(modType))
    
    subplot(6, 2, modType);
    hold on;
    title(char(modulationTypes(modType)),'FontSize',32);
    xlabel('样本','FontSize',24);
    ylabel('幅度','FontSize',24);
    grid on;
    set(gca,'FontSize',9);

    numSymbols = (numFramesPerModType / sps);
    dataSrc = getSource(modulationTypes(modType), sps, 2*spf, fs);
    modulator = ModClassGetModulator(modulationTypes(modType), sps, fs);
    if contains(char(modulationTypes(modType)), {'B-FM','DSB-AM','SSB-AM'})
        % Analog modulation types use a center frequency of 100 MHz
        channel.CenterFrequency = 100e3;
    else
        % Digital modulation types use a center frequency of 900 MHz
        channel.CenterFrequency = 900e3;
    end

    % 生成随机数据
    x = dataSrc();

    % 调制
    y = modulator(x);

    % 通过通道传输并接收信号
    rxSamples = channel(y);

    % 处理接收到的信号，删除瞬态等
    frame = ModClassFrameGenerator(rxSamples, spf, spf, transDelay, sps);

    % 绘制时域波形
    plot(1:length(frame), frame);
end

% 创建用于绘制频谱图的图形
figure('Name', '各种信号的频谱图');
for modType = 1:numModulationTypes
    fprintf('%s - 正在生成 %s 的频谱图\n', ...
        datestr(toc/86400,'HH:MM:SS'), modulationTypes(modType))
    
    subplot(6, 2, modType);
    hold on;
    title(char(modulationTypes(modType)),'FontSize',32);
    xlabel('频率 (Hz)','FontSize',24);
    ylabel('功率谱密度 (dB)','FontSize',24);
    grid on;
    set(gca,'FontSize',9);

    numSymbols = (numFramesPerModType / sps);
    dataSrc = getSource(modulationTypes(modType), sps, 2*spf, fs);
    modulator = ModClassGetModulator(modulationTypes(modType), sps, fs);
    if contains(char(modulationTypes(modType)), {'B-FM','DSB-AM','SSB-AM'})
        % Analog modulation types use a center frequency of 100 MHz
        channel.CenterFrequency = 100e3;
    else
        % Digital modulation types use a center frequency of 900 MHz
        channel.CenterFrequency = 900e3;
    end

    % 生成随机数据
    x = dataSrc();

    % 调制
    y = modulator(x);

    % 通过通道传输并接收信号
    rxSamples = channel(y);

    % 处理接收到的信号，删除瞬态等
    frame = ModClassFrameGenerator(rxSamples, spf, spf, transDelay, sps);

    % 计算频谱
    f = (-fs/2:fs/spf:fs/2-fs/spf);
    spectrum = fftshift(fft(frame));

    % 绘制频谱图
    plot(f, 10*log10(abs(spectrum).^2));
end

% 创建用于绘制星座图的图形
figure('Name', '各种信号的星座图');
for modType = 1:numModulationTypes
    fprintf('%s - 正在生成 %s 的星座图\n', ...
        datestr(toc/86400,'HH:MM:SS'), modulationTypes(modType))
    
    subplot(6, 2, modType);
    hold on;
    title(char(modulationTypes(modType)),'FontSize',32);
    xlabel('实部','FontSize',24);
    ylabel('虚部','FontSize',24);
    grid on;
    set(gca,'FontSize',9);

    numSymbols = (numFramesPerModType / sps);
    dataSrc = getSource(modulationTypes(modType), sps, 2*spf, fs);
    modulator = ModClassGetModulator(modulationTypes(modType), sps, fs);

    % 生成随机数据
    x = dataSrc();

    % 调制
    y = modulator(x);

    % 绘制星座图
    scatter(real(y), imag(y), '.');
end

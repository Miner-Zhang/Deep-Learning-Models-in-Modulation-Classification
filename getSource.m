function src = getSource(modType, sps, spf, fs)
% 调制类型的 %getSource 源选择器
% % SRC = getSource（TYPE，SPS，SPF，fs） 返回数据源
% % 表示调制类型 TYPE，包含样本数
% 每个符号的百分比 SPS、每帧 SPF 的样本数，以及
% 采样频率 fs 的百分比。

switch modType
  case {"BPSK","2FSK","GFSK","CPFSK"}
    M = 2;
    src = @()randi([0 M-1],spf/sps,1);
  case {"QPSK","PAM4"}
    M = 4;
    src = @()randi([0 M-1],spf/sps,1);
  case {"8PSK","8FSK"}
    M = 8;
    src = @()randi([0 M-1],spf/sps,1);
  case "16QAM"
    M = 16;
    src = @()randi([0 M-1],spf/sps,1);
  case "64QAM"
    M = 64;
    src = @()randi([0 M-1],spf/sps,1);
  case {"B-FM","DSB-AM","SSB-AM"}
    src = @()getAudio(spf,fs);
  case "LFM"
    rangeN = [512, 1920];
    rangeB = [fs/20, fs/16]; % 带宽 （Hz） 范围
    sweepDirections = {'Up','Down'};
    Ts = 1/fs;
    
    %获取随机参数的百分比
    B = randOverInterval(rangeB);
    Ncc = round(randOverInterval(rangeN));
    hLfm = phased.LinearFMWaveform('SampleRate',fs,'OutputFormat','Samples');           
    % 生成 LFM
    hLfm.SweepBandwidth = B;
    hLfm.PulseWidth = Ncc*Ts;
    hLfm.NumSamples = 256;
    hLfm.PRF = 1/(Ncc*Ts);
    hLfm.SweepDirection = sweepDirections{randi(2)};
    src = hLfm();  
   

   case 'Rect'
    %创建信号
    hRect = phased.RectangularWaveform(...
             'SampleRate',fs,...
             'OutputFormat','Samples');
            
    %获取随机参数
    rangeN = [512, 1920]; % Number of collected signal samples range
    Ts = 1/fs;
    Ncc = round(randOverInterval(rangeN));
                
   % 创建波形
    hRect.PulseWidth = Ncc*Ts;
    hRect.PRF = 1/(Ncc*Ts);
    hRect.NumSamples = 256;
    src = hRect();
                
%     filter = phased.MatchedFilter( ...
%                'Coefficients',getMatchedFilter(hRect),...
%                'SampleRate', fs,...
%                'SpectrumWindow','None');
%                 src = filter(wav);
                
   case 'Barker'
            rangeNChip = [3,4,5,7,11]; % 芯片数量
            rangeNcc = [1,5]; % 每相代码的周期数
            rangeFc = [fs/6, fs/5]; %中心频率 （Hz） 范围
            Ts = 1/fs;
            % 创建信号并更新 SNR
            hPhaseBarker = phased.PhaseCodedWaveform(...
                'SampleRate',fs,...
                'Code',string(modType),...
                'OutputFormat','Samples');
            
%                 获取随机参数
                Fc = randOverInterval(rangeFc);
                N = rangeNChip(randi(length(rangeNChip),1));
                Ncc = rangeNcc(randi(length(rangeNcc),1));
                
                % 创建信号并更新 SNR
                chipWidth = Ncc/Fc;
                chipWidthSamples = round(chipWidth*fs)-1; % This must be an integer!
                chipWidth = chipWidthSamples*Ts;
                hPhaseBarker.ChipWidth = chipWidth;
                hPhaseBarker.NumChips = N;
                hPhaseBarker.PRF = 1/((chipWidthSamples*N+1)*Ts);
                hPhaseBarker.NumSamples = 256;
                src = hPhaseBarker();
                
%                 filter = phased.MatchedFilter( ...
%                           'Coefficients',getMatchedFilter(hPhaseBarker),...
%                           'SampleRate', fs,...
%                           'SpectrumWindow','None');
%                 src = filter(wav);
                
      case 'Frank'
            rangeNChip = 4; % 芯片数量
            rangeNcc = [1,5]; % 每相代码的周期数
            rangeFc = [fs/6, fs/5]; % 中心频率 （Hz） 范围
            Ts = 1/fs;
            % 创建信号并更新 SNR
            hPhaseFrank = phased.PhaseCodedWaveform(...
                'SampleRate',fs,...
                'Code',string(modType),...
                'OutputFormat','Samples');
            
            
%               获取随机参数
                
                Fc = randOverInterval(rangeFc);
                N = rangeNChip(randi(length(rangeNChip),1));
                Ncc = rangeNcc(randi(length(rangeNcc),1));
                
                % 创建信号并更新 SNR
                chipWidth = Ncc/Fc;
                chipWidthSamples = round(chipWidth*fs)-1; % 这必须是一个整数！
                chipWidth = chipWidthSamples*Ts;
                hPhaseFrank.ChipWidth = chipWidth;
                hPhaseFrank.NumChips = N;
                hPhaseFrank.PRF = 1/((chipWidthSamples*N+1)*Ts);
                hPhaseFrank.NumSamples = 256;
                src = hPhaseFrank();
                
%                 filter = phased.MatchedFilter( ...
%                           'Coefficients',getMatchedFilter(hPhaseFrank),...
%                           'SampleRate', fs,...
%                           'SpectrumWindow','None');
%                 src = filter(wav);
            
      case 'P1'
            rangeNChip = 4; %  芯片数量
            rangeNcc = [1,5]; % 每相代码的周期数
            
            % 创建信号并更新 SNR
            hPhaseP1 = phased.PhaseCodedWaveform(...
                'SampleRate',fs,...
                'Code',string(modType),...
                'OutputFormat','Samples');
           rangeFc = [fs/6, fs/5]; %中心频率 （Hz） 范围
            Ts = 1/fs; 
           
          
                %获取随机参数
                Fc = randOverInterval(rangeFc);
                N = rangeNChip(randi(length(rangeNChip),1));
                Ncc = rangeNcc(randi(length(rangeNcc),1));

                          
           % 创建信号并更新 SNR
            chipWidth = Ncc/Fc;
            chipWidthSamples = round(chipWidth*fs)-1; % 这必须是一个整数！
            chipWidth = chipWidthSamples*Ts;
            hPhaseP1.ChipWidth = chipWidth;
            hPhaseP1.NumChips = N;
            hPhaseP1.PRF = 1/((chipWidthSamples*N+1)*Ts);
            hPhaseP1.NumSamples = 256;
            src = hPhaseP1();
            
%             filter = phased.MatchedFilter( ...
%                           'Coefficients',getMatchedFilter(hPhaseP1),...
%                           'SampleRate', fs,...
%                           'SpectrumWindow','None');
%             src = filter(wav);
            
            
      case 'P2'
            rangeNChip = 4; % 芯片数量
            rangeNcc = [1,5]; %每相代码的周期数
            rangeFc = [fs/6, fs/5]; % 中心频率 （Hz） 范围
            Ts = 1/fs; 
            % 创建信号并更新SNR
            hPhaseP2 = phased.PhaseCodedWaveform(...
                'SampleRate',fs,...
                'Code',string(modType),...
                'OutputFormat','Samples');
            
           
                %获取随机参数
               
                Fc = randOverInterval(rangeFc);
                N = rangeNChip(randi(length(rangeNChip),1));
                Ncc = rangeNcc(randi(length(rangeNcc),1));

                            
                % 创建信号并更新 SNR
                chipWidth = Ncc/Fc;
                chipWidthSamples = round(chipWidth*fs)-1; % 这必须是一个整数!
                chipWidth = chipWidthSamples*Ts;
                hPhaseP2.ChipWidth = chipWidth;
                hPhaseP2.NumChips = N;
                hPhaseP2.PRF = 1/((chipWidthSamples*N+1)*Ts);
                hPhaseP2.NumSamples = 256;
                src = hPhaseP2();
                
%                 filter = phased.MatchedFilter( ...
%                           'Coefficients',getMatchedFilter(hPhaseP2),...
%                           'SampleRate', fs,...
%                           'SpectrumWindow','None');
%                 src = filter(wav);
               
     case 'P3'
            rangeNChip = 4; % 芯片数量
            rangeNcc = [1,5]; % 每相代码的周期数
            
            %创建信号并更新SNR
            hPhaseP3 = phased.PhaseCodedWaveform(...
                'SampleRate',fs,...
                'Code',string(modType),...
                'OutputFormat','Samples');
            rangeFc = [fs/6, fs/5]; % 中心频率 （Hz） 范围
            Ts = 1/fs; 
           
               
                %获取随机参数
                Fc = randOverInterval(rangeFc);
                N = rangeNChip(randi(length(rangeNChip),1));
                Ncc = rangeNcc(randi(length(rangeNcc),1));

           
                
                %创建信号并更新SNR
                chipWidth = Ncc/Fc;
                chipWidthSamples = round(chipWidth*fs)-1; % 这必须是一个整数!
                chipWidth = chipWidthSamples*Ts;
                hPhaseP3.ChipWidth = chipWidth;
                hPhaseP3.NumChips = N;
                hPhaseP3.PRF = 1/((chipWidthSamples*N+1)*Ts);
                hPhaseP3.NumSamples = 256;
                src = hPhaseP3();
                
%                 filter = phased.MatchedFilter( ...
%                           'Coefficients',getMatchedFilter(hPhaseP3),...
%                           'SampleRate', fs,...
%                           'SpectrumWindow','None');
%                 src = filter(wav);
            
            case 'P4'
            rangeNChip = 4; % 芯片数量
            rangeNcc = [1,5]; % 每相代码的周期数
            rangeFc = [fs/6, fs/5]; % 中心频率 （Hz） 范围
            Ts = 1/fs; 
            %创建信号并更新SNR
            hPhaseP4 = phased.PhaseCodedWaveform(...
                'SampleRate',fs,...
                'Code',string(modType),...
                'OutputFormat','Samples');
            
           
               
                %获取随机参数
                Fc = randOverInterval(rangeFc);
                N = rangeNChip(randi(length(rangeNChip),1));
                Ncc = rangeNcc(randi(length(rangeNcc),1));

         
                %创建信号并更新SNR
                chipWidth = Ncc/Fc;
                chipWidthSamples = round(chipWidth*fs)-1; % 这必须是一个整数!
                chipWidth = chipWidthSamples*Ts;
                hPhaseP4.ChipWidth = chipWidth;
                hPhaseP4.NumChips = N;
                hPhaseP4.PRF = 1/((chipWidthSamples*N+1)*Ts);
                hPhaseP4.NumSamples = 256;
                src = hPhaseP4();
                
%                 filter = phased.MatchedFilter( ...
%                           'Coefficients',getMatchedFilter(hPhaseP4),...
%                           'SampleRate', fs,...
%                           'SpectrumWindow','None');
%                src = filter(wav);
            
     case 'Zadoff-Chu'
            rangeNChip = 4; % 芯片数量
            rangeNcc = [1,5]; % 每相代码的周期数
            rangeFc = [fs/6, fs/5]; % 中心频率 （Hz） 范围
            Ts = 1/fs; 
            % 创建信号并更新SNR
            hPhaseZadoffChu = phased.PhaseCodedWaveform(...
                'SampleRate',fs,...
                'Code',string(modType),...
                'OutputFormat','Samples');
                
                %获取随机参数
                Fc = randOverInterval(rangeFc);
                N = rangeNChip(randi(length(rangeNChip),1));
                Ncc = rangeNcc(randi(length(rangeNcc),1));
                
                % 创建信号并更新SNR
                chipWidth = Ncc/Fc;
                chipWidthSamples = round(chipWidth*fs)-1; % 这必须是一个整数!
                chipWidth = chipWidthSamples*Ts;
                hPhaseZadoffChu.ChipWidth = chipWidth;
                hPhaseZadoffChu.NumChips = N;
                hPhaseZadoffChu.PRF = 1/((chipWidthSamples*N+1)*Ts);
                hPhaseZadoffChu.NumSamples = 256;
                src = hPhaseZadoffChu();
                
%                 filter = phased.MatchedFilter( ...
%                           'Coefficients',getMatchedFilter(hPhaseZadoffChu),...
%                           'SampleRate', fs,...
%                           'SpectrumWindow','None');
%             src = filter(wav);
        otherwise
            error('Modulation type not recognized.');
end


%% 子例程
function val = randOverInterval(interval)
% 预计间隔为 <1x2>，格式为 [minVal maxVal]
val = (interval(2) - interval(1)).*rand + interval(1);
end
end

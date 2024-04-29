classdef ModClassFrameStore < handle
    %helperModClassFrameStore 管理调制分类数据
    % FS = helperModClassFrameStore 创建一个帧存储对象 FS，该对象
    % 以机器中可用的格式存储复杂的基带信号
    % 学习算法。
    %
    % FS = helperModClassFrameStore（MAXFR，SPF，LABELS） 创建帧存储
    % object，FH，最大帧数，MAXFR，每个
    % 帧、SPF 和预期标签 LABELS。
    %
    % 方法：
    %
    % add（FS，FRAMES，LABEL） 将 frame（s）， FRAMES， with label， 添加到
    % 帧存储。
    % %
    % % [FRAMES，LABELS] = get（FS） 返回存储的帧和相应的
    % 来自帧存储的标签百分比，FS。
    % %
    % %

    properties
        OutputFormat = FrameStoreOutputFormat.IQAsRows
    end

    properties (SetAccess=private)
        %NumFrames 帧存储中的帧数
        NumFrames = 0
        %最大帧数 存储帧的容量
        MaximumNumFrames
        %每帧采样 每帧采样
        SamplesPerFrame
        %标签 预期标签集
        Labels
    end

    properties (Access=private)
        Frames
        Label
    end

    methods
        function obj = ModClassFrameStore(varargin)
            %       存储复杂的 I/Q 帧
            % FS = ModClassFrameStore(MAXFR,SPF,LABELS) 返回一个帧
            %       存储对象 FS，用于存储复 I/Q 基带帧，其类型为
            % LABEL，帧大小为 SPF。帧存储为
            % [SPFxNUMFRAMES] 数组。

            inputs = inputParser;
            addRequired(inputs, 'MaximumNumFrames')
            addRequired(inputs, 'SamplesPerFrame')
            addRequired(inputs, 'Labels')
            parse(inputs, varargin{:})

            obj.SamplesPerFrame = inputs.Results.SamplesPerFrame;
            obj.MaximumNumFrames = inputs.Results.MaximumNumFrames;
            obj.Labels = inputs.Results.Labels;
            obj.Frames = ...
                zeros(obj.SamplesPerFrame,obj.MaximumNumFrames);
            obj.Label = repmat(obj.Labels(1),obj.MaximumNumFrames,1);
        end

        function add(obj,frames,label,varargin)
            %       将基带帧添加到帧存储中
            % add(FS,FRAMES,LABEL) 将带有标签 LABEL 的帧 FRAMES 添加到
            %帧存储 FS。

            numNewFrames = size(frames,2);
            if (~isscalar(label) && numNewFrames ~= length(label)) ...
                    && (size(frames,1) ~= obj.SamplesPerFrame)
                error(message('comm_demos:ModClassFrameStore:MismatchedInputSize'));
            end

            % 添加框架
            startIdx = obj.NumFrames+1;
            endIdx = obj.NumFrames+numNewFrames;
            obj.Frames(:,startIdx:endIdx) = frames;

            % 添加标签类型
            if all(ismember(label,obj.Labels))
                obj.Label(startIdx:endIdx,1) = label;
            else
                error(message('comm_demos:ModClassFrameStore:UnknownLabel',...
                    label(~ismember(label,obj.Labels))))
            end

            obj.NumFrames = obj.NumFrames + numNewFrames;
        end

        function [frames,labels] = get(obj)
            %get 返回帧和标签
            % [FRAMES,LABELS]=get(FS) 返回帧存储区 FS 中的帧和相应的
            % 返回帧存储区 FS 中的帧和相应的标签。
            %
            %       如果输出格式是 IQAsRows，那么 FRAMES 是一个大小为
            % [2xSPFx1xNUMFRAMES]，其中第一行是同相分量，第二行是相位分量。
            %       第二行是正交分量。
            %
            %       如果输出格式为 IQAsPages，则 FRAMES 是大小为 % [1xSPFx2xNUMFRAMES] 的数组。
            % [1xSPFx2xNUMFRAMES]，其中第一页（第 3 维）是同相分量，第二页是正交分量。
            % 同相分量，第二页为正交分量。
            %       分量。

            switch obj.OutputFormat
                case FrameStoreOutputFormat.IQAsRows
                    I = real(obj.Frames(:,1:obj.NumFrames));
                    Q = imag(obj.Frames(:,1:obj.NumFrames));
                    I = permute(I,[3 1 4 2]);
                    Q = permute(Q,[3 1 4 2]);
                    frames = cat(1,I,Q);
                case FrameStoreOutputFormat.IQAsPages
                    I = real(obj.Frames(:,1:obj.NumFrames));
                    Q = imag(obj.Frames(:,1:obj.NumFrames));
                    I = permute(I,[3 1 4 2]);
                    Q = permute(Q,[3 1 4 2]);
                    frames = cat(3,I,Q);
            end

            labels = obj.Label(1:obj.NumFrames,1);
        end

        function [fsTraining,fsValidation,fsTest] = ...
                splitData(obj,splitPercentages)
            %       将数据分为训练、验证和测试
            %[FSTRAIN,FSVALID,FSTEST]=splitData(FS,PER)会将存储的帧
            %的帧分成训练组、验证组和测试组。
            %的百分比，即 PER。PER 是一个三元素向量、
            % [PERTRAIN,PERVALID,PERTEST]，指定了训练、验证和测试的百分比、
            %       验证和测试百分比。FSTRAIN、FSVALID 和 FSTEST
            %       分别是训练帧、验证帧和测试帧的存储空间。

            fsTraining = ModClassFrameStore(...
                ceil(obj.MaximumNumFrames*splitPercentages(1)/100), ...
                obj.SamplesPerFrame, obj.Labels);
            fsValidation = ModClassFrameStore(...
                ceil(obj.MaximumNumFrames*splitPercentages(2)/100), ...
                obj.SamplesPerFrame, obj.Labels);
            fsTest = ModClassFrameStore(...
                ceil(obj.MaximumNumFrames*splitPercentages(3)/100), ...
                obj.SamplesPerFrame, obj.Labels);

            for modType = 1:length(obj.Labels)
                rawIdx = find(obj.Label == obj.Labels(modType));
                numFrames = length(rawIdx);

                % 首先洗框
                shuffleIdx = randperm(numFrames);
                frames = obj.Frames(:,rawIdx);
                frames = frames(:,shuffleIdx);

                numTrainingFrames = round(numFrames*splitPercentages(1)/100);
                numValidationFrames = round(numFrames*splitPercentages(2)/100);
                numTestFrames = round(numFrames*splitPercentages(3)/100);
                extraFrames = sum([numTrainingFrames,numValidationFrames,numTestFrames]) - numFrames;
                if (extraFrames > 0)
                    numTestFrames = numTestFrames - extraFrames;
                end

                add(fsTraining, ...
                    frames(:,1:numTrainingFrames), ...
                    obj.Labels(modType));
                add(fsValidation, ...
                    frames(:,numTrainingFrames+(1:numValidationFrames)), ...
                    obj.Labels(modType));
                add(fsTest, ...
                    frames(:,numTrainingFrames+numValidationFrames+(1:numTestFrames)), ...
                    obj.Labels(modType));
            end

            % 洗牌新帧存储
            shuffle(fsTraining);
            shuffle(fsValidation);
            shuffle(fsTest);
        end

        function shuffle(obj)
            %       洗卷存储的帧
            %shuffle(FS) 更改存储帧的顺序。

            shuffleIdx = randperm(obj.NumFrames);
            obj.Frames = obj.Frames(:,shuffleIdx);
            obj.Label = obj.Label(shuffleIdx,1);
        end
    end
end


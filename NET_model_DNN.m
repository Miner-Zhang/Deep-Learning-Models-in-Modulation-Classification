 %% 定义特征提取函数    
 % 计算波形形状特征
 function shapeFeatures = computeWaveformShape(signal)


    % 峰值
    peakToPeak = max(signal) - min(signal);

    % 均方根值
    rmsValue = rms(signal);

    % 波形因子
    waveformFactor = rmsValue / mean(abs(signal), 'all'); % 明确指定在所有维度上取平均值

    % 时域零交叉率
    zeroCrossingRate = sum(abs(diff(sign(signal)))) / (2 * length(signal));

    % 波形斜率
    slope = diff(signal);

    % 汇总波形形状特征
    shapeFeatures = [peakToPeak, rmsValue, waveformFactor, ...
                     zeroCrossingRate, slope];   
end
 function features = extractFeatures(signal)
    % 时域特征
    meanVal = mean(signal);
    variance = var(signal);
    peakValue = max(signal);
    skewnessVal = skewness(signal);
    kurtosisVal = kurtosis(signal);
    meanAbsDev = mean(abs(signal - meanVal));
    % 波形特征
    waveformShape = computeWaveformShape(signal);
    
    % 汇总所有特征
    features = [meanVal, variance, peakValue, skewnessVal, kurtosisVal,...
        meanAbsDev, waveformShape];
end
%% 特征提取
% 初始化用于存储特征的单元数组
trainFeatures_DNN = cell(size(rxTraining, 4), 1);
validationFeatures_DNN = cell(size(rxValidation, 4), 1);
testFeatures_DNN = cell(size(rxTest, 4), 1);

% 提取训练、验证和测试数据的特征
for ii = 1:size(rxTraining, 4)
    trainFeatures_DNN{ii} = extractFeatures(rxTraining(:, :, :, ii));
end

for ii = 1:size(rxValidation, 4)
    validationFeatures_DNN{ii} = extractFeatures(rxValidation(:, :, :, ii));
end

for ii = 1:size(rxTest, 4)
    testFeatures_DNN{ii} = extractFeatures(rxTest(:, :, :, ii));
end

% 将特征转换为矩阵形式，保留四维结构
trainingData_DNN = cat(4, trainFeatures_DNN{:});
validationData_DNN = cat(4, validationFeatures_DNN{:});
testData_DNN = cat(4, testFeatures_DNN{:});


%% 定义神经网络模型
numModTypes = numel(modulationTypes);
Layers_DNN = [
    imageInputLayer([1 1033 2], 'Normalization', 'none', 'Name', 'InputLayer')
    fullyConnectedLayer(64 * numModTypes, 'Name', 'FC1')
    reluLayer('Name', 'ReLU1')
    dropoutLayer()
    fullyConnectedLayer(64 * numModTypes, 'Name', 'FC2')
    reluLayer('Name', 'ReLU2')
    dropoutLayer()
    fullyConnectedLayer(numModTypes, 'Name', 'FC3')
    softmaxLayer('Name', 'SoftMax')
    classificationLayer('Name', 'OutputLayer')];

% 定义训练选项
maxEpochs = 50;
miniBatchSize = 1024;
validationFrequency = floor(numel(rxTrainingLabel)/miniBatchSize);
Options_DNN = trainingOptions('adam', ...
    'InitialLearnRate', 0.0013, ...
    'MaxEpochs', maxEpochs, ...
    'MiniBatchSize', miniBatchSize, ...
    'Shuffle', 'every-epoch', ...
    'Plots', 'training-progress', ...
    'Verbose', true, ...
    'ValidationData', {validationData_DNN, rxValidationLabel}, ...
    'ValidationFrequency', validationFrequency, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropPeriod', 15, ...
    'LearnRateDropFactor', 0.9,...
    'ExecutionEnvironment', 'multi-gpu');
 %% 训练 DNN 模型
    fprintf('%s - Training the DNN network\n', datestr(toc/86400,'HH:MM:SS'))
    DNN_NET = trainNetwork(trainingData_DNN, rxTrainingLabel, Layers_DNN, Options_DNN);

% 评估网络
    fprintf('%s - Classifying test frames\n', datestr(toc/86400,'HH:MM:SS'))
    rxTestPred_DNN = classify(DNN_NET, testData_DNN); 
    testAccuracy_DNN = mean(rxTestPred_DNN == rxTestLabel);
    disp("Test accuracy: " + testAccuracy_DNN*100 + "%")

%% 混淆矩阵绘制
figure
    cm = confusionchart(rxTestLabel, rxTestPred_DNN); 
    cm.Title = 'Confusion Matrix for Validation Data (DNN)';
    cm.RowSummary = 'row-normalized';
    %cm.Normalization = 'total-normalized';
    sortClasses(cm,'descending-diagonal')
    cm.Parent.Position = [cm.Parent.Position(1:2) 740 424];
       
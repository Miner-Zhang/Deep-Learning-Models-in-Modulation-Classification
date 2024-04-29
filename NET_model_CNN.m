%% 定义神经网络模型
numModTypes = numel(modulationTypes);
netWidth = 2;
filterSize = [1 sps];
poolSize = [1 2];

Layers_CNN = [
    imageInputLayer([1 spf 2], 'Normalization', 'none', 'Name', 'Input Layer')
    
    convolution2dLayer(filterSize, 8*netWidth, 'Padding', 'same', 'Name', 'CNN1')
    batchNormalizationLayer('Name', 'BN1')
    reluLayer('Name', 'ReLU1')
    maxPooling2dLayer(poolSize, 'Stride', [1 2], 'Name', 'MaxPool1')

    convolution2dLayer(filterSize, 16*netWidth, 'Padding', 'same', 'Name', 'CNN2')
    batchNormalizationLayer('Name', 'BN2')
    reluLayer('Name', 'ReLU2')
    maxPooling2dLayer(poolSize, 'Stride', [1 2], 'Name', 'MaxPool2')

    convolution2dLayer(filterSize, 24*netWidth, 'Padding', 'same', 'Name', 'CNN3')
    batchNormalizationLayer('Name', 'BN3')
    reluLayer('Name', 'ReLU3')
    maxPooling2dLayer(poolSize, 'Stride', [1 2], 'Name', 'MaxPool3')

    convolution2dLayer(filterSize, 40*netWidth, 'Padding', 'same', 'Name', 'CNN4')
    batchNormalizationLayer('Name', 'BN4')
    reluLayer('Name', 'ReLU4')
    maxPooling2dLayer(poolSize, 'Stride', [1 2], 'Name', 'MaxPool4')

    convolution2dLayer(filterSize, 56*netWidth, 'Padding', 'same', 'Name', 'CNN5')
    batchNormalizationLayer('Name', 'BN5')
    reluLayer('Name', 'ReLU5')
    maxPooling2dLayer(poolSize, 'Stride', [1 2], 'Name', 'MaxPool5')

    convolution2dLayer(filterSize, 72*netWidth, 'Padding', 'same', 'Name', 'CNN6')
    batchNormalizationLayer('Name', 'BN6')
    reluLayer('Name', 'ReLU6')
    maxPooling2dLayer(poolSize, 'Stride', [1 2], 'Name', 'MaxPool6')

    %   Added by Rachana
    convolution2dLayer(filterSize, 104*netWidth, 'Padding', 'same', 'Name', 'CNN7')
    batchNormalizationLayer('Name', 'BN7')
    reluLayer('Name', 'ReLU7')

    averagePooling2dLayer([1 ceil(spf/64)], 'Name', 'AP1')

    fullyConnectedLayer(numModTypes, 'Name', 'FC1')
    softmaxLayer('Name', 'SoftMax')

    classificationLayer('Name', 'Output') ];


    % 定义训练选项

    maxEpochs = 20;
    miniBatchSize = 1024;
    validationFrequency = floor(numel(rxTrainingLabel)/miniBatchSize);
    Options_CNN = trainingOptions('adam', ...
        'InitialLearnRate',1e-2, ...
        'MaxEpochs',maxEpochs, ...
        'MiniBatchSize',miniBatchSize, ...
        'Shuffle','every-epoch', ...
        'Plots','training-progress', ...
        'Verbose',true, ...
        'ValidationData',{rxValidation,rxValidationLabel}, ...
        'ValidationFrequency',validationFrequency, ...
        'LearnRateSchedule', 'piecewise', ...
        'LearnRateDropPeriod', 9, ...
        'LearnRateDropFactor', 0.2, ...
        'ExecutionEnvironment', 'multi-gpu');
%% 训练 CNN 模型
    fprintf('%s - Training the CNN network\n', datestr(toc/86400,'HH:MM:SS'))
    CNN_NET = trainNetwork(rxTraining,rxTrainingLabel,Layers_CNN,Options_CNN);
% 评估网络

    fprintf('%s - Classifying test frames\n', datestr(toc/86400,'HH:MM:SS'))
    rxTestPred_CNN = classify(CNN_NET,rxTest);
    testAccuracy_CNN = mean(rxTestPred_CNN == rxTestLabel);
    disp("Test accuracy: " + testAccuracy_CNN*100 + "%")

%% 混淆矩阵绘制

    figure
    cm = confusionchart(rxTestLabel, rxTestPred_CNN);
    cm.Title = 'Confusion Matrix for Test Data(CNN)';
    cm.RowSummary = 'row-normalized';
    % cm.Normalization = 'total-normalized';
    sortClasses(cm,'descending-diagonal')
    cm.Parent.Position = [cm.Parent.Position(1:2) 740 424];
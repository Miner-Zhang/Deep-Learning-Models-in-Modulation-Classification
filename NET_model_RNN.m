
% 初始化用于存储特征的单元数组
trainFeatures_RNN = cell(size(rxTraining, 4), 1);
validationFeatures_RNN = cell(size(rxValidation, 4), 1);
testFeatures_RNN = cell(size(rxTest, 4), 1);

% 提取训练、验证和测试数据的特征
for ii = 1:size(rxTraining, 4)
    trainFeatures_RNN{ii} = extractFeatures(rxTraining(:, :, :, ii));
end

for ii = 1:size(rxValidation, 4)
    validationFeatures_RNN{ii} = extractFeatures(rxValidation(:, :, :, ii));
end

for ii = 1:size(rxTest, 4)
    testFeatures_RNN{ii} = extractFeatures(rxTest(:, :, :, ii));
end

% 模型训练和测试
numModTypes=numel(modulationTypes);
%初始化
trainingData_RNN = cellfun(@(x) reshape(x, [], 2066, 1), trainFeatures_RNN, 'UniformOutput', false);
testData_RNN  = cellfun(@(x) reshape(x, [], 2066, 1), testFeatures_RNN, 'UniformOutput', false);
validationData_RNN   = cellfun(@(x) reshape(x, [], 2066, 1), validationFeatures_RNN, 'UniformOutput', false);

trainingData_RNN = cellfun(@(x) permute(x, [2, 1, 3]), trainingData_RNN, 'UniformOutput', false);
testData_RNN = cellfun(@(x) permute(x, [2, 1, 3]), testData_RNN, 'UniformOutput', false);
validationData_RNN = cellfun(@(x) permute(x, [2, 1, 3]), validationData_RNN, 'UniformOutput', false);

% 定义神经网络模型
Layers_RNN = [
    sequenceInputLayer(2066, 'Name', 'input')
    bilstmLayer(256, 'OutputMode', 'last', 'Name', 'bilstm1')
    dropoutLayer(0.2)
    lstmLayer(512, 'OutputMode', 'last', 'Name', 'lstm2')
    dropoutLayer(0.2)
    fullyConnectedLayer(128)
    reluLayer
    fullyConnectedLayer(numModTypes)
    softmaxLayer
    classificationLayer];

% 定义训练选项
maxEpochs = 50;
miniBatchSize = 1024;
validationFrequency = floor(numel(rxTrainingLabel)/miniBatchSize);
Options_RNN = trainingOptions('adam', ...    
    'InitialLearnRate', 0.009, ...
    'MaxEpochs', maxEpochs, ...
    'MiniBatchSize', miniBatchSize, ...
    'Shuffle', 'every-epoch', ...
    'ValidationData', {validationData_RNN, rxValidationLabel}, ...
    'ValidationFrequency', validationFrequency, ...
    'Plots', 'training-progress', ...
    'Verbose', true, ...
    'LearnRateSchedule', 'piecewise', ...
    'LearnRateDropPeriod', 10, ...
    'LearnRateDropFactor', 0.9, ...
    'ExecutionEnvironment', 'gpu');


% 训练 LSTM 模型
    fprintf('%s - Training the RNN(LSTM) network\n', datestr(toc/86400,'HH:MM:SS'))
    RNN_NET = trainNetwork(trainingData_RNN, rxTrainingLabel, Layers_RNN, Options_RNN);

% 测试模型
    fprintf('%s - Classifying test frames\n', datestr(toc/86400,'HH:MM:SS'))
    rxTestPred_RNN = classify(RNN_NET, testData_RNN); 
    testAccuracy_RNN = mean(rxTestPred_RNN == rxTestLabel);
    disp("Test accuracy: " + testAccuracy_RNN*100 + "%")
% 混淆矩阵绘制
figure;
    cm=confusionchart(rxTestLabel,rxTestPred_RNN);
    cm.Title = 'Confusion Matrix for Test Data(LSTM)';
    cm.RowSummary = 'row-normalized';
    %cm.Normalization = 'total-normalized';
    sortClasses(cm,'descending-diagonal')
    cm.Parent.Position = [cm.Parent.Position(1:2) 740 424];
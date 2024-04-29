%% CNN
% load('TrainedNet_CNN.mat');
    fprintf('%s - Classifying test frames for CNN\n', datestr(toc/86400,'HH:MM:SS'))
    rxTestPred_CNN = classify(CNN_NET, rxTest);
    testAccuracy_CNN = mean(rxTestPred_CNN == rxTestLabel);
       
    % 计算混淆矩阵
    cm_CNN = confusionmat(rxTestLabel, rxTestPred_CNN); 
    % 计算召回率
    recall_CNN = cm_CNN(2, 2) / (cm_CNN(2, 2) + cm_CNN(2, 1));
    % 计算精确率
    precision_CNN = cm_CNN(2, 2) / (cm_CNN(2, 2) + cm_CNN(1, 2));
    % 计算F1分数
    f1_CNN = 2 * (precision_CNN * recall_CNN) / (precision_CNN + recall_CNN);    
    % 计算准确率
    accuracy_CNN = sum(diag(cm_CNN)) / sum(cm_CNN(:));    
    % 计算特异度
    specificity_CNN = cm_CNN(1, 1) / (cm_CNN(1, 1) + cm_CNN(1, 2));    
    % 计算假正率
    fpr_CNN = 1 - specificity_CNN;

    figure;
        % Calculate confusion matrix
        cm_CNN = confusionchart(rxTestLabel, rxTestPred_CNN);    
        cm_CNN.Title = 'Confusion Matrix for Test Data (CNN)';
        cm_CNN.RowSummary = 'row-normalized';
        sortClasses(cm_CNN,'descending-diagonal')
        cm_CNN.Parent.Position = [cm_CNN.Parent.Position(1:2) 740 424];
    disp(['CNN召回率:', num2str(recall_CNN)])
    disp(['CNNF1分数:', num2str(f1_CNN)])
    disp(['CNN精确率:', num2str(precision_CNN)])
    disp(['CNN准确率:', num2str(accuracy_CNN)])
    disp(['CNN特异度:', num2str(specificity_CNN)])
    disp(['CNN假正率:', num2str(fpr_CNN)])

%% DNN
% load('TrainedNet_DNN.mat');
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

    % Classify test frames using DNN model
    fprintf('%s - Classifying test frames for DNN\n', datestr(toc/86400,'HH:MM:SS'))
    rxTestPred_DNN = classify(DNN_NET, testData_DNN); 
    testAccuracy_DNN = mean(rxTestPred_DNN == rxTestLabel);
    
    % 计算混淆矩阵
    cm_DNN = confusionmat(rxTestLabel, rxTestPred_DNN);
    
    % 计算召回率
    recall_DNN = cm_DNN(2, 2) / (cm_DNN(2, 2) + cm_DNN(2, 1));
    
    % 计算精确率
    precision_DNN = cm_DNN(2, 2) / (cm_DNN(2, 2) + cm_DNN(1, 2));
    
    % 计算F1分数
    f1_DNN = 2 * (precision_DNN * recall_DNN) / (precision_DNN + recall_DNN);
    
    % 计算准确率
    accuracy_DNN = sum(diag(cm_DNN)) / sum(cm_DNN(:));
    
    % 计算特异度
    specificity_DNN = cm_DNN(1, 1) / (cm_DNN(1, 1) + cm_DNN(1, 2));
    
    % 计算假正率
    fpr_DNN = 1 - specificity_DNN;

    figure;
        % Calculate confusion matrix for DNN
        cm_DNN = confusionchart(rxTestLabel, rxTestPred_DNN); 
        cm_DNN.Title = 'Confusion Matrix for Test Data (DNN)';
        cm_DNN.RowSummary = 'row-normalized';
        sortClasses(cm_DNN,'descending-diagonal')
        cm_DNN.Parent.Position = [cm_DNN.Parent.Position(1:2) 740 424];

    disp(['DNN召回率:', num2str(recall_DNN)])
    disp(['DNNF1分数:', num2str(f1_DNN)])
    disp(['DNN精确率:', num2str(precision_DNN)])
    disp(['DNN准确率:', num2str(accuracy_DNN)])
    disp(['DNN特异度:', num2str(specificity_DNN)])
    disp(['DNN假正率:', num2str(fpr_DNN)])


%% LSTM
% load('TrainedNet_RNN.mat');
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
    
    %初始化
    trainingData_RNN = cellfun(@(x) reshape(x, [], 2066, 1), trainFeatures_RNN, 'UniformOutput', false);
    testData_RNN  = cellfun(@(x) reshape(x, [], 2066, 1), testFeatures_RNN, 'UniformOutput', false);
    validationData_RNN   = cellfun(@(x) reshape(x, [], 2066, 1), validationFeatures_RNN, 'UniformOutput', false);
    
    trainingData_RNN = cellfun(@(x) permute(x, [2, 1, 3]), trainingData_RNN, 'UniformOutput', false);
    testData_RNN = cellfun(@(x) permute(x, [2, 1, 3]), testData_RNN, 'UniformOutput', false);
    validationData_RNN = cellfun(@(x) permute(x, [2, 1, 3]), validationData_RNN, 'UniformOutput', false);

    % Classify test frames using RNN (LSTM) model
    fprintf('%s - Classifying test frames for RNN (LSTM)\n', datestr(toc/86400,'HH:MM:SS'))
    rxTestPred_RNN = classify(RNN_NET, testData_RNN); 
    testAccuracy_RNN = mean(rxTestPred_RNN == rxTestLabel);
    % 计算混淆矩阵
    cm_RNN = confusionmat(rxTestLabel, rxTestPred_RNN);
    % 计算召回率
    recall_RNN = cm_RNN(2, 2) / (cm_RNN(2, 2) + cm_RNN(2, 1));
    % 计算精确率
    precision_RNN = cm_RNN(2, 2) / (cm_RNN(2, 2) + cm_RNN(1, 2));
    % 计算F1分数
    f1_RNN = 2 * (precision_RNN * recall_RNN) / (precision_RNN + recall_RNN);
    % 计算准确率
    accuracy_RNN = sum(diag(cm_RNN)) / sum(cm_RNN(:));
    % 计算特异度
    specificity_RNN = cm_RNN(1, 1) / (cm_RNN(1, 1) + cm_RNN(1, 2));
    % 计算假正率
    fpr_RNN = 1 - specificity_RNN;

    figure;
            % Calculate confusion matrix for RNN
            cm_RNN = confusionchart(rxTestLabel, rxTestPred_RNN); 
            cm_RNN.Title = 'Confusion Matrix for Test Data (LSTM)';
            cm_RNN.RowSummary = 'row-normalized';
            sortClasses(cm_RNN,'descending-diagonal')
            cm_RNN.Parent.Position = [cm_RNN.Parent.Position(1:2) 740 424];

    disp(['RNN召回率:', num2str(recall_RNN)])
    disp(['RNNF1分数:', num2str(f1_RNN)])
    disp(['RNN精确率:', num2str(precision_RNN)])
    disp(['RNN准确率:', num2str(accuracy_RNN)])
    disp(['RNN特异度:', num2str(specificity_RNN)])
    disp(['RNN假正率:', num2str(fpr_RNN)])
%% 输出图表
figure;

barData = [recall_CNN, recall_DNN, recall_RNN;
           f1_CNN, f1_DNN, f1_RNN;
           precision_CNN, precision_DNN, precision_RNN;
           accuracy_CNN, accuracy_DNN, accuracy_RNN;
           specificity_CNN, specificity_DNN, specificity_RNN;
           fpr_CNN, fpr_DNN, fpr_RNN];

bar(barData);

xticklabels({'Recall', 'F1 Score', 'Precision', 'Accuracy', 'Specificity', 'False Positive Rate'});
ylabel('Score');
title('Comparison of Model Performance Metrics');
legend({'CNN', 'DNN', 'LSTM'}, 'Location', 'northoutside');

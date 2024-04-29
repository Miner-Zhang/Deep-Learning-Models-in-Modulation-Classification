function y = ModClassFrameGenerator(x, windowLength, stepSize, offset, sps)
% %helperModClassFrameGenerator 生成用于机器学习的帧
% % Y = helperModClassFrameGenerator（X，WLEN，STEP，OFFSET） 分段
% % input， X，用于生成要用于机器学习算法的帧。
% % X 必须是复值列向量。输出 Y 是一个大小
% % WLENxN 复值数组，其中 N 是输出帧数。
% % 每个单独的帧都有 WLEN 样本。窗口进行 STEP
% 新帧的样本百分比。STEP 可以小于或大于 WLEN。
% % 该函数在计算出
% 基于 OFFSET 值的 % 初始偏移量。OFFSET 是双元素
% % 实值向量，其中第一个元素是确定性偏移量
% % 值，第二个元素是随机偏移量的最大值
% % 值。总偏移量为 OFFSET（1）+randi（[0 OFFSET（2）]） 个样本。这
% 偏移的 % 确定性部分消除瞬态，而随机
% % 部分使网络能够适应未知延迟值


numSamples = length(x);
numFrames = ...
  floor(((numSamples-offset)-(windowLength-stepSize))/stepSize);

y = zeros([windowLength,numFrames],class(x));

startIdx = offset + randi([0 sps]);
frameCnt = 1;

while startIdx + windowLength < numSamples
  xWindowed = x(startIdx+(0:windowLength-1),1);
  framePower = sum(abs(xWindowed).^2);
  xWindowed = xWindowed / sqrt(framePower);
  y(:,frameCnt) = xWindowed;
  frameCnt = frameCnt + 1;
  startIdx = startIdx + stepSize;
end

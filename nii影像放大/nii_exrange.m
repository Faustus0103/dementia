clear;
clc;
close all;

% 設置影像目錄和輸出CSV文件路徑
inputDir = 'C:\Dementia\nii\labels_monai'; 
outputCSV = 'MRI_BoneMeasurements.csv';

% 設置去噪影像、擴張後影像和差集影像的儲存資料夾
denoisedDir = fullfile(inputDir, 'denoised');
dilatedDir = fullfile(inputDir, 'dilated');
differenceDir = fullfile(inputDir, 'difference');

% 創建儲存資料夾（如果尚未存在）
if ~exist(denoisedDir, 'dir')
    mkdir(denoisedDir);
end
if ~exist(dilatedDir, 'dir')
    mkdir(dilatedDir);
end
if ~exist(differenceDir, 'dir')
    mkdir(differenceDir);
end

% 獲取所有NIfTI影像文件
imageFiles = dir(fullfile(inputDir, '*.nii'));

% 初始化結果儲存
results = cell(length(imageFiles), 4);

for i = 1:length(imageFiles)
    % 讀取影像檔案
    inputFilePath = fullfile(inputDir, imageFiles(i).name);
    nii = niftiread(inputFilePath);
    info = niftiinfo(inputFilePath);
    
    % 提取影像數據
    imageData = nii;
    
    % 去除噪聲（使用高斯濾波器）
    sigma = 2;  % 高斯濾波的標準差
    denoisedImageData = imgaussfilt3(imageData, sigma);
    
    % 儲存去噪後的影像
    denoisedFilePath = fullfile(denoisedDir, [erase(imageFiles(i).name, '.nii'), '_denoised.nii']);
    niftiwrite(denoisedImageData, denoisedFilePath, info);
    
    % 擴張影像
    dilationSize = 10;  % 擴張結構元素的大小
    se = strel('cube', dilationSize);  % 定義擴張的結構元素
    dilatedImageData = imdilate(denoisedImageData, se);
    
    % 修剪擴張後影像，使其與原始影像大小相同
    finalDilatedImageData = dilatedImageData(1:size(imageData,1), 1:size(imageData,2), 1:size(imageData,3));
    
    % 計算差集
    differenceImageData = finalDilatedImageData - denoisedImageData;
    
    % 計算每個體素的體積 (毫米^3)
    voxelVolume = prod(info.PixelDimensions);
    
    % 計算原始影像的體積
    numOriginalVoxels = sum(imageData(:) > 0);
    originalVolume = numOriginalVoxels * voxelVolume;
    
    % 計算擴張後影像的體積
    numDilatedVoxels = sum(finalDilatedImageData(:) > 0);
    dilatedVolume = numDilatedVoxels * voxelVolume;
    
    % 計算差集影像的體積
    numDifferenceVoxels = sum(differenceImageData(:) > 0);
    differenceVolume = numDifferenceVoxels * voxelVolume;
    
    % 儲存結果
    results{i, 1} = imageFiles(i).name;
    results{i, 2} = originalVolume;
    results{i, 3} = dilatedVolume;
    results{i, 4} = differenceVolume;
    
    % 顯示進度
    fprintf('Processed %s\n', imageFiles(i).name);

    % 獲取影像名稱和擴展名
    [~, name, ~] = fileparts(imageFiles(i).name);

    % 保存擴張後的 NII 檔案
    niftiwrite(finalDilatedImageData, fullfile(dilatedDir, [name '_dilated.nii']), info);
    
    % 保存差集影像的 NII 檔案
    niftiwrite(differenceImageData, fullfile(differenceDir, [name '_difference.nii']), info);
end

% 將結果轉換為表格並保存為CSV文件
resultsTable = cell2table(results, 'VariableNames', {'FileName', 'OriginalVolume_mm3', 'DilatedVolume_mm3', 'DifferenceVolume_mm3'});
writetable(resultsTable, outputCSV);

disp(['結果已保存至 ', outputCSV]);


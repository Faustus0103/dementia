clear
clc
close('all')

% 設置影像目錄
imageDir = 'C:\Dementia\頭顱大小計算\test';
imageFiles = dir(fullfile(imageDir, '*.nii'));

% 設置閾值
lower_threshold = 200;
upper_threshold = 1000;

% 初始化結果儲存
results = {};

for i = 1:length(imageFiles)
    % 讀取MRI影像
    imageFilePath = fullfile(imageDir, imageFiles(i).name);
    image = niftiread(imageFilePath);
    info = niftiinfo(imageFilePath);

    % 閾值分割
    bone_mask = (image > lower_threshold) & (image < upper_threshold);

    % 移除小區域和填充孔洞
    bone_mask = bwareaopen(bone_mask, 50);
    bone_mask = imfill(bone_mask, 'holes');

    % 獲取影像的像素間距
    spacing = info.PixelDimensions;

    % 計算顱骨的邊界框
    props = regionprops3(bone_mask, 'BoundingBox');

    % 確保有找到顱骨邊界框
    if ~isempty(props)
        bounding_box = props.BoundingBox;

        % 計算實際尺寸
        width = bounding_box(1, 4) * spacing(1);
        height = bounding_box(1, 5) * spacing(2);
        depth = bounding_box(1, 6) * spacing(3);

        % 儲存結果
        results{i, 1} = imageFiles(i).name;
        results{i, 2} = width;
        results{i, 3} = height;
        results{i, 4} = depth;
    else
        % 如果未找到邊界框，則設置為 NaN
        results{i, 1} = imageFiles(i).name;
        results{i, 2} = NaN;
        results{i, 3} = NaN;
        results{i, 4} = NaN;
    end

    % 顯示進度
    fprintf('Processed %s\n', imageFiles(i).name);
end

% 確保結果變數的格式正確
results = [results; cell(length(imageFiles), 4)]; % 確保results的列數正確

% 將結果轉換為表格並顯示
resultsTable = cell2table(results, 'VariableNames', {'FileName', 'Width_mm', 'Height_mm', 'Depth_mm'});
disp(resultsTable);

% 將結果保存為CSV文件
writetable(resultsTable, 'MRI_BoneMeasurements.csv');
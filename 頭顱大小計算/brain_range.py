import SimpleITK as sitk

# 讀取MRI影像
image = sitk.ReadImage('s0007986-0005-00001-000027-01.nii')

# 使用閾值分割顱骨（假設顱骨的密度範圍為閾值內）
# 請根據實際情況調整這些閾值
lower_threshold = 200
upper_threshold = 1000
bone_mask = sitk.BinaryThreshold(image, lower_threshold, upper_threshold)

# 計算顱骨的邊界框
label_shape_filter = sitk.LabelShapeStatisticsImageFilter()
label_shape_filter.Execute(bone_mask)
bounding_box = label_shape_filter.GetBoundingBox(1)  # 假設顱骨標籤為1

# 獲取影像像素間距
spacing = image.GetSpacing()

# 計算顱骨的實際尺寸
width = bounding_box[3] * spacing[0]
height = bounding_box[4] * spacing[1]
depth = bounding_box[5] * spacing[2]

print(f'顱骨長: {width} mm, 顱骨寬: {height} mm, 顱骨高: {depth} mm')
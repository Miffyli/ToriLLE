-- screenshot (string filename, [number filetype])

-- USE: Takes a screenshot
-- NOTES: -

echo ("saving screenshots into the screenshots folder") 
-- 0 for BMP
screenshot("sh.bmp", 0)
-- 1 for PPM
screenshot("sh.ppm", 1)
-- Default is BMP
screenshot("sh2.bmp")

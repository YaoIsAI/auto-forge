const sharp = require('sharp');
const path = require('path');

const svgPath = path.join(__dirname, 'cover.svg');
const pngPath = path.join(__dirname, 'cover.png');

sharp(svgPath)
  .resize(900, 383)
  .png()
  .toFile(pngPath)
  .then(() => {
    console.log('转换成功！');
    console.log('PNG 文件已保存到:', pngPath);
  })
  .catch(err => {
    console.error('转换失败:', err);
  });

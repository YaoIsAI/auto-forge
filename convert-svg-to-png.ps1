# SVG to PNG 转换脚本
# 使用 Windows 内置功能

$svgPath = "C:\Users\yao\Desktop\openclaw\projects\auto-forge\cover.svg"
$pngPath = "C:\Users\yao\Desktop\openclaw\projects\auto-forge\cover.png"

# 方法：使用 .NET 的 System.Drawing
Add-Type -AssemblyName System.Drawing

# 读取 SVG
$svgContent = Get-Content $svgPath -Raw

# 创建临时 HTML 文件用于渲染
$tempHtml = [System.IO.Path]::GetTempFileName() + ".html"
$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<style>
  body { margin: 0; padding: 0; }
  svg { display: block; }
</style>
</head>
<body>
$svgContent
</body>
</html>
"@

Set-Content -Path $tempHtml -Value $htmlContent -Encoding UTF8

Write-Host "SVG 文件已准备好: $svgPath"
Write-Host "PNG 文件将保存到: $pngPath"
Write-Host ""
Write-Host "请使用以下方法之一转换为 PNG:"
Write-Host "1. 打开 cover.svg，使用截图工具截图"
Write-Host "2. 访问 https://convertio.co/svg-png/ 在线转换"
Write-Host "3. 安装 Inkscape: scoop install inkscape"
Write-Host "   然后运行: inkscape cover.svg --export-type=png --export-filename=cover.png"

# 清理临时文件
Remove-Item $tempHtml -Force -ErrorAction SilentlyContinue

use anyhow::{Context, Result};
use image::ImageReader;
use image::{GenericImageView, DynamicImage}; // 引入 GenericImageView
use image::imageops::FilterType; // 引入滤镜类型
use std::io::Cursor;
use std::fs;

// 引入你的库
use pix2svg::{convert_image_to_svg, ConversionOptions};

pub struct FlutterConversionOptions {
    pub scale: u32,
    pub alpha_threshold: u8,
    pub crisp_edges: bool,
    // 新增一个选项：是否自动缩小大图
    pub auto_resize: bool, 
}

impl Default for FlutterConversionOptions {
    fn default() -> Self {
        Self {
            scale: 1,
            alpha_threshold: 1,
            crisp_edges: true,
            auto_resize: true, // 默认开启
        }
    }
}

pub fn convert_pixels_to_svg_file(
    image_bytes: Vec<u8>, 
    output_path: String, 
    options: Option<FlutterConversionOptions>
) -> Result<String> {
    let opts = options.unwrap_or_default();
    
    // 1. 解码图片
    let mut img = ImageReader::new(Cursor::new(image_bytes))
        .with_guessed_format()
        .context("无法识别图像格式")?
        .decode()
        .context("图像解码失败")?;

    // 2. 【关键修复】预处理：如果图片太大，强制缩小
    // pix2svg 适合处理 64x64, 128x128 这种级别的图。
    // 如果给它 4000x3000 的图，必须缩小，否则 SVG 必定爆炸。
    if opts.auto_resize {
        let (width, height) = img.dimensions();
        let max_dimension = 256; // 设置一个合理的上限，例如 256 像素

        if width > max_dimension || height > max_dimension {
            // 使用 Nearest (最近邻) 算法进行缩放。
            // 这一点至关重要！其他的算法（如 Linear/Lanczos）会产生抗锯齿模糊，
            // 导致产生成千上万种新颜色，反而让 SVG 变得更复杂。
            // Nearest 能保持“像素风”的硬边缘，最适合 pix2svg。
            img = img.resize(max_dimension, max_dimension, FilterType::Nearest);
        }
    }

    // 3. 配置 pix2svg 选项
    let lib_options = ConversionOptions {
        // 如果我们缩小了图片，可能需要调整输出的 scale 让它显示时看起来还是大的
        scale: opts.scale, 
        alpha_threshold: opts.alpha_threshold,
        skip_transparent: true, 
        crisp_edges: opts.crisp_edges,
    };

    // 4. 执行转换
    let result = convert_image_to_svg(&img, lib_options)
        .map_err(|e| anyhow::anyhow!("SVG 转换错误: {}", e))?;

    // 5. 写入文件
    fs::write(&output_path, result.svg_content)
        .context("无法写入 SVG 文件")?;

    Ok(output_path)
}
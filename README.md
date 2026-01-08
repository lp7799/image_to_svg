# image_to_svg

A Rust-based Flutter plugin that converts bitmap images (PNG/JPG) into scalable SVG vectors. Built with `flutter_rust_bridge`, it provides high-performance vectorization suitable for pixel art, simplified vector previews, and graphic design tools.

## Features

- **Bitmap to SVG**: Converts raster images into SVG paths.
- **Configurable**: Supports scale, alpha threshold, and crisp edges options.
- **Cross-Platform**: Full support for Android, iOS, macOS, Windows, and Linux.
- **High Performance**: Powered by Rust for efficient image processing.

## Prerequisites

To use this plugin, you must have the Rust toolchain installed on your development machine.

1. **Install Rust**:
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf [https://sh.rustup.rs](https://sh.rustup.rs) | sh
   rustup default stable
   
## 安装要求

- Rust（必须）：使用 rustup 安装稳定工具链

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup default stable
```

- Flutter SDK
- 平台依赖
  - Android：Android SDK + NDK（Gradle 会自动拉取并构建）
  - iOS/macOS：Xcode（通过 CocoaPods 集成）
  - Windows/Linux：CMake（由 Flutter 构建系统驱动）

## 快速开始

1. 初始化 FRB

```dart
import 'package:image_to_svg/image_to_svg.dart';

Future<void> main() async {
  await RustLib.init();
  // ...
}
```

2. 调用转换 API（Dart）

```dart
import 'dart:io';
import 'package:image_to_svg/image_to_svg.dart';
import 'package:path_provider/path_provider.dart';

Future<String> convertToSvg(File input) async {
  final bytes = await input.readAsBytes();
  final dir = await getTemporaryDirectory();
  final out = '${dir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.svg';
  final resultPath = await convertPixelsToSvgFile(
    imageBytes: bytes,
    outputPath: out,
    options: FlutterConversionOptions(
      scale: 1,
      alphaThreshold: 1,
      crispEdges: true,
      autoResize: true,
    ),
  );
  return resultPath; // 返回生成的 SVG 文件路径
}
```

3. 在界面中展示（示例工程已集成 `flutter_svg`）

示例应用代码参考：[main.dart](file:///Users/yk/Documents/rust_model/image_to_svg/example/lib/main.dart)

## API 说明（Dart）

- 函数：`convertPixelsToSvgFile({ required List<int> imageBytes, required String outputPath, FlutterConversionOptions? options }) -> Future<String>`
  - 入参：
    - `imageBytes`：输入图片的字节（PNG/JPG 等）
    - `outputPath`：输出 SVG 文件路径
    - `options`：可选配置
  - 返回：生成的 SVG 文件路径（String）

- `FlutterConversionOptions`
  - `scale`：输出 SVG 的缩放倍数（整数）
  - `alphaThreshold`：透明度阈值（0–255），低于该值视为透明
  - `crispEdges`：是否启用硬边缘渲染，避免抗锯齿导致颜色泛化
  - `autoResize`：是否自动缩小过大的图片（内部使用最近邻缩放，最大边默认 256）

API 源码参考：
- Dart 封装：[image_to_svg.dart](file:///Users/yk/Documents/rust_model/image_to_svg/lib/src/rust/api/image_to_svg.dart)
- Rust 实现：[image_to_svg.rs](file:///Users/yk/Documents/rust_model/image_to_svg/rust/src/api/image_to_svg.rs)

## 使用建议

- 大尺寸位图（如 4000×3000）在矢量化时会产生巨量路径与颜色块，SVG 体积和渲染复杂度会急剧上升。默认开启 `autoResize`，将图片最大边缩到 256，并使用最近邻缩放以保留像素硬边。
- 适合场景：像素风图标、简化渲染的矢量预览、低分辨率图形的矢量化。

## 示例应用

- 位置：`example/`
- 主要逻辑：图片选择、参数调整（scale/alphaThreshold）、SVG 预览
- 入口示例：[main.dart](file:///Users/yk/Documents/rust_model/image_to_svg/example/lib/main.dart)

## 平台构建与集成说明

该插件通过 Flutter 的构建系统与 flutter_rust_bridge 自动编译并打包原生库：

- Android：Gradle + NDK（配置见项目 `android/`）
- iOS/macOS：CocoaPods（见 [image_to_svg.podspec](file:///Users/yk/Documents/rust_model/image_to_svg/ios/image_to_svg.podspec) 与 [macOS podspec](file:///Users/yk/Documents/rust_model/image_to_svg/macos/image_to_svg.podspec)）
- Windows/Linux：CMake（见 [linux/CMakeLists.txt](file:///Users/yk/Documents/rust_model/image_to_svg/linux/CMakeLists.txt) 与 [windows/CMakeLists.txt](file:///Users/yk/Documents/rust_model/image_to_svg/windows/CMakeLists.txt)）

默认配置由 FRB 生成代码管理，入口位于：
- [frb_generated.dart](file:///Users/yk/Documents/rust_model/image_to_svg/lib/src/rust/frb_generated.dart)

## 许可

本项目遵循开源许可证，详见 [LICENSE](file:///Users/yk/Documents/rust_model/image_to_svg/LICENSE)。

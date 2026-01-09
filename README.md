
<!-- formatted by Gemini -->
# image_to_svg

A high-performance Flutter plugin that converts bitmap images (PNG/JPG) into scalable SVG vectors using Rust FFI.

Powered by `flutter_rust_bridge`, this plugin leverages the speed and memory safety of Rust to perform computationally intensive vectorization tasks efficiently. It is specifically designed for scenarios requiring pixel art vectorization, simplified vector previews, and graphic design tools where preserving sharp edges and handling transparency is critical. By offloading image processing to native Rust code, it ensures your Flutter UI remains smooth and responsive.

![Demo Image](https://github.com/lp7799/image_to_svg/blob/main/image.jpg?raw=true)

## ✨ Features

-   **Bitmap to SVG Conversion**: Efficiently traces contours and converts raster image data (pixels) into mathematically defined SVG paths.
-   **Highly Configurable**: Offers fine-grained control over the output. You can adjust scaling, set transparency thresholds to remove background noise, and toggle edge detection modes.
-   **Cross-Platform Support**: Works seamlessly across all major Flutter platforms including Android, iOS, macOS, Windows, and Linux, with no platform-specific code required on your end.
-   **High Performance**: Built on a robust Rust backend, allowing for fast processing of image data without the garbage collection overhead typical of managed languages.

## 🚀 Prerequisites

To use this plugin, your development environment must be set up to compile the underlying Rust code.

**Install the Rust Toolchain:**
This plugin relies on the standard Rust compiler. Install it via `rustup` to ensure you have the latest stable version.

```shell
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
rustup default stable
```

**Platform-Specific Requirements:**

-   **Android**: Requires the Android SDK & NDK. These are usually handled automatically by Gradle during the build process.
-   **iOS/macOS**: Requires Xcode. The native pods will be handled by CocoaPods.
-   **Windows/Linux**: Requires CMake and a C++ compiler (like Visual Studio or GCC), which are driven by the standard Flutter build system.

## 📦 Installation

Add `image_to_svg` to your project's `pubspec.yaml` file:

```yaml
dependencies:
  image_to_svg: ^0.0.2
```

Then run `flutter pub get` to install the package.

## 🎯 Quick Start

### 1. Initialize the Library

Before making any calls to the plugin, you must initialize the Rust-Dart bridge. This sets up the FFI bindings and ensures the native library is loaded correctly. A good place to do this is in your `main` function.

```dart
import 'package:image_to_svg/image_to_svg.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the Rust-Dart bridge
  await RustLib.init();

  runApp(const MyApp());
}
```

### 2. Convert an Image

Use the `convertPixelsToSvgFile` function to process an image. The following example demonstrates how to read a file, convert it, and handle potential errors.

```dart
import 'dart:io';
import 'package:image_to_svg/image_to_svg.dart';
import 'package:path_provider/path_provider.dart';

Future<String?> convertToSvg(File inputImage) async {
  try {
    // 1. Read image bytes
    // Ensure the file exists and is readable before proceeding
    final bytes = await inputImage.readAsBytes();

    // 2. Prepare output path
    // We use the temporary directory to avoid cluttering user storage
    final tempDir = await getTemporaryDirectory();
    final outputPath = '${tempDir.path}/converted_image_${DateTime.now().millisecondsSinceEpoch}.svg';

    // 3. Convert
    // This operation runs asynchronously on a native thread
    final svgFilePath = await convertPixelsToSvgFile(
      imageBytes: bytes,
      outputPath: outputPath,
      options: const FlutterConversionOptions(
        scale: 1,            // Keeps the SVG viewbox same size as pixel dimensions
        alphaThreshold: 10,  // Ignores near-transparent pixels (0-10 alpha)
        crispEdges: true,    // Forces sharp corners, ideal for logos/pixel art
        autoResize: true,    // Downscales massive images to prevent crashes
      ),
    );
    
    // Returns the absolute path to the generated SVG file
    return svgFilePath; 
  } catch (e) {
    print('Error converting image to SVG: $e');
    return null;
  }
}
```

## 📚 API Reference

### `convertPixelsToSvgFile`

The main entry point for conversion. This method is asynchronous and executes the heavy lifting in Rust to prevent blocking the Flutter UI thread.

| Parameter | Type | Description |
|---|---|---|
| `imageBytes` | `List<int>` | The raw binary data of the input image. Supported formats include PNG, JPEG, GIF, and WebP. |
| `outputPath` | `String` | The absolute filesystem path where the generated SVG string will be written. Ensure the app has write permissions to this location. |
| `options` | `FlutterConversionOptions?` | (Optional) A configuration object to tune the vectorization algorithm. If `null`, default settings are used. |

### `FlutterConversionOptions`

This class controls the behavior of the vectorization algorithm.

-   **`scale`** (`int`, default: `1`):
    Multiplies the dimensions of the output SVG. For example, a `scale` of `2` will make the SVG `viewBox` twice as large as the input image resolution.

-   **`alphaThreshold`** (`int`, default: `0`):
    Defines the transparency cutoff. Pixels with an alpha value lower than this (0-255) will be treated as fully transparent. This is useful for cleaning up "dirty" alpha channels or removing faint background noise.

-   **`crispEdges`** (`bool`, default: `true`):
    Determines the tracing style.
    -   `true`: The algorithm preserves pixel corners, resulting in a blocky, "pixel-perfect" look. This is ideal for pixel art, QR codes, or technical diagrams.
    -   `false`: The algorithm may attempt to smooth curves or corners, which can be better for organic shapes or photographs (depending on implementation specifics).

-   **`autoResize`** (`bool`, default: `true`):
    A safety mechanism for performance. If `true`, input images larger than `256px` on their longest side are automatically downscaled using "Nearest Neighbor" interpolation before processing.
    **Why?** Vectorizing a 4K photo creates millions of individual paths, which can consume gigabytes of RAM and crash the SVG rendering engine. This option ensures the output remains usable.

## ⚡️ Performance Tips

-   **Image Resolution vs. Complexity**: The processing time is not just dependent on image resolution, but on complexity. A 1000x1000 image of a single color processes instantly, while a 1000x1000 photo with noise will take much longer.
-   **Avoid High-Res Photos**: Vectorizing high-resolution photos (e.g., > 1000px) is generally not recommended for this type of algorithm. It generates massive SVG files (tens of MBs) that are slow to parse and render. Always keep `autoResize` enabled or manually resize images to a manageable size (e.g., < 512px) before conversion.
-   **Optimizing for Pixel Art**: This tool shines with pixel art or icons. Ensure `crispEdges` is set to `true` and `alphaThreshold` is tuned (e.g., 1-10) to get the cleanest vector output.

## Example

Check the `example/` directory in the repository for a complete sample application. The example includes:
-   Picking an image from the system gallery.
-   A UI to adjust conversion parameters dynamically.
-   Side-by-side comparison of the original bitmap and the generated SVG.

## 📄 License

This project is licensed under the MIT License - see the `LICENSE` file for details.

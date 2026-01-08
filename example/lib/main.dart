import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_to_svg/image_to_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  XFile? _imageFile;
  File? _svgFile;
  bool _isConverting = false;
  int _scale = 1;
  int _alphaThreshold = 1;
  int _svgVersion = 0;
  Future<void> _reconvertIfPossible() async {
    if (_imageFile == null || _isConverting) return;
    final bytes = await _imageFile!.readAsBytes();
    setState(() => _isConverting = true);
    final tempDir = await getTemporaryDirectory();
    final tempPath =
        '${tempDir.path}/converted_image_${DateTime.now().millisecondsSinceEpoch}.svg';
    final sw = Stopwatch()..start();
    final result = await convertPixelsToSvgFile(
      imageBytes: bytes,
      outputPath: tempPath,
      options: FlutterConversionOptions(
        scale: _scale,
        alphaThreshold: _alphaThreshold,
        crispEdges: true,
        autoResize: true,
      ),
    );
    sw.stop();
    print('SVG转换耗时：${sw.elapsedMilliseconds} ms，文件：$result');
    setState(() {
      _svgFile = File(result);
      _isConverting = false;
      _svgVersion++;
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (_isConverting) return;
            try {
              final image = await ImagePicker().pickImage(
                source: ImageSource.gallery,
              );
              if (image == null) return;
              setState(() => _imageFile = image);
              final bytes = await image.readAsBytes();
              setState(() => _isConverting = true);
              final tempDir = await getTemporaryDirectory();
              final tempPath =
                  '${tempDir.path}/converted_image_${DateTime.now().millisecondsSinceEpoch}.svg';
              final sw = Stopwatch()..start();
              final result = await convertPixelsToSvgFile(
                imageBytes: bytes,
                outputPath: tempPath,
                options: FlutterConversionOptions(
                  scale: _scale,
                  alphaThreshold: _alphaThreshold,
                  crispEdges: true,
                  autoResize: true,
                ),
              );
              sw.stop();
              print('SVG转换耗时：${sw.elapsedMilliseconds} ms，文件：$result');
              setState(() {
                _svgFile = File(result);
                _isConverting = false;
                _svgVersion++;
              });
            } catch (e) {
              if (!mounted) return;
              setState(() => _isConverting = false);

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('图片选择或转换失败：$e')));
            }
          },
          child: const Icon(Icons.add),
        ),
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final paramsSection = Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '参数',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('Scale'), Text('$_scale')],
                    ),
                    Slider(
                      value: _scale.toDouble(),
                      min: 1,
                      max: 8,
                      divisions: 7,
                      label: '$_scale',
                      onChanged: (v) => setState(() => _scale = v.round()),
                      onChangeEnd: (_) => _reconvertIfPossible(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Alpha Threshold'),
                        Text('$_alphaThreshold'),
                      ],
                    ),
                    Slider(
                      value: _alphaThreshold.toDouble(),
                      min: 0,
                      max: 255,
                      divisions: 255,
                      label: '$_alphaThreshold',
                      onChanged: (v) =>
                          setState(() => _alphaThreshold = v.round()),
                      onChangeEnd: (_) => _reconvertIfPossible(),
                    ),
                  ],
                ),
              ),
            );
            final originalSection = Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '原图',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 260,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: _imageFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: InteractiveViewer(
                                child: Image.file(
                                  File(_imageFile!.path),
                                  fit: BoxFit.contain,
                                ),
                              ),
                            )
                          : const Center(child: Text('未选择照片')),
                    ),
                  ],
                ),
              ),
            );
            final svgSection = Card(
              margin: const EdgeInsets.all(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SVG预览',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 260,
                      width: double.infinity,
                      color: Colors.grey.shade200,
                      child: _svgFile != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SvgPicture.file(
                                _svgFile!,
                                key: ValueKey(
                                  'svg-${_svgVersion}-${_svgFile?.path}',
                                ),
                                fit: BoxFit.contain,
                                allowDrawingOutsideViewBox: true,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrintStack(
                                    stackTrace: stackTrace,
                                    label: 'SVG加载失败$error',
                                  );
                                  return Center(child: Text('SVG加载失败${error}'));
                                },
                              ),
                            )
                          : (_isConverting
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : const Center(child: Text('尚未生成SVG'))),
                    ),
                  ],
                ),
              ),
            );
            if (isWide) {
              return Row(
                children: [
                  Expanded(child: paramsSection),
                  Expanded(child: originalSection),
                  Expanded(child: svgSection),
                ],
              );
            } else {
              return ListView(
                children: [paramsSection, originalSection, svgSection],
              );
            }
          },
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'scan_preview_controller.dart';

class ScanPreviewWidget extends StatefulWidget {

  final ValueChanged<String>? onScanResult;
  final int laserColor;
  final int borderColor;
  final void Function(ScanPreviewController controller)? onCreate;

  ScanPreviewWidget(
      {this.laserColor = 0xFF00FF00,
      this.borderColor = 0xFFFFFFFF,
      @required this.onScanResult, this.onCreate});

  @override
  ScanPreviewWidgetState createState() => ScanPreviewWidgetState();
}

class ScanPreviewWidgetState extends State<ScanPreviewWidget>
    with WidgetsBindingObserver {
  ScanPreviewController? _controller;
  final BasicMessageChannel _messageChannel =
  BasicMessageChannel("scan_preview_message", StandardMessageCodec());

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageChannel.setMessageHandler(_messageHandler);
  }

  Future<dynamic> _messageHandler(dynamic message) async {
    widget.onScanResult!(message.toString());
    _controller?.stopCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
    _controller?.stopCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed) {
      _controller?.startCamera();
    } else if (state == AppLifecycleState.paused) {
      _controller?.stopCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return _init();
  }

  Widget _init() {
    final Map<String, dynamic> creationParams = <String, dynamic>{
      // 其他参数
      'laserColor': widget.laserColor,
      'borderColor': widget.borderColor
    };
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidView(
        viewType: 'scan_preview',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: onPlatformViewCreated,
      );
    } else {
      return UiKitView(
        viewType: 'scan_preview',
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: onPlatformViewCreated,
      );
    }
  }

  Future<void> onPlatformViewCreated(int id) async {
    await Future.delayed(Duration(milliseconds: 300));
    _controller = await ScanPreviewController.init(id, this);
    if(widget.onCreate != null) widget.onCreate!(_controller!);
    _controller!.startCamera();
  }
}
import 'package:audio_session/audio_session.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AudioDeviceService {
  final _controller = StreamController<bool>.broadcast();
  Stream<bool> get bluetoothStream => _controller.stream;
  
  bool _isBluetoothConnected = false;
  bool get isBluetoothConnected => _isBluetoothConnected;

  Future<void> init() async {
    final session = await AudioSession.instance;
    
    // 現在の状態を確認
    await _updateStatus(session);

    // 変更を監視
    session.devicesStream.listen((devices) async {
      await _updateStatus(session);
    });
  }

  Future<void> _updateStatus(AudioSession session) async {
    final devices = await session.getDevices();
    bool found = false;
    for (var device in devices) {
      if (device.type == AudioDeviceType.bluetoothA2dp ||
          device.type == AudioDeviceType.bluetoothSco ||
          device.type == AudioDeviceType.bluetoothLe) {
        found = true;
        break;
      }
    }
    
    if (_isBluetoothConnected != found) {
      _isBluetoothConnected = found;
      _controller.add(_isBluetoothConnected);
      debugPrint('Bluetooth connection status changed: $_isBluetoothConnected');
    }
  }

  void dispose() {
    _controller.close();
  }
}

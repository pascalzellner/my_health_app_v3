import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

final btleDeviceProvider  = StateNotifierProvider<BtleDevicesNotifier, List<BluetoothDevice>>((ref) => BtleDevicesNotifier());


class BtleDevicesNotifier extends StateNotifier<List<BluetoothDevice>> {
  BtleDevicesNotifier() : super([]){
    _checkPermissionsAndScan();
}

void _checkPermissionsAndScan() async {
    if (await _requestPermissions()) {
      _scanForDevices();
    } else {
      // Handle the case where permissions are not granted
    }
}

Future<bool> _requestPermissions() async {
  final status = await [
    Permission.bluetooth,
    Permission.bluetoothScan,
    Permission.bluetoothConnect,
    Permission.location,
  ].request();
   return status.values.every((status) => status.isGranted);
}

  void _scanForDevices() async {
    await FlutterBluePlus.startScan(withServices: [Guid('0000180d-0000-1000-8000-00805f9b34fb')]);
    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        if (!state.any((d) => d.remoteId == result.device.remoteId)) {
          state = [...state, result.device];
      }
      }
    });
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
    print('btleDevicesNotifier disposed');
  }

  void refresh() {
    state = [];
    _checkPermissionsAndScan();
  }
}
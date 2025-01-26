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
    //await FlutterBluePlus.startScan();//scan all devices
    await FlutterBluePlus.startScan(withServices: [Guid('0000180d-0000-1000-8000-00805f9b34fb')]);//scab only devices with heart rate service
    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult result in results) {
        if (!state.any((d) => d.remoteId == result.device.remoteId)) {
          state = [...state, result.device];//add the device to the list
      }
      }
    });
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();//stop the scan before disposing the notifier
    super.dispose();
  }

  void refresh() {//to refresh the list of devices
    state = [];
    _checkPermissionsAndScan();
  }
}
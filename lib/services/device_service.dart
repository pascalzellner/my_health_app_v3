import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final deviceServiceProvider = Provider.family<DeviceService, BluetoothDevice>((ref, device) {
  return DeviceService(device: device);
});

class DeviceService {
  
  final BluetoothDevice device;
  final StreamController<int> _hrDataStreamController = StreamController<int>.broadcast();
  final StreamController<int> _rrDataStreamController = StreamController<int>.broadcast();

  bool is16Bit = false;
  bool rrAvailable = false;

  Stream<int> get hrDataStream => _hrDataStreamController.stream;
  Stream<int> get rrDataStream => _rrDataStreamController.stream;

  DeviceService({required this.device});

  Future<void> connect() async {
    await device.connect();
  }
  
   Future<void> disconnect() async {
    await device.disconnect();
  }

  Future<bool> isConnect() async {
    return device.isConnected;
  }

  Future<void> beginReadHRInfo() async {
    if(!device.isConnected){
      await device.connect();
    }
    final services = await device.discoverServices();
    final hrService = services.firstWhere((service) => service.uuid == Guid('0000180d-0000-1000-8000-00805f9b34fb'));
    final hrChar = hrService.characteristics.firstWhere((char) => char.uuid == Guid('00002a37-0000-1000-8000-00805f9b34fb'));
    await Future.delayed(Duration(seconds: 2));
    await hrChar.setNotifyValue(true);//on active la notification
    hrChar.lastValueStream.listen((value) async {
    print('NOUVELLE VALEUR: $value');
    //on va décoder le paquet
    int heartRate = 0;
    if(value.isNotEmpty){ 
      final flag = value[0];
      is16Bit = (flag & 0x01) != 0;
      rrAvailable = (flag & 0x02) != 0;
      int index = 1;
        if (is16Bit){
          heartRate = value[index] | (value[index + 1] << 8);
          index += 2;
        }else{
          heartRate = value[index];
          index +=1;
        }
        _hrDataStreamController.add(heartRate);
        if(rrAvailable){//si les RRIntervals sont disponibles
          while (index + 1 < value.length) {//tant qu'il reste des octes à lire
          final rrInterval = (value[index] | (value[index + 1] << 8)) / 1024 * 1000; // Convert to milliseconds
          _rrDataStreamController.add(rrInterval.toInt());//on ajoute les RRIntervals
          index += 2;//on passe au deux octets suivants
          }
        }
    }
    });
  }

  bool is16BitHR(){
    return is16Bit;
  }

  bool isRRIntervalsAvailable(){
    return rrAvailable;
  }

  Future<void> stopReadHRInfo() async {
    final services = await device.discoverServices();
    final hrService = services.firstWhere((service) => service.uuid == Guid('0000180d-0000-1000-8000-00805f9b34fb'));
    final hrChar = hrService.characteristics.firstWhere((char) => char.uuid == Guid('00002a37-0000-1000-8000-00805f9b34fb'));
    await hrChar.setNotifyValue(false);
    _hrDataStreamController.add(0);
    _hrDataStreamController.close();
    _rrDataStreamController.add(0);
    _rrDataStreamController.close();
    print('NOTIFYVALUE EST DÉSACTIVÉ ET STREAM RÉINITIALISÉ');
  }

}


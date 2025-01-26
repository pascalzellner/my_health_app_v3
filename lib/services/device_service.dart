import 'dart:async';
import 'dart:ffi';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deviceServiceProvider = Provider.family<DeviceService, BluetoothDevice>((ref, device) {
  return DeviceService(device: device);
});

class DeviceService {
  
  final BluetoothDevice device;
  final StreamController<int> _hrDataStreamController = StreamController<int>.broadcast();
  final StreamController<int> _rrDataStreamController = StreamController<int>.broadcast();
  final StreamController<int> _energyExpendedStreamController = StreamController<int>.broadcast();
  final StreamController<int> _contactDetectedStreamController = StreamController<int>.broadcast();
  final StreamController<int> _isContactSupportedStreamController = StreamController<int>.broadcast();
  final StreamController<int> _isrrAvailableStreamController = StreamController<int>.broadcast();
  final StreamController<int> _isEnergyExpendedStreamController = StreamController<int>.broadcast();

  bool is16Bit = false;
  bool rrAvailable = false;
  bool energyExpendedPresent = false;
  bool iscontactSupported = false;
  bool contactValue = false;

  Stream<int> get hrDataStream => _hrDataStreamController.stream;
  Stream<int> get rrDataStream => _rrDataStreamController.stream;
  Stream<int> get energyExpendedStream => _energyExpendedStreamController.stream;
  Stream<int> get contactDetectedStream => _contactDetectedStreamController.stream;
  Stream<int> get isContactSupportedStream => _isContactSupportedStreamController.stream;
  Stream<int> get isrrAvailableStream => _isrrAvailableStreamController.stream;
  Stream<int> get isEnergyExpendedStream => _isEnergyExpendedStreamController.stream;

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
    await hrChar.setNotifyValue(true);//active notify value to receive data
    hrChar.lastValueStream.listen((value) async {
    //we will analyse the value to get the heart rate and RRIntervals
    int heartRate;
    if(value.isNotEmpty){ 
      final flag = value[0];//catch the first octet to get the flags
      is16Bit = (flag & 0x01) != 0;//bit 0 flag to know if the heart rate is coded on 16 bits or 8 bits
      rrAvailable = (flag & 0x10) != 0;//bit 4 flag to know if the RRIntervals are available
      iscontactSupported = (flag & 0x04) != 0;//bit 2 flag to know if the contact is supported
      contactValue = (flag & 0x02) != 0;//bit 1 flag to know if the contact is detected
      energyExpendedPresent = (flag & 0x08) != 0;//bit 3 flag to know if the energy expended is present
      _isrrAvailableStreamController.add(rrAvailable ? 1 : 0);//push rrAvailable to the stream
      _isContactSupportedStreamController.add(iscontactSupported ? 1 : 0);//push iscontactSupported to the stream
      _isEnergyExpendedStreamController.add(energyExpendedPresent ? 1 : 0);//push energyExpendedPresent to the stream
     
      if(iscontactSupported){//if the contact is supported
        _contactDetectedStreamController.add(contactValue ? 1 : 0);//push the contact value to the stream
      }
      int index = 1;//first got the heart rate value
        if (is16Bit){//if the heart rate is coded on 16 bits
          heartRate = value[index] | (value[index + 1] << 8);//take the two octets and convert to int
          index += 2;//go to the next octets
        }else{//if the heart rate is coded on 8 bits
          heartRate = value[index];//take the octet and convert to int
          index +=1;//go to the next octet
        }
        _hrDataStreamController.add(heartRate);//push the heart rate to the stream
        //we move foward in the octets packet, if energy expended is present we take the next two octets to get the value
        if(energyExpendedPresent){//if energy expended is present
          int energyExpended = (value[index++] << 8) | value[index++];//take the two octets and convert to int, kJoules
          _energyExpendedStreamController.add(energyExpended);
          index += 2;//go to the next octets
        }
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

  Future<bool> is16BitHR() async {
    return is16Bit;
  }

  Future<void> stopReadHRInfo() async {
    final services = await device.discoverServices();
    final hrService = services.firstWhere((service) => service.uuid == Guid('0000180d-0000-1000-8000-00805f9b34fb'));
    final hrChar = hrService.characteristics.firstWhere((char) => char.uuid == Guid('00002a37-0000-1000-8000-00805f9b34fb'));
    await hrChar.setNotifyValue(false);
    _hrDataStreamController.add(0);
    _rrDataStreamController.add(0);
    _contactDetectedStreamController.add(0);
    _energyExpendedStreamController.add(0);
    _isContactSupportedStreamController.add(0);
  }

  void dispose() {
    _hrDataStreamController.close();
    _rrDataStreamController.close();
    _energyExpendedStreamController.close();
    _contactDetectedStreamController.close();
    _isContactSupportedStreamController.close();
    _isrrAvailableStreamController.close();
    _isEnergyExpendedStreamController.close();
  }

}


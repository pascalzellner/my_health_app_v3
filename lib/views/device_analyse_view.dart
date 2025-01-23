import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_health_app_v3/services/device_service.dart';

class DeviceAnalyseView extends ConsumerStatefulWidget{

  final BluetoothDevice device;

  const DeviceAnalyseView({required this.device, super.key});

  @override
  _DeviceAnalyseViewState createState() => _DeviceAnalyseViewState();
}

class _DeviceAnalyseViewState extends ConsumerState<DeviceAnalyseView>{
  

  bool isConnected = false;//to know if the device is connected
  String info ='Wainting for connection';//to display the information
  bool isRecording = false;//to know if the device is recording

  @override
  void initState(){//to connect to the device & initialize widget state
    super.initState();
    connectToDevice();
  }

  void connectToDevice() async {
    final deviceService = ref.read(deviceServiceProvider(widget.device));
    await deviceService.connect();
    bool result = await deviceService.isConnect();
    setState(() {
      isConnected = result;
      if(isConnected){
        info = 'Connected';
      }
    });
    setState(() {
      info = 'Wainting for sensor data';
    });
    await deviceService.beginReadHRInfo();
    setState(() {
      info = 'Reading data in progress';
      isRecording = true;
    });
  }
  
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Sensor Analysis'),
        backgroundColor: Colors.cyan,
      ),
      body: Center(
        child: Column(children: [
          Text('Device: ${widget.device.platformName}'),
          Text('Connected: $isConnected'),
          Text('Info: $info'),
          SizedBox(height: 20),
          StreamBuilder(//to display the HR value
            stream: ref.read(deviceServiceProvider(widget.device)).hrDataStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('...', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold));
              } else if (snapshot.hasError) {
                return Text('HR Error', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold));
              } else if (snapshot.hasData) {
                final data = snapshot.data as int;
                // Assuming data contains HR value
                return Text('HR: $data', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold));   
              }
              return Text('...');  
            },
          ),
          StreamBuilder(//to display the RR value
            stream: ref.read(deviceServiceProvider(widget.device)).rrDataStream, 
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('...', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold));
              } else if (snapshot.hasError) {
                return Text('RR Error', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold));
              } else if (snapshot.hasData) {
                final data = snapshot.data as int;
                // Assuming data contains RR value
                return Text('RR: $data', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold));   
              }
              return Text('...');  
            },
          ),
          StreamBuilder(
            stream: ref.read(deviceServiceProvider(widget.device)).isrrAvailableStream, 
            builder: (context,snapshot){
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Waiting analysis', style: TextStyle(color: Colors.blueAccent));
              } else if (snapshot.hasError) {
                return Text('Packet Error', style: TextStyle(color: Colors.redAccent));
              } else if (snapshot.hasData) {
                final data = snapshot.data as int;
                // Assuming data contains RR value
                if(data == 1){
                  return Text('RR Available', style: TextStyle(color: Colors.greenAccent));
                }
                else{
                  return Text('RR Not Available', style: TextStyle(color: Colors.redAccent));
                }  
              }
              return Text('..NS..',style: TextStyle(color: Colors.deepOrangeAccent),);
            }
          ),
          SizedBox(height: 20),
          StreamBuilder(
            stream: ref.read(deviceServiceProvider(widget.device)).isContactSupportedStream, 
            builder: (context,snapshot){
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Waiting for data', style: TextStyle(color: Colors.blueAccent));
              } else if (snapshot.hasError) {
                return Text('CS Error', style: TextStyle(color: Colors.redAccent));
              } else if (snapshot.hasData) {
                final data = snapshot.data as int;
                // Assuming data contains contact supported value
                if(data == 1){
                  return Text('Contact Supported', style: TextStyle(color: Colors.greenAccent));
                }
                else{
                  return Text('Contact Not Supported', style: TextStyle(color: Colors.redAccent));
                }  
              }
              return Text('..NS - Contact..',style: TextStyle(color: Colors.deepOrangeAccent),);
            }
          ),
          StreamBuilder(//to display the correct electrode contact (skin or ppg)
            stream: ref.read(deviceServiceProvider(widget.device)).contactDetectedStream, 
            builder: (context,snapshot){
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Waiting for data', style: TextStyle(color: Colors.blueAccent));
              } else if (snapshot.hasError) {
                return Text('CC Error', style: TextStyle(color: Colors.redAccent));
              } else if (snapshot.hasData) {
                final data = snapshot.data as int;
                // Assuming data contains contact detected value
                if(isRecording){
                  if(data == 1){
                    return Text('electrodes connected', style: TextStyle(color: Colors.greenAccent));
                  }
                  else{
                    return Text('electrodes not connected', style: TextStyle(color: Colors.redAccent));
                  }
                }else{
                  return Text('Analysis Stopped', style: TextStyle(color: Colors.lightGreen));
                }  
              }
            return Text('..NS - Electrodes..',style: TextStyle(color: Colors.deepOrangeAccent),);
            },
          ),
          StreamBuilder(
            stream: ref.read(deviceServiceProvider(widget.device)).isEnergyExpendedStream,
            builder: (context,snapshot){
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Waiting for data', style: TextStyle(color: Colors.blueAccent));
              } else if (snapshot.hasError) {
                return Text('EN Error', style: TextStyle(color: Colors.redAccent));
              } else if (snapshot.hasData) {
                final data = snapshot.data as int;
                // Assuming data contains energy expended value
                if(data == 1){
                  return Text('Energy Expended Available', style: TextStyle(color: Colors.greenAccent));
                }
                else{
                  return Text('Energy Expended Not Available', style: TextStyle(color: Colors.redAccent));
                }  
              }
              return Text('..NS - Energy Expended..',style: TextStyle(color: Colors.deepOrangeAccent),);
            }
          ),
          StreamBuilder(
            stream: ref.read(deviceServiceProvider(widget.device)).energyExpendedStream,
            builder: (context,snapshot){
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Text('Waiting for data', style: TextStyle(color: Colors.blueAccent));
              } else if (snapshot.hasError) {
                return Text('EE Error', style: TextStyle(color: Colors.redAccent));
              } else if (snapshot.hasData) {
                final data = snapshot.data as int;
                // Assuming data contains energy expended value
                return Text('Energy Expended: $data', style: TextStyle(color: Colors.greenAccent));
              }
              return Text('..NS - Energy Expended..',style: TextStyle(color: Colors.deepOrangeAccent),);
            }
          ),
          SizedBox(height: 40),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: isRecording? WidgetStateProperty.all(Colors.red):WidgetStateProperty.all(Colors.green)
            ),
            onPressed: (){
              if(isRecording){
                ref.read(deviceServiceProvider(widget.device)).stopReadHRInfo();
                setState(() {
                  isRecording = false;
                  info = 'Stop reading data';
                });
              }else{
                ref.read(deviceServiceProvider(widget.device)).beginReadHRInfo();
                setState(() {
                  isRecording = true;
                  info = 'Reading data in progress';
                });
              }
            }, 
            child: Text(isRecording? 'Stop reading':"Read Data", 
            style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
        ],  
        ),
      ),
    );
  }

  @override
  void dispose(){
    super.dispose();
  }
}
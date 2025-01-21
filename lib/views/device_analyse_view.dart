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
  

  bool isConnected = false;
  String info ='Attente de connexion';
  bool isRecording = false;

  @override
  void initState(){
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
        info = 'Connexion établie';
      }
    });
    setState(() {
      info = 'Attente des données du capteur';
    });
    await deviceService.beginReadHRInfo();
    setState(() {
      info = 'Lecture des données en cours';
      isRecording = true;
    });
  }

  
  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text('Analyse du device'),
        backgroundColor: Colors.cyan,
      ),
      body: Center(
        child: Column(children: [
          Text('Device: ${widget.device.platformName}'),
          Text('Connected: $isConnected'),
          Text('Info: $info'),
          SizedBox(height: 20),
          StreamBuilder(
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
          StreamBuilder(
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
          SizedBox(height: 40),
          FilledButton(
            style: ButtonStyle(
              backgroundColor: isRecording? WidgetStateProperty.all(Colors.red):WidgetStateProperty.all(Colors.green)
            ),
            onPressed: (){
              if(isRecording){
                ref.read(deviceServiceProvider(widget.device)).disconnect();
                setState(() {
                  isRecording = false;
                  info = 'Arrêt de la lecture des données';
                });
              }else{
                ref.read(deviceServiceProvider(widget.device)).beginReadHRInfo();
                setState(() {
                  isRecording = true;
                  info = 'Lecture des données en cours';
                });
              }
            }, 
            child: Text(isRecording? 'Arrêter':"Lecture", 
            style: TextStyle(fontSize: 20, color: Colors.white)),
            ),
        ],  
        ),
      ),
    );
  }
}
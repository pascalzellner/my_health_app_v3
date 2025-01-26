import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_health_app_v3/providers/btle_provider.dart';
import 'package:my_health_app_v3/views/device_analyse_view.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ayur Health App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.cyan),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends ConsumerWidget {
  
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final btleDevices = ref.watch(btleDeviceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('HR Devices List',style: TextStyle(color:Colors.white),),
        backgroundColor: Colors.cyan,
      ),
      body: ListView.builder(
        itemCount: btleDevices.length,
        itemBuilder: (context,index){
          final device = btleDevices[index];
          return ListTile(
            title: Text(device.platformName),
            subtitle: Text(device.remoteId.toString()),
            trailing: IconButton(
              onPressed: ()async{
                Navigator.push(context, MaterialPageRoute(builder: (context)=>DeviceAnalyseView(device: device))).then((value) async {
                  await device.disconnect();
                });
              }, 
              icon: const Icon(Icons.connect_without_contact,color: Colors.deepOrange,)
            ),
          );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          ref.read(btleDeviceProvider.notifier).refresh();
        },
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
     
    );
  }
}
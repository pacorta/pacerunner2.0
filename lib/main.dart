import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'The Pacerunner Home Screen'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(30),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/pacerunner.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 250),
              const Text(
                'You have pushed the button this many times:',
              ),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              FloatingActionButton(
                onPressed: _incrementCounter,
                tooltip: 'Increment',
                child: const Icon(Icons.add),
              ),
              const SizedBox(height: 80),
              ElevatedButton(
                  child: const Text('Click to Start Running'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ThirdScreen()),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}



class ThirdScreen extends StatelessWidget {
  const ThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Current Run'),
        backgroundColor: Colors.teal,
      ),
      body: Center(
        child: Column(
          children: [
            const SizedBox(
              height: 300,
              child: Map(),
            ),
            OverflowBar(
              alignment: MainAxisAlignment.start,
              children: <Widget>[
                TextButton(
                    child: const Text('Home Screen'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Map()),
                      );
                    }),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AboutScreen(tag: 'visca')), // HERO
                    );
                  },
                  child: Hero( // HERO
                    tag: 'visca', // Use the tag // HERO
                    child: Image.asset(
                      'images/FCB.png',
                      width: 50, // Set the desired width
                      height: 50, // Set the desired height
                    ),
                  ),
                ),
                const MyButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class AboutScreen extends StatelessWidget {
  final String tag;                                   //HERO
  const AboutScreen({required this.tag, super.key});  //HERO

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: const Text('About Page'),
      ),
      body: Center(
        child: Hero(
          tag: tag,                                     //HERO
          child: Image.asset('images/FCB.png'),
        ),
      ),
    );
  }
}

class MyButton extends StatelessWidget {
  const MyButton({super.key});

  @override
  Widget build(BuildContext context) {
    // The GestureDetector wraps the button.
    return GestureDetector(
      // When the child is tapped, show a snackbar.
      onTap: () {
        const snackBar = SnackBar(content: Text('Cosquillas'));

        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      },
      // The custom button
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.lightBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('My Button'),
      ),
    );
  }
}



void gmaps() => runApp(const Map());

class Map extends StatefulWidget {
  const Map({super.key});

  @override
  State<Map> createState() => _MapState();
}

class _MapState extends State<Map> {
  late GoogleMapController mapController;           //will be declared later
  final Location location = Location();             //unmutable
  LatLng _currentPosition = const LatLng(0, 0);
  bool _locationObtained = false;

  double _currentSpeed = 0.0;

  @override
    void initState() {
      super.initState();
      _getCurrentLocation();
      print("initState Called");
    }


  void _onMapCreated(GoogleMapController controller) {
      print("_onMapCreated called");
      mapController = controller;
    }

    Future<void> _getCurrentLocation() async {
      print("_getCurrentLocation called");
      bool serviceEnabled;
      PermissionStatus permissionGranted;

      serviceEnabled = await location.serviceEnabled();
      print("Service enabled: $serviceEnabled");
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        print("Service enabled after request: $serviceEnabled");
        if (!serviceEnabled) {
          return;
        }
      }

      permissionGranted = await location.hasPermission();
      print("Permission granted: $permissionGranted");
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        print("Permission granted after request: $permissionGranted");
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      try {
            final locationData = await location.getLocation();
            print("Location data: ${locationData.latitude}, ${locationData.longitude}"); // Log entry
            print("Accuracy: ${locationData.accuracy}, Altitude: ${locationData.altitude}"); // More details
            print('Current speed: ${locationData.speed} m/s');
            setState(() {
              _currentPosition = LatLng(locationData.latitude!, locationData.longitude!);
              _locationObtained = true;
            });
          } catch (e) {
            print("Error getting location: $e"); // Log entry
          }

      // Set up a listener for location changes
      location.onLocationChanged.listen((LocationData currentLocation) {
        print("Location updated: ${currentLocation.latitude}, ${currentLocation.longitude}, Speed: ${currentLocation.speed} m/s"); // Log entry
        setState(() {
          _currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _currentSpeed = currentLocation.speed!;
        });
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _currentPosition, zoom: 20),
          ),
        );
      });
    }

    @override
    Widget build(BuildContext context) {
      print("Build method called"); // Log entry
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(
                  backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                  title: Text('speed: ${_currentSpeed} m/s'),
                ),
          body: _locationObtained
              ? GoogleMap(
                  onMapCreated: _onMapCreated,
                  mapType: MapType.hybrid,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 15.0,
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

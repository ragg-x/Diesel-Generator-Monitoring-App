import 'package:flutter/material.dart';
import 'mqtt_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  MqttService _mqttService = MqttService();

  Map<String, String> _latestValues = {
    'volt': '220V',
    'rps': '3000',
    'freq': '50Hz',
    'temp': '75°C',
    'health': 'Good',
  };

  Map<String, List<Map<String, String>>> _allValues = {
    'volt': [],
    'rps': [],
    'freq': [],
    'temp': [],
    'health': [],
  };

  @override
  void initState() {
    super.initState();
    _mqttService.connect((topic, payload, timestamp) {
      setState(() {
        _latestValues[topic] = payload;
        _allValues[topic]!.add({'value': payload, 'timestamp': timestamp});
      });
    });
  }

  @override
  void dispose() {
    _mqttService.disconnect();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diesel Generator',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomePage(
        isDarkMode: _isDarkMode,
        toggleTheme: _toggleTheme,
        latestValues: _latestValues,
        allValues: _allValues,
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  final Map<String, String> latestValues;
  final Map<String, List<Map<String, String>>> allValues;

  HomePage(
      {required this.isDarkMode,
      required this.toggleTheme,
      required this.latestValues,
      required this.allValues});

  final List<Map<String, dynamic>> blocks = [
    {
      'title': 'VOLTAGE',
      'icon': Icons.flash_on,
      'color': Colors.blue,
      'topic': 'volt',
    },
    {
      'title': 'RPS',
      'icon': Icons.speed,
      'color': Colors.green,
      'topic': 'rps',
    },
    {
      'title': 'FREQUENCY',
      'icon': Icons.waves,
      'color': Colors.orange,
      'topic': 'freq',
    },
    {
      'title': 'TEMPERATURE',
      'icon': Icons.thermostat,
      'color': Colors.red,
      'topic': 'temp',
    },
    {
      'title': 'HEALTH',
      'icon': Icons.health_and_safety,
      'color': Colors.purple,
      'topic': 'health',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Diesel Generator'),
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: toggleTheme,
          ),
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(10.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        itemCount: blocks.length,
        itemBuilder: (context, index) {
          final block = blocks[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailsPage(
                    title: block['title'],
                    latestValue: latestValues[block['topic']]!,
                    latestTimestamp: allValues[block['topic']]!.isNotEmpty
                        ? allValues[block['topic']]!.last['timestamp']!
                        : '',
                    allValues: allValues[block['topic']]!,
                  ),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                color: block['color'],
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(block['icon'], size: 50.0, color: Colors.white),
                  SizedBox(height: 10.0),
                  Text(
                    block['title'],
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.0),
                  Text(
                    latestValues[block['topic']] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class DetailsPage extends StatelessWidget {
  final String title;
  final String latestValue;
  final String latestTimestamp;
  final List<Map<String, String>> allValues;

  DetailsPage({
    required this.title,
    required this.latestValue,
    required this.latestTimestamp,
    required this.allValues,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  latestValue,
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
                ),
                Text(
                  latestTimestamp,
                  style: TextStyle(fontSize: 16.0, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: allValues.length,
              itemBuilder: (context, index) {
                final value = allValues[index];
                return ListTile(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(value['value']!),
                      Text(value['timestamp']!,
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

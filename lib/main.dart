import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _selectedCategory = 'Продукт';
  String _searchText = '';
  List<dynamic> _results = [];
  bool _showSidebar = false;

  Future<String> _getLocalFilePath(String fileName) async {
    return 'C:/Users/Simeon/Desktop/pharmaciesProducts/$fileName.png';
  }

  Future<void> _fetchData() async {
    String apiUrl;
    if (_selectedCategory == 'Аптека') {
      apiUrl = 'http://10.0.2.2:8080/pharmacies/search?name=$_searchText';
    } else {
      apiUrl = 'http://10.0.2.2:8080/pharmacyProducts/search?name=$_searchText';
    }
    print(apiUrl);

    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          if (_selectedCategory == 'Аптека') {
            _results = decodedData.map((result) {
              return {
                'lat': (result['lat'] as double?) ?? 0.0,
                'lon': (result['lon'] as double?) ?? 0.0,
                'name': result['name'] ?? '',
                'id': result['id'] ?? 1
              };
            }).toList();
            _showSidebar = false;
          } else {
            print(decodedData);
            _results = decodedData;
            _showSidebar = _results.isNotEmpty;
          }
        });
      } else {
        _results = [];
        _showSidebar = false;
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showSidebar = false;
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/logo.png'),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.help),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.info),
              onPressed: () {},
            ),
          ],
        ),
        body: GestureDetector(
            onTap: () {
              if (_showSidebar && _selectedCategory == 'Продукт') {
                final double screenWidth = MediaQuery.of(context).size.width;
                final double tapXPosition =
                    MediaQuery.of(context).size.width - (screenWidth * 0.6);
                if (tapXPosition > 0) {
                  setState(() {
                    _showSidebar = false;
                  });
                }
              }
            },
            child: Stack(children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 30),
                    Text(
                      'Сè на едно место',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Заштеди време, сочувај пари, грижи се за твоето здравје!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 50),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 8,
                            child: TextFormField(
                              onChanged: (value) {
                                setState(() {
                                  _searchText = value;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Пишувај...',
                                border: OutlineInputBorder(),
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 20),
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 2.5, top: 2.0),
                            child: SizedBox(
                              height: 47,
                              child: ElevatedButton(
                                style: ButtonStyle(
                                  shape: MaterialStateProperty.all<
                                      RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0),
                                    ),
                                  ),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.blue),
                                ),
                                onPressed: () {
                                  _fetchData();
                                },
                                child: Text('Пребарај'),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 47,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(0),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedCategory = newValue!;
                                    });
                                  },
                                  dropdownColor: Colors.blue,
                                  style: TextStyle(color: Colors.white),
                                  items: <String>['Продукт', 'Аптека']
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(
                                        value,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 55),
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(41.6086, 21.7453),
                          zoom: 8,
                        ),
                        markers: _selectedCategory == 'Аптека' &&
                                _results.length > 0
                            ? _results
                                .map((result) => Marker(
                                      markerId:
                                          MarkerId(result['id'].toString()),
                                      position:
                                          LatLng(result['lat'], result['lon']),
                                      infoWindow:
                                          InfoWindow(title: result['name']),
                                    ))
                                .toSet()
                            : Set<Marker>(),
                      ),
                    ),
                  ],
                ),
              ),
              Visibility(
                visible: _showSidebar && _selectedCategory == 'Продукт',
                child: Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: MediaQuery.of(context).size.width * 0.6,
                  child: Container(
                    color: Colors.white,
                    child: SingleChildScrollView(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 1,
                        child: _showSidebar
                            ? ListView.builder(
                                itemCount: _results.length,
                                itemBuilder: (context, index) {
                                  final result = _results[index];
                                  return ListTile(
                                    title: Text(result['name']),
                                    subtitle:
                                        Text('Price: ${result['price']} MKD'),
                                    onTap: () {},
                                  );
                                },
                              )
                            : Container(),
                      ),
                    ),
                  ),
                ),
              ),
            ])));
  }
}

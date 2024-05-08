import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Django Flutter Example'),
        ),
        body: Center(
          child: FutureBuilder(
            future: fetchDataFromDjango(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              } else {
                // Check if the data from Django is 'hello'
                if (snapshot.data == 'hello') {
                  return Text('hello');
                } else {
                  return Text('Data from Django: ${snapshot.data}');
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Future<String> fetchDataFromDjango() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:8000/hello/'));

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception(
            'Failed to load data from Django: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to the server: $e');
    }
  }
}

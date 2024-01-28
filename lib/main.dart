import 'dart:io'; // Import this for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fish Detector',
      home: FishDetectorPage(),
    );
  }
}

class FishDetectorPage extends StatefulWidget {
  @override
  _FishDetectorPageState createState() => _FishDetectorPageState();
}

class _FishDetectorPageState extends State<FishDetectorPage> {
  final ImagePicker _picker = ImagePicker();
  List<String> fishList = [];
  File? _image; // Variable to hold the image file
  Uint8List? _imageBytes;
  String responseText = ""; // Variable to hold the response text

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Set the _image File
      });
    }
  }

  Future<void> detectFish() async {
    if (_image == null) return; // Do nothing if no image is selected

    setState(() {
      responseText = "Detecting..."; // Update UI to show detecting state
    });

    // Directly read bytes from the file and encode them to Base64
    String imageBase64 = base64Encode(await _image!.readAsBytes());

    try {
      var response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer YOUR_API_KEY', // Replace with your actual API Key
        },
        body: json.encode({
          'model': 'gpt-4-vision-preview', // Specify the model, replace with the actual model you want to use
          'messages': [
            {'role': 'system', 'content': 'You are a helpful assistant, capable of identifying fish and sea creatures in images.'},
            {'role': 'user', 
            "content": [
                {
                  "type": "text",
                  // "text": "What fish can you detect in thailand and sharks?"

                  "text": "What fish or sea creature (could be a shark, turtle whale any animal you find in the sea) can you detect in this image? Respond in json only. Assuming JSON content starts with '{' so we can parse it. Should have 'fish' key that shows and array dictionary of containing 'name', 'species', 'description', 'location', 'endangered', 'GPS-Coords' of where you can find this species, for each type of fish"
                },
                {
                  "type": "image_url",
                  "image_url": {
                    "url": 'data:image/jpeg;base64,'+imageBase64
                  }
                }
              ]
            }
          ],
          'max_tokens': 1000 // Increase this value as needed

        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          var data = json.decode(response.body);
          var contentString = data['choices']?.first['message']['content'] ?? '';

          // Find the start and end of the JSON content within the 'content' string
          int jsonStartIndex = contentString.indexOf('{');
          int jsonEndIndex = contentString.lastIndexOf('}');

          if (jsonStartIndex != -1 && jsonEndIndex != -1) {
            var jsonString = contentString.substring(jsonStartIndex, jsonEndIndex + 1);
            var contentData = json.decode(jsonString);

            // Process the extracted JSON data
            responseText = contentData.toString(); // Or process as needed
            List<dynamic> fishDetails = contentData['fish'] ?? [];
            fishList = fishDetails.map((f) => "Name: ${f['name']}, Species: ${f['species']}, Description: ${f['description']}").toList();
          } else {
            responseText = 'No valid JSON content found';
          }
        });

      }  else {
        setState(() {
          responseText = "Error: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        responseText = "Error: ${e.toString()}";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fish Detector'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: pickImage, // Button to pick the image
            child: Text('Pick Image'),
          ),
          if (_imageBytes != null) Image.memory(_imageBytes!),
          if (_image != null) Image.file(_image!), // Display the selected image
          ElevatedButton(
            onPressed: detectFish, // Button to detect fish
            child: Text('Detect Fish'),
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 500, // Adjust as needed
              ),
              child: SingleChildScrollView(
                child: Text(responseText),
              ),
            ),
          ),


          Expanded(
            child: ListView.builder(
              itemCount: fishList.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(fishList[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

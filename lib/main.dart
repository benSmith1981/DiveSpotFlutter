import 'dart:io'; // Import this for File
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'fish.dart';
import "FishDetailsWidget.dart";
import "FishService.dart";
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:fluttertoast/fluttertoast.dart';

Future main() async {
  print("Loading .env file");
  try {
    await dotenv.load(fileName: ".env");
    print("Successfully loaded .env file");
  } catch (e) {
    print("Failed to load .env file: $e");
  }
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
  List<Fish> fishList = [];
  File? _image; // Variable to hold the image file
  Uint8List? _imageBytes;
  String responseText = ""; // Variable to hold the response text
  bool isLoading = false; // Add this line

  void showToast(String message, {Color backgroundColor = Colors.black, ToastGravity gravity = ToastGravity.BOTTOM}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      timeInSecForIosWeb: 1,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0
    );
  }
  Future<void> pickImage() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select Image Source'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, ImageSource.gallery); },
              child: const Text('Gallery'),
            ),
            SimpleDialogOption(
              onPressed: () { Navigator.pop(context, ImageSource.camera); },
              child: const Text('Camera'),
            ),
          ],
        );
      },
    );

    if (source != null) {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        final image = File(pickedFile.path); // Set the _image File
        final imageBytes = await pickedFile.readAsBytes(); // Get image bytes

        // Now update the state
        setState(() {
          _image = image;
          _imageBytes = imageBytes;
        });
      }
    }
  }


  Future<void> detectFish() async {
    if (_image == null) {
      showToast("Please select an image first", backgroundColor: Colors.red);
      return;
    }

    setState(() {
      isLoading = true; // Start loading
    });
    String imageBase64 = base64Encode(await _image!.readAsBytes());

    try {
      var fishService = FishService();
      var newList = await fishService.detectFish(imageBase64);
      // Update state with the list of fish
      setState(() {
        this.fishList = newList; // Update state with the list of fish
      });
      showToast("Detection complete", backgroundColor: Colors.green);

    } catch (e) {
      showToast("Error: ${e.toString()}", backgroundColor: Colors.red);
    }finally {
      setState(() {
        isLoading = false; // Stop loading regardless of success or error
      });
    }
  }

  // Method to parse JSON data into Fish objects
  void processFishData(dynamic jsonData) {
    List<Fish> fishList = [];
    for (var fishData in jsonData) {
      fishList.add(Fish.fromJson(fishData));
    }
    setState(() {
      this.fishList = fishList;
    });
  }


@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Anything Detector'),
    ),
    body: Stack(
      children: <Widget>[
        Column(
          children: [
            ElevatedButton(
              onPressed: pickImage,
              child: Text('Pick Image'),
            ),
            if (_image != null) 
              Container(
                height: 200, // Fixed height for the image container
                child: Image.file(_image!, fit: BoxFit.cover),
              ),
            ElevatedButton(
              onPressed: detectFish,
              child: Text('Detect Anything'),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: fishList.length,
                itemBuilder: (context, index) {
                  return FishDetailsWidget(fish: fishList[index]);
                },
              ),
            ),
          ],
        ),
        if (isLoading)
          Positioned.fill(
            child: Container(
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    ),
  );
}

}
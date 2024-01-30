import 'package:http/http.dart' as http;
import 'dart:convert';
import 'fish.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FishService {
  String get apiKey => dotenv.env['API_KEY'] ?? 'No API Key';

  FishService();

  Future<List<Fish>> detectFish(String imageBase64) async {
    var response = await _postFishDetectionRequest(imageBase64);
    if (response.statusCode == 200) {
      return _processFishData(response.body);
    } else {
      throw Exception('Failed to load fish data');
    }
  }

  Future<http.Response> _postFishDetectionRequest(String imageBase64) async {
    return await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: json.encode({
        'model': 'gpt-4-vision-preview',
        'messages': [
          {'role': 'system', 'content': 'You are a helpful assistant, capable of identifying ANYTHING in images.'},
          {'role': 'user', 
            "content": [
              {
                "type": "text",
                "text": "What is this in the image? Focus on the main thing. Respond in json only. Assuming JSON content starts with '{' so we can parse it. Should have 'thing' key that shows and array dictionary of containing (if ther is no data for the different apart from descriptipon, as you should atleast put something in there, keys just empty string but do return data) 'name', 'species', 'description', 'location', 'endangered', for whatever is in the picture."
                // "text": "What recipes can I make with this collection of food items, id them, then give me a list of recipes"

                //  "text": "What fish or sea creature (could be a shark, turtle whale any animal you find in the sea) can you detect in this image? Respond in json only. Assuming JSON content starts with '{' so we can parse it. Should have 'fish' key that shows and array dictionary of containing 'name', 'species', 'description', 'location', 'endangered' for each type of fish"
              },
              {
                "type": "image_url",
                "image_url": 'data:image/jpeg;base64,'+imageBase64
              }
            ]
          }
        ],
        'max_tokens': 1000
      }),
    );
  }

  List<Fish> _processFishData(String responseBody) {
    var jsonData = json.decode(responseBody);
    var contentString = jsonData['choices']?.first['message']['content'] ?? '';

    // Find the start and end of the JSON content within the 'content' string
    int jsonStartIndex = contentString.indexOf('{');
    int jsonEndIndex = contentString.lastIndexOf('}');

    if (jsonStartIndex != -1 && jsonEndIndex != -1) {
      var jsonString = contentString.substring(jsonStartIndex, jsonEndIndex + 1);
      var fishDataJson = json.decode(jsonString);
      if (fishDataJson.containsKey('thing')) {
        var fishData = fishDataJson['thing'] as List;
        return fishData.map<Fish>((json) => Fish.fromJson(json)).toList();
      }

    } 
    print(contentString);
    // create a single Fish object with the response in its description.
    return [
      Fish(
        name: "Unknown",
        species: "Unknown",
        description: "Response: $contentString",
        location: "Unknown",
        endangered: "Unknown"
      )
    ];
    // else {
    //     // Fallback: if the JSON does not contain expected structure,

    //   throw Exception('No valid JSON content found');
    // }
  }

}



# DiveSpot - Chat GPT Vision API and flutter

I thought adding a new feature to my dive app where you can analyse images to find out what fish or sealife where in them would be really ool. But I didn't know how to do this without creating my own neural network, and I don't have the resources or money or knowledege to do this, but Chat GPT have a brilliant new Vision API that can understand any image. I intergrated this into flutter, find out how below. 

Go and read their Vision API https://platform.openai.com/docs/guides/vision it is incredible not only can it understand images but it can tell you detailed information about the contents of a photo. I used it in a simple flutter app to scan dive photos and then return the content. 

To use it you need a paid for chat gpt account so you can access GPT 4. Then you need to go and create your own API key https://platform.openai.com/api-keys and then insert it in to the flutter code below where it says "YOUR_API_KEY", let's breakdown the  code for the detecting the fish a little :
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

                  "text": "What fish or sea creature (could be a shark, turtle whale any animal you find in the sea) can you detect in this image? Respond in json only. Assuming JSON content starts with '{' so we can parse it. Should have 'fish' key that shows and array dictionary of containing 'name', 'species', 'description', 'location', 'endangered', for each type of fish"
                },
                {
                  "type": "image_url",
                  "image_url": {
                    // "url": "https://cms.bbcearth.com/sites/default/files/2020-12/2fdhe0000001000.jpg",
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
We are testing to see if the user has added a photo firstly and then if they have we need to convert it to base64 so we can send to the vision api, to get the photo you need to request the user to add a picture from their photo library:

  Future<void> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Set the _image File
      });
    }
  }
The next part is an HTTP request it is similar to their python examples on their documentation website, we need to post to https://api.openai.com/v1/chat/completions and then set up some things in the headers such as the API key, what model of GPT we want to use, and then the content, the text and the image

Notice my text prompt "What fish or sea creature (could be a shark, turtle whale any animal you find in the sea) can you detect in this image? Respond in json only. Assuming JSON content starts with '{' so we can parse it. Should have 'fish' key that shows and array dictionary of containing 'name', 'species', 'description', 'location', 'endangered', for each type of fish", I have asked chat gpt to respond with a specific JSON so we can parse it (is this a bit hacky, maybe, but it is cool as then we can do specific things with the data and it is incredibly detailed)

The last part is about decoding the response. We need to get at the content returned data['choices']?.first['message']['content'] and then we need basically get the substring of where the json starts { and where it ends }  once we have this we can actually parse the json string.

The last part is taking the parsed response and adding to our widget, where we are basically display the returned data in a list view:

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fish Detector1'),
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
And that is it really. Of course you could change the text prompt to detect anything. But as I want to add this to my dive app to help divers ID fish I made it specific to the ocean.

Cost of the API

Bear in mind their are costs associated to this Vision API from Chat GPT 4. You can calculate these costs here https://openai.com/pricing#language-models however, given the image dimensions are an image I was using (below) 1170 × 1071 pixels, which is approximately 1 MP, and the detail level is high, here's how you would calculate the cost:
1. Since the image is less than 2048 on the shortest side, it would not need to be resized.
2. The image is then scaled down to a 768px length on the shortest side.
3. Calculate the number of 512px tiles needed to cover the image area. For an image of 1170 × 1071, you would need 2 tiles along the width and 2 tiles along the height after scaling (since it would be smaller than 768 on the shortest side, we assume 768x768 to simplify).
4. Each tile costs 170 tokens, so 4 tiles would cost ( 170 times 4 = 680 ) tokens.
5. Add the base cost of 85 tokens for high-detail images.
So the total token cost would be ( 680 + 85 = 765 ) tokens.
If the rate is £0.01 per 1,000 tokens, the cost would be ( 765 div 1,000 times £0.01 ), which is approximately £0.00765.
However, it's important to note that this is a simplified calculation and the actual cost may vary based on OpenAI's specific implementation of the token counting system. Always refer to the OpenAI documentation for the most accurate and up-to-date information.

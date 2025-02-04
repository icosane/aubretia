import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sharing_intent/flutter_sharing_intent.dart';
import 'package:flutter_sharing_intent/model/sharing_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'aubretia',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white, // Light theme background
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.purple,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black, // Dark theme background
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.purple,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system,
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late StreamSubscription<List<SharedFile>> _intentDataStreamSubscription; // Declare the StreamSubscription
  List<SharedFile>? sharedFiles;
  final TextEditingController _linkController = TextEditingController(); 

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    initSharingListener(); // Keep this line
  }

  void initSharingListener() {
    _intentDataStreamSubscription = FlutterSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedFile> value) {
      _handleSharedFiles(value);
    }, onError: (err) {
      //print("Shared: getIntentDataStream error: $err");
    });

    FlutterSharingIntent.instance
        .getInitialSharing()
        .then((List<SharedFile> value) {
      _handleSharedFiles(value);
    });
  }

    void _handleSharedFiles(List<SharedFile> sharedFiles) {
      setState(() {
        this.sharedFiles = sharedFiles;
      });

      //print("Shared files: ${sharedFiles.map((f) => f.value).join(",")}");

      String? imageUrl;

      // Check for shared files
      for (var file in sharedFiles) {
        if (file.value?.startsWith('http') == true) {
          // If the shared item is a URL
          imageUrl = file.value;
          //print("Shared URL: $imageUrl");
          break; // Exit the loop once we find a valid URL
        }
      }

      // If a valid URL is found, show the bottom sheet
      if (imageUrl != null) {
        _linkController.text = imageUrl; // Optionally set the text field with the shared URL
        _showBottomSheet(context); // Show the bottom sheet
      } else {
        // Check if any shared file is an image
        bool isImageShared = sharedFiles.any((file) => file.value != null && 
            (file.value!.endsWith('.jpg') || 
            file.value!.endsWith('.png') || 
            file.value!.endsWith('.jpeg') || 
            file.value!.endsWith('.webp')));

        if (isImageShared) {
          _showDialog("Please share a direct link to the image instead of an image file.");
        } else {
          //print("No valid URL found.");
        }
      }
    }
    void _processImageLink(String link) {
      link = link.trim(); // Trim leading and trailing spaces

      // Decode the URL if it is URL-encoded
      if (link.contains('%')) {
        link = Uri.decodeComponent(link);
      }

      //print("Pasted link after decoding: $link"); // Log the decoded link

      if (link.isNotEmpty && link.startsWith('http')) {
        // Handle the image link (e.g., open the bottom sheet with search options)
        _showBottomSheet(context);
      } else {
        _showDialog("Please enter a valid image URL.");
      }
    }

    @override
    void dispose() {
      _intentDataStreamSubscription.cancel(); // Cancel the subscription
      super.dispose();
    }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;

        return GestureDetector(
          onTap: () {
            _closeApp(context);
          },
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: GestureDetector(
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    onPressed: () => _buttonClick("Button 1"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("SauceNAO"),
                  ),
                  SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _buttonClick("Button 2"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("ascii2d"),
                  ),
                  SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _buttonClick("Button 3"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("Google Images"),
                  ),
                  SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => _buttonClick("Button 4"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text("Google Lens"),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colorScheme.onSurface, size: 20),
                    onPressed: () => _closeApp(context), // Pass context to _closeApp
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

    void _buttonClick(String buttonName) async {
      // Get URLs from the text field
      List<String> urls = _linkController.text.isNotEmpty && _linkController.text.startsWith('http')
          ? [_linkController.text.trim()] // Use the pasted URL and trim it
          : sharedFiles?.map((file) => file.value)
              .where((url) => url != null && url.startsWith('http'))
              .cast<String>()
              .toList() ?? []; // Get URLs from shared files

      // Check if no valid URLs are found
      if (urls.isEmpty) {
        // Check if any shared file is an image
        bool isImageShared = sharedFiles?.any((file) => file.value != null && 
            (file.value!.endsWith('.jpg') || 
            file.value!.endsWith('.png') || 
            file.value!.endsWith('.jpeg') || 
            file.value!.endsWith('.webp'))) ?? false;

        if (isImageShared) {
          _showDialog("Please share a direct link to the image instead of an image file.");
        } else {
          _showDialog("No valid URLs found.");
        }
        return; // Exit if no valid URLs
      }

      String sharedUrl = Uri.encodeComponent(urls[0]); // Use the first valid URL
      String url = ''; // Declare the url variable

      switch (buttonName) {
        case "Button 1":
          url = "https://saucenao.com/search.php?db=999&url=$sharedUrl";
          break;
        case "Button 2":
          url = "https://ascii2d.net/search/url/$sharedUrl";
          break;
        case "Button 3":
          url = "https://www.google.com/searchbyimage?client=firefox-b-d&image_url=$sharedUrl";
          break;
        case "Button 4":
          url = "https://lens.google.com/uploadbyurl?url=$sharedUrl";
          break;
      }

      if (url.isNotEmpty) {
        final Uri uri = Uri.parse(url);
        //print("Attempting to launch URL: $uri"); // Log the URL
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        } 
      }
    }


  void _showDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }


  void _closeApp(BuildContext context) {
    // Delay for a short duration to allow animations to complete
    Future.delayed(Duration(milliseconds: 300), () {
      Navigator.pop(context); // Close the bottom sheet
      SystemNavigator.pop(); // Exit the app completely
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Display the appropriate image based on the theme
            Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_foreground.png'
                  : 'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_monochrome.png',
              width: 100, // Set the width of the image
              height: 100, // Set the height of the image
            ),
            SizedBox(height: 20), // Add some space
            Container(
              alignment: Alignment.center,
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Share a direct link to an image \n from any app to Aubretia. Or paste it below.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 20), // Add some space
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: 'Paste image link here',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) {
                  _processImageLink(value);
                },
              ),
            ),
            SizedBox(height: 20), // Add some space
            ElevatedButton(
              onPressed: () {
                _processImageLink(_linkController.text);
              },
              child: Text("Search Image"),
            ),
            SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
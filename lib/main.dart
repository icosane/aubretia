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
        scaffoldBackgroundColor: Colors.white, // Set a solid color for light theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.purple, // Set app bar color
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: Colors.black, // Set a solid color for dark theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.purple, // Set app bar color
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system, // Automatically switch based on system theme
      home: MyHomePage(),
      debugShowCheckedModeBanner: false, // Hide the debug banner
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

  @override
void initState() {
  super.initState();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  WidgetsBinding.instance.addPostFrameCallback((_) {
    _showBottomSheet(context);
  });

  initSharingListener();
}

void initSharingListener() {
  _intentDataStreamSubscription = FlutterSharingIntent.instance
      .getMediaStream()
      .listen((List<SharedFile> value) {
    setState(() {
      sharedFiles = value;
    });
    print("Shared: getMediaStream ${value.map((f) => f.value).join(",")}");
  }, onError: (err) {
    print("Shared: getIntentDataStream error: $err");
  });

  FlutterSharingIntent.instance
      .getInitialSharing()
      .then((List<SharedFile> value) {
    setState(() {
      sharedFiles = value;
    });
    print("Shared: getInitialMedia => ${value.map((f) => f.value).join(",")}");
    print("Initial sharedFiles: $sharedFiles"); // Log the sharedFiles list

    // Check if there is a URL in the shared data
    String? url = value.isNotEmpty ? value[0].value : null; // Assuming the first item might be a URL
    if (url != null && url.startsWith('http')) {
      // Handle the URL as needed
      print("Shared URL: $url");
    } else {
      // Handle the case where no URL is found
      print("No URL found in shared data.");
    }
  });
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
    if (sharedFiles == null || sharedFiles!.isEmpty) return;

    // Filter to get only the URLs
    List<String> urls = sharedFiles!
        .map((file) => file.value) // Get the value (path) of each SharedFile
        .where((url) => url != null && url.startsWith('http')) // Check if it's a URL
        .cast<String>() // Cast to List<String>
        .toList();

    if (urls.isEmpty) return; // Exit if no valid URLs

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
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
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
      backgroundColor: Colors.black, // Make the scaffold background transparent
      body: Center(
        child: Container(), // No additional content
      ),
    );
  }
}
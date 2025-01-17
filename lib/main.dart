import 'package:flutter/material.dart';
import 'bible_picker.dart';
import 'editable_text_widget.dart';

import 'package:telegram_web_app/telegram_web_app.dart';


void main() async {
  try {
    if (TelegramWebApp.instance.isSupported) {
      TelegramWebApp.instance.ready();
      TelegramWebApp.instance.disableVerticalSwipes();

      Future.delayed(
          const Duration(seconds: 1), TelegramWebApp.instance.expand);
    }
  } catch (e) {
    print("Error happened in Flutter while loading Telegram: $e");
    // add delay for 'Telegram not loading sometimes' bug
    await Future.delayed(const Duration(milliseconds: 200));
    main();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.redAccent,
          onSecondary: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          surface: Colors.black,
          onSurface: Colors.white,
        ),
      ),
      home: const HomeWidget(),
    );
  }
}

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  String _value = "ллдлодол одлолдо  лдолдо  лдодло длодло д л л л л л лл  л л л л л л л л л л лл  л л л л л л  л л л л л л л лл ллдлодол одлолдо  лдолдо  лдодло длодло д л л л л л лл  л л л л л л л л л л лл  л л л л л л  л л л л л л л лл ллдлодол одлолдо  лдолдо  лдодло длодло д л л л л л лл  л л л л л л л л л л лл  л л л л л л  л л л л л л л лл ллдлодол одлолдо  лдолдо  лдодло длодло д л л л л л лл  л л л л л л л л л л лл  л л л л л л  л л л л л л л ллллдлодол одлолдо  лдолдо  лдодло длодло д л л л л л лл  л л л л л л л л л л лл  л л л л л л  л л л л л л л лл ";
  double _hiddenWordPercentage = 0.8;

  void _updateValue(String newValue) {
    setState(() {
      _value = newValue;
    });
  }

  void _updatePercentage(double newPercentage) {
    setState(() {
      _hiddenWordPercentage = newPercentage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          PickerWidget(onTextChanged: _updateValue),
          const SizedBox(height: 10),
          Slider(
            value: _hiddenWordPercentage,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (value) => _updatePercentage(value),
            activeColor: Colors.white,
            inactiveColor: Colors.grey,
            thumbColor: Colors.grey,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: EditableTextWidget(
              inputString: _value,
              hiddenWordPercentage: _hiddenWordPercentage,
            ),
          ),
        ],
      ),
    );
  }
}

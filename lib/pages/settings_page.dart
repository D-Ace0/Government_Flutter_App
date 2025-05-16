import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:governmentapp/themes/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("Settings"),
        centerTitle: true,
        backgroundColor: Colors.grey,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(14),
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Dark Mode"),

            CupertinoSwitch(
              value: Provider.of<ThemeProvider>(context).isDarkMode,
              onChanged:
                  (value) =>
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).toggleTheme(),
            ),
          ],
        ),
      ),
    );
  }
}
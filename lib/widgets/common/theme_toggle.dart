import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:nwt_app/controllers/theme_controller.dart';

class ThemeToggle extends StatelessWidget {
  final double? size;
  final Color? lightModeColor;
  final Color? darkModeColor;

  const ThemeToggle({
    Key? key,
    this.size = 24.0,
    this.lightModeColor,
    this.darkModeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    
    return Obx(() {
      final isDarkMode = themeController.isDarkMode;
      
      return IconButton(
        icon: Icon(
          isDarkMode ? Icons.dark_mode : Icons.light_mode,
          color: isDarkMode 
              ? darkModeColor ?? Colors.white 
              : lightModeColor ?? Colors.black,
          size: size,
        ),
        onPressed: () {
          themeController.toggleTheme();
        },
      );
    });
  }
}

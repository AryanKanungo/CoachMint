import 'package:coachmint/screens/goals/icon_data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class IconPickerScreen extends StatelessWidget {
  const IconPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select an Icon'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: AppIcons.icons.length,
        itemBuilder: (context, index) {
          final icon = AppIcons.icons[index];
          return InkWell(
            onTap: () {
              Get.back(result: icon);
            },
            borderRadius: BorderRadius.circular(12.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            ),
          );
        },
      ),
    );
  }
}

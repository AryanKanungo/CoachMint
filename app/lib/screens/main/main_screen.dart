import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'main_controller.dart';

class MainScreen extends GetView<MainController> {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(MainController());

    return Scaffold(
      body: Obx(
            () => AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: controller.pages[controller.selectedIndex.value],
        ),
      ),
      bottomNavigationBar: Obx(
            () => BottomNavigationBar(
          currentIndex: controller.selectedIndex.value,
          onTap: controller.onItemTapped,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.star_rounded), // This tab will be purple when active
              label: "Goals",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_rounded),
              label: "Stats",
            ),
          ],
        ),
      ),
    );
  }
}
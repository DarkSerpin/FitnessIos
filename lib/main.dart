import 'package:flutter/material.dart';
import 'package:fitness/pages/trainingsplaene.dart';
import 'package:fitness/pages/uebungen.dart';
import 'package:fitness/pages/statistiken.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const MainNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final PageController _pageController = PageController(initialPage: 1);
  int _currentPage = 1;

  final List<Widget> _pages = [
    const Statistiken(),
    const Trainingsplaene(),
    const UebungenSeite(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (int page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentPage,
        onTap: (int index) {
          setState(() {
            _currentPage = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart), 
            label: 'Statistiken', 
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fitness_center),
            label: 'Trainingspläne',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Übungen',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
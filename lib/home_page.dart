import 'package:flutter/material.dart';
import 'account.dart';
import 'chat.dart';
import 'maktba.dart';
import 'tasks.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Simple Home',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int counter = 0;

  // ترتيب الصفحات نفس ترتيب الأيقونات
  final List<Widget> _pages = const [
    AccountSection(),
    LibraryPage(),
    ChatScreen(),
    TasksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضا
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF3A4297),
        unselectedItemColor: const Color(0xFFFBCA41),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, size: 30),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book, size: 30),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat, size: 30),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.task, size: 30),
            label: '',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => setState(() => counter = 0),
              backgroundColor: const Color(0xFF3A4297),
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }
}

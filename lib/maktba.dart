import 'package:flutter/material.dart';
import 'adap.dart';
import 'arts.dart';
import 'bahta.dart';
import 'dianat.dart';
import 'falsafa.dart';
import 'history.dart';
import 'languages.dart';
import 'mecanica.dart';
import 'social%20science.dart';
// استدعاء صفحة البحث
import 'ma3rfa_3ama.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF8FF),
      body: Column(
        children: [
          // الهيدر العلوي
          Container(
            height: 90,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF592F96),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
          ),

          // باقي الصفحة (شبكة الصور)
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.only(
                left: 25,
                right: 25,
                bottom: 25,
                top: 30,
              ),
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              childAspectRatio: 0.8, // زيادة النسبة لجعل الخلايا مربعة
              children: [
                _buildSmallImageCard(
                  context,
                  'assets/3ama.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BooksSearchPage(),
                      ),
                    );
                  },
                ),
                _buildSmallImageCard(
                  context,
                  'assets/falsafa.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Falsafa(),
                      ),
                    );
                  },
                ),
                _buildSmallImageCard(
                  context,
                  'assets/history.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => History(),
                      ),
                    );
                  },
                ),
                _buildSmallImageCard(
                  context,
                  'assets/dianat.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Dianat(),
                      ),
                    );
                  },
                ),
                _buildSmallImageCard(
                  context,
                  'assets/arts.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Arts(),
                      ),
                    );
                  },
                ),
                _buildSmallImageCard(
                  context,
                  'assets/micanica.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Mecanica(),
                      ),
                    );
                  },
                ),
                _buildSmallImageCard(
                  context,
                  'assets/languages.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Languages(),
                      ),
                    );
                  },
                ),
                _buildSmallImageCard(
                  context,
                  'assets/bahta.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Bahta(),
                      ),
                    );
                  },
                ),
                _buildSmallImageCard(
                  context,
                  'assets/social science.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Socialscience(),
                      ),
                    );
                  },
                ),
                _buildSmallImageCard(
                  context,
                  'assets/adap.png',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Adap(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallImageCard(BuildContext context, String imagePath, {VoidCallback? onTap}) {
    Widget imageWidget = Container(
      // زيادة المساحة البيضاء حول الصورة لجعلها أصغر
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image, size: 30, color: Colors.grey),
            );
          },
        ),
      ),
    );

    // لو فيه onTap نغلفها بـ InkWell
    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
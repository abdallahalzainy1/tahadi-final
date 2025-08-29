import 'log_in.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  int _currentStep = 0;
  String _name = '';
  String _phone = '';
  String _password = '';
  DateTime? _dateOfBirth;
  File? _profileImage;
  bool _isLoading = false;
  String _errorMessage = '';
  final _formKey = GlobalKey<FormState>();
  final Color _primaryColor = const Color(0xFF5A34A2);
  
  // بيانات المحافظات والإدارات
  Map<String, dynamic> _citiesData = {};
  List<String> _governorates = [];
  List<String> _departments = [];
  String? _selectedGovernorate;
  String? _selectedDepartment;
  String _school = '';

  @override
  void initState() {
    super.initState();
    _loadCitiesData();
  }

  Future<void> _loadCitiesData() async {
    try {
      String data = await rootBundle.loadString('assets/cities.json');
      setState(() {
        _citiesData = json.decode(data);
        _governorates = _citiesData.keys.toList();
      });
    } catch (e) {
      print("Error loading cities data: $e");
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // استخدام رقم الهاتف كمعرف بدلاً من البريد الإلكتروني
      String phoneEmail = '${_phone}@tahadi.com';
      
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: phoneEmail,
        password: _password,
      );

      String? imageUrl;
      if (_profileImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_images/${userCredential.user!.uid}');
        await storageRef.putFile(_profileImage!);
        imageUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _name,
        'password': _password,
        'phone': _phone,
        'dateOfBirth': _dateOfBirth,
        'profileImage': imageUrl,
        'governorate': _selectedGovernorate,
        'department': _selectedDepartment,
        'school': _school,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SuccessPage(name: _name)),
      );
    } on FirebaseAuthException catch (e) {
      _handleAuthError(e);
    } catch (e) {
      setState(() {
        _errorMessage = 'حدث خطأ غير متوقع: $e';
        _isLoading = false;
      });
    }
  }

  void _handleAuthError(FirebaseAuthException e) {
    String errorMessage;
    switch (e.code) {
      case 'weak-password':
        errorMessage = 'كلمة المرور ضعيفة جداً (يجب أن تحتوي على 6 أحرف على الأقل)';
        break;
      case 'email-already-in-use':
        errorMessage = 'رقم الهاتف مستخدم بالفعل';
        break;
      case 'invalid-email':
        errorMessage = 'رقم الهاتف غير صحيح';
        break;
      default:
        errorMessage = 'حدث خطأ: ${e.message}';
    }
    setState(() {
      _errorMessage = errorMessage;
      _isLoading = false;
      _currentStep = 0;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _dateOfBirth) {
      setState(() {
        _dateOfBirth = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // خلفية الصورة
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/Sign.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // المحتوى الرئيسي
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // نص التسجيل والدخول
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 45),
                      Text(
                        'إنشاء حساب',
                        style: GoogleFonts.tajawal(
                          fontWeight: FontWeight.w600,
                          color: _primaryColor,
                          fontSize: 30,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'لديك حساب بالفعل؟ ',
                              style: GoogleFonts.tajawal(
                                fontWeight: FontWeight.w600,
                                color: _primaryColor,
                                fontSize: 14,
                              ),
                            ),
                            WidgetSpan(
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SignInPage()),
                                  );
                                },
                                child: Text(
                                  'تسجيل الدخول',
                                  style: GoogleFonts.tajawal(
                                    fontWeight: FontWeight.w600,
                                    color: _primaryColor,
                                    fontSize: 14,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // الشعار
                  const SizedBox(height: 10),
                  Center(
                    child: Image.asset(
                      'assets/tahadi.png',
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // محتوى النموذج
                  _buildStepper(),
                ],
              ),
            ),
          ),
          // زر الرجوع للخطوة الثانية
          if (_currentStep == 1)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _currentStep--;
                    _errorMessage = '';
                  });
                },
              ),
            ),
          // مؤشر التحميل
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 5,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'جاري إنشاء حسابك...',
                      style: GoogleFonts.tajawal(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildStepIndicator(),
            const SizedBox(height: 24),
            _currentStep == 0 ? _buildStepOne() : _buildStepTwo(),
            const SizedBox(height: 24),
            if (_currentStep == 0) _buildContinueButton(),
            if (_currentStep == 1) _buildCreateButton(),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  _errorMessage,
                  style: GoogleFonts.tajawal(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStepCircle(0, '1', 'المعلومات'),
        _buildStepLine(),
        _buildStepCircle(1, '2', 'المحافظة'),
      ],
    );
  }

  Widget _buildStepCircle(int step, String number, String text) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentStep >= step ? _primaryColor : Colors.grey[300],
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.tajawal(
                color: _currentStep >= step ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: GoogleFonts.tajawal(
            color: _currentStep >= step ? _primaryColor : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine() {
    return Container(
      width: 50,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.grey[300],
    );
  }

  Widget _buildStepOne() {
    return Column(
      children: [
        TextFormField(
          style: GoogleFonts.tajawal(),
          decoration: InputDecoration(
            labelText: 'الاسم',
            labelStyle: GoogleFonts.tajawal(),
            prefixIcon: Icon(Icons.person, color: _primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
          ),
          onChanged: (value) => _name = value,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال اسمك';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          style: GoogleFonts.tajawal(),
          decoration: InputDecoration(
            labelText: 'رقم الهاتف',
            labelStyle: GoogleFonts.tajawal(),
            prefixIcon: Icon(Icons.phone, color: _primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) => _phone = value,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال رقم هاتفك';
            }
            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
              return 'يرجى إدخال رقم هاتف صحيح (أرقام فقط)';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          style: GoogleFonts.tajawal(),
          decoration: InputDecoration(
            labelText: 'كلمة المرور',
            labelStyle: GoogleFonts.tajawal(),
            prefixIcon: Icon(Icons.lock, color: _primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
          ),
          obscureText: true,
          onChanged: (value) => _password = value,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال كلمة مرور';
            }
            if (value.length < 6) {
              return 'يجب أن تحتوي كلمة المرور على 6 أحرف على الأقل';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: () => _selectDate(context),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'تاريخ الميلاد',
              labelStyle: GoogleFonts.tajawal(),
              prefixIcon: Icon(Icons.calendar_today, color: _primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _dateOfBirth == null
                      ? 'اختر تاريخ ميلادك'
                      : '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}',
                  style: GoogleFonts.tajawal(
                    color: _dateOfBirth == null ? Colors.grey[600] : Colors.black,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.black),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwo() {
    return Column(
      children: [
        // اختيار المحافظة
        DropdownButtonFormField<String>(
          value: _selectedGovernorate,
          decoration: InputDecoration(
            labelText: 'المحافظة',
            labelStyle: GoogleFonts.tajawal(),
            prefixIcon: Icon(Icons.location_city, color: _primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
          ),
          items: _governorates.map((String governorate) {
            return DropdownMenuItem<String>(
              value: governorate,
              child: Text(governorate, style: GoogleFonts.tajawal()),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGovernorate = newValue;
              _selectedDepartment = null;
              if (newValue != null && _citiesData.containsKey(newValue)) {
                _departments = List<String>.from(_citiesData[newValue]);
              } else {
                _departments = [];
              }
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى اختيار المحافظة';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // اختيار الإدارة (تظهر فقط بعد اختيار المحافظة)
        if (_selectedGovernorate != null)
          DropdownButtonFormField<String>(
            value: _selectedDepartment,
            decoration: InputDecoration(
              labelText: 'الإدارة',
              labelStyle: GoogleFonts.tajawal(),
              prefixIcon: Icon(Icons.location_on, color: _primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            items: _departments.map((String department) {
              return DropdownMenuItem<String>(
                value: department,
                child: Text(department, style: GoogleFonts.tajawal()),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedDepartment = newValue;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'يرجى اختيار الإدارة';
              }
              return null;
            },
          ),
        if (_selectedGovernorate != null) const SizedBox(height: 16),
        
        // حقل إدخال المدرسة
        TextFormField(
          style: GoogleFonts.tajawal(),
          decoration: InputDecoration(
            labelText: 'المدرسة',
            labelStyle: GoogleFonts.tajawal(),
            prefixIcon: Icon(Icons.school, color: _primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _primaryColor, width: 2),
            ),
          ),
          onChanged: (value) => _school = value,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'يرجى إدخال اسم المدرسة';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // صورة البروفايل
        
        
      ],
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(59),
            ),
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              setState(() {
                _currentStep++;
                _errorMessage = '';
              });
            }
          },
          child: Text(
            'متابعة',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(59),
            ),
          ),
          onPressed: _createAccount,
          child: Text(
            'إنشاء حساب',
            style: GoogleFonts.tajawal(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class SuccessPage extends StatelessWidget {
  final String name;

  const SuccessPage({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/tahadi.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 100,
                ),
                const SizedBox(height: 32),
                Text(
                  'مبروك!',
                  style: GoogleFonts.tajawal(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'تم إنشاء حسابك بنجاح',
                  style: GoogleFonts.tajawal(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'مرحباً $name',
                  style: GoogleFonts.tajawal(
                    color: Colors.black54,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A34A2),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                      (Route<dynamic> route) => false,
                    );
                  },
                  child: Text(
                    'الذهاب للصفحة الرئيسية',
                    style: GoogleFonts.tajawal(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
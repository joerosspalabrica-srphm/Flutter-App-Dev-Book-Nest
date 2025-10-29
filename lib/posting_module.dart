import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Posting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF003060),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF003060), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      home: const BookPostingForm(),
    );
  }
}

class FormFieldConfig {
  final String label;
  final String key;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? prefix;
  final bool required;
  final String? Function(String?)? validator;
  final bool isDropdown;
  final List<String>? dropdownOptions;

  FormFieldConfig({
    required this.label,
    required this.key,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.prefix,
    this.required = true,
    this.validator,
    this.isDropdown = false,
    this.dropdownOptions,
  });
}

class BookPostingForm extends StatefulWidget {
  const BookPostingForm({Key? key}) : super(key: key);

  @override
  State<BookPostingForm> createState() => _BookPostingFormState();
}

class _BookPostingFormState extends State<BookPostingForm> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  File? _bookImage;
  String? _bookImageBase64;
  
  // Dynamic form data storage
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, dynamic> _formData = {};

  // Dynamic form configuration
  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Book Details',
      'fields': [
        FormFieldConfig(
          label: 'Book Title',
          key: 'title',
          icon: Icons.auto_stories_rounded,
        ),
        FormFieldConfig(
          label: 'Book Genre/Category',
          key: 'genre',
          icon: Icons.local_library_rounded,
          isDropdown: true,
          dropdownOptions: ['Education', 'Fiction', 'Non - Fiction', 'Mystery'],
        ),
        FormFieldConfig(
          label: 'Author',
          key: 'author',
          icon: Icons.edit_rounded,
        ),
        FormFieldConfig(
          label: 'Publication',
          key: 'publication',
          icon: Icons.apartment_rounded,
        ),
        FormFieldConfig(
          label: 'Language',
          key: 'language',
          icon: Icons.translate_rounded,
        ),
        FormFieldConfig(
          label: 'Condition',
          key: 'condition',
          icon: Icons.verified_rounded,
          isDropdown: true,
          dropdownOptions: ['Brand New', 'Good as New', 'Old (Used)'],
        ),
        FormFieldConfig(
          label: 'Publication Year',
          key: 'year',
          icon: Icons.event_rounded,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter Publication Year';
            final year = int.tryParse(value);
            if (year == null) return 'Please enter a valid year';
            if (year < 1000 || year > DateTime.now().year) {
              return 'Please enter a valid year';
            }
            return null;
          },
        ),
        FormFieldConfig(
          label: 'Publisher',
          key: 'publisher',
          icon: Icons.domain_rounded,
        ),
        FormFieldConfig(
          label: 'About',
          key: 'about',
          icon: Icons.article_rounded,
          maxLines: 4,
        ),
      ],
    },
    {
      'title': 'Penalties',
      'subtitle': 'Set penalty amounts for book violations',
      'fields': [
        FormFieldConfig(
          label: 'Late Return',
          key: 'late_return',
          icon: Icons.access_time_rounded,
          keyboardType: TextInputType.number,
          prefix: '₱',
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter Late Return penalty';
            final amount = double.tryParse(value);
            if (amount == null || amount < 0) return 'Please enter a valid amount';
            return null;
          },
        ),
        FormFieldConfig(
          label: 'Book Damage',
          key: 'damage',
          icon: Icons.report_problem_rounded,
          keyboardType: TextInputType.number,
          prefix: '₱',
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter Book Damage penalty';
            final amount = double.tryParse(value);
            if (amount == null || amount < 0) return 'Please enter a valid amount';
            return null;
          },
        ),
        FormFieldConfig(
          label: 'Lost or Unreturned Book',
          key: 'lost',
          icon: Icons.search_off_rounded,
          keyboardType: TextInputType.number,
          prefix: '₱',
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter Lost Book penalty';
            final amount = double.tryParse(value);
            if (amount == null || amount < 0) return 'Please enter a valid amount';
            return null;
          },
        ),
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (var step in _steps) {
      final fields = step['fields'] as List<FormFieldConfig>;
      for (var field in fields) {
        _controllers[field.key] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      // Save current step data
      _saveCurrentStepData();

      if (_currentStep < _steps.length - 1) {
        setState(() {
          _currentStep++;
        });
      } else {
        _submitForm();
      }
    }
  }

  void _saveCurrentStepData() {
    final fields = _steps[_currentStep]['fields'] as List<FormFieldConfig>;
    for (var field in fields) {
      _formData[field.key] = _controllers[field.key]!.text;
    }
  }

  Future<void> _submitForm() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to post books'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Prepare book data
      final bookData = {
        'title': _formData['title'],
        'genre': _formData['genre'],
        'author': _formData['author'],
        'publication': _formData['publication'],
        'language': _formData['language'],
        'condition': _formData['condition'],
        'year': _formData['year'],
        'publisher': _formData['publisher'],
        'about': _formData['about'],
        'imageUrl': _bookImageBase64, // Store image as base64
        'penalties': {
          'lateReturn': double.tryParse(_formData['late_return'] ?? '0') ?? 0.0,
          'damage': double.tryParse(_formData['damage'] ?? '0') ?? 0.0,
          'lost': double.tryParse(_formData['lost'] ?? '0') ?? 0.0,
        },
        'ownerId': user.uid,
        'ownerName': user.displayName ?? 'Unknown',
        'status': 'available', // available, borrowed, unavailable
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('books').add(bookData);

      // Close loading
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Book posted successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        // Go back to homepage
        Navigator.of(context).pop();
      }
      
    } catch (e) {
      // Close loading if open
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting book: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Map<String, dynamic> getFormData() {
    _saveCurrentStepData();
    return Map.from(_formData);
  }

  @override
  Widget build(BuildContext context) {
    final currentStepData = _steps[_currentStep];
    final fields = currentStepData['fields'] as List<FormFieldConfig>;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildFormCard(currentStepData, fields),
                      const SizedBox(height: 24),
                      _buildStepIndicators(),
                      const SizedBox(height: 24),
                      _buildActionButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: _previousStep,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF003060),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Add a Book for Posting',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF003060),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(Map<String, dynamic> stepData, List<FormFieldConfig> fields) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (stepData['subtitle'] != null) ...[
            Text(
              stepData['title'],
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF003060),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stepData['subtitle'],
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 24),
          ],
          // Image Upload Section (only on first step)
          if (_currentStep == 0) ...[
            _buildImageUploadSection(),
            const SizedBox(height: 20),
          ],
          ...List.generate(
            fields.length,
            (index) => Column(
              children: [
                _buildDynamicTextField(fields[index]),
                if (index < fields.length - 1) const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicTextField(FormFieldConfig config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              config.label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF374151),
              ),
            ),
            if (config.required)
              Text(
                ' *',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (config.isDropdown && config.dropdownOptions != null)
          DropdownButtonFormField<String>(
            value: _formData[config.key],
            decoration: InputDecoration(
              prefixIcon: Icon(config.icon, color: const Color(0xFF6B7280), size: 20),
              hintText: 'Select ${config.label}',
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFFD1D5DB),
                fontSize: 14,
              ),
            ),
            items: config.dropdownOptions!.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _formData[config.key] = newValue;
                if (_controllers[config.key] != null) {
                  _controllers[config.key]!.text = newValue ?? '';
                }
              });
            },
            validator: config.validator ??
                (value) {
                  if (config.required && (value == null || value.isEmpty)) {
                    return 'Please select ${config.label}';
                  }
                  return null;
                },
          )
        else
          TextFormField(
            controller: _controllers[config.key],
            maxLines: config.maxLines,
            keyboardType: config.keyboardType,
            decoration: InputDecoration(
              prefixIcon: Icon(config.icon, color: const Color(0xFF6B7280), size: 20),
              prefixText: config.prefix,
              hintText: 'Enter ${config.label}',
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFFD1D5DB),
                fontSize: 14,
              ),
            ),
            validator: config.validator ??
                (value) {
                  if (config.required && (value == null || value.isEmpty)) {
                    return 'Please enter ${config.label}';
                  }
                  return null;
                },
          ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Book Cover Image',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: _bookImage != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _bookImage!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF003060).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_photo_alternate_rounded,
                          size: 48,
                          color: Color(0xFF003060),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to upload book cover',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'JPG, PNG (Max 5MB)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_bookImage != null) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _bookImage = null;
                    _bookImageBase64 = null;
                  });
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(
                  'Remove Image',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final bytes = await imageFile.readAsBytes();
        
        // Check file size (5MB limit)
        if (bytes.length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image size should be less than 5MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _bookImage = imageFile;
          _bookImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStepIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _steps.length * 2 - 1,
        (index) {
          if (index.isOdd) {
            // Connector line
            final lineIndex = index ~/ 2;
            return Container(
              width: 40,
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: _currentStep > lineIndex
                  ? const Color(0xFF003060)
                  : const Color(0xFFE5E7EB),
            );
          } else {
            // Step indicator
            final stepIndex = index ~/ 2;
            return _buildStepIndicator(
              stepIndex,
              _steps[stepIndex]['title'],
            );
          }
        },
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF003060) : Colors.white,
            border: Border.all(
              color: isActive ? const Color(0xFF003060) : const Color(0xFFE5E7EB),
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && step < _currentStep
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${step + 1}',
                    style: GoogleFonts.poppins(
                      color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isActive ? const Color(0xFF003060) : const Color(0xFF9CA3AF),
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _nextStep,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD67730),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _currentStep == _steps.length - 1 ? 'Submit' : 'Next',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

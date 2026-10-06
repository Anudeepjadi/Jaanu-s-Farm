import 'package:flutter/material.dart';
import 'firebase_service.dart';
import 'home_screen.dart';

class OtpScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String password;

  const OtpScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool isLoading = false;
  String error = "";

  void _verifyAndRegister() async {
    String otp = otpController.text.trim();

    // For demonstration, we'll use a hardcoded OTP '123456'
    // In a real app, you'd use Firebase Phone Auth or an Email OTP service
    if (otp != "123456") {
      setState(() => error = "Invalid OTP. Use 123456 for testing.");
      return;
    }

    setState(() {
      isLoading = true;
      error = "";
    });

    String? result = await _firebaseService.signUp(
      widget.email,
      widget.password,
      widget.name,
      widget.phone,
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (result == null) {
      // Success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration Successful!")),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen(name: widget.name)),
          (route) => false,
        );
      }
    } else {
      setState(() => error = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("OTP Verification")),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.mark_email_read, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              "Verify your number ${widget.phone}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Enter the 6-digit code sent to you\n(Test code: 123456)",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 10),
              decoration: InputDecoration(
                counterText: "",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
            const SizedBox(height: 10),
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : _verifyAndRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Verify & Create Account"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  String error = "";
  bool isPasswordVisible = false;

  void login() {
    String name = nameController.text.trim();
    String password = passwordController.text.trim();

    if (name.isEmpty || password.isEmpty) {
      setState(() {
        error = "Please enter all fields";
      });
      return;
    }

    // Admin Login Check
    if (name.toLowerCase() == "admin" && password == "admin123") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AdminDashboard(),
        ),
      );
      return;
    }

    // User Login Check (Simplified for demonstration)
    if (password.length < 4) {
      setState(() {
        error = "Password must be at least 4 characters";
      });
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(name: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 80),
              Image.asset(
                "assets/icons/Jaanu Farm's.jpeg",
                height: 180,
              ),
              const SizedBox(height: 20),
              Text(
                "Jaanu's Farm",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const Text("Login to your account"),
              const SizedBox(height: 40),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Username / Email",
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: !isPasswordVisible,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        isPasswordVisible = !isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
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
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text(
                    "Login",
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Are you an Admin?"),
                  TextButton(
                    onPressed: () {
                      nameController.text = "admin";
                      passwordController.text = "admin123";
                    },
                    child: const Text("Use Admin Creds", style: TextStyle(color: Colors.blue)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

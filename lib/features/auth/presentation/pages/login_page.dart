import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  
  String _selectedDepartment = 'IT';
  String _selectedRole = 'employee';
  
  final List<String> _departments = [
    'IT', 'Maintenance', 'Production', 'Quality Control', 'Management'
  ];
  
  final List<String> _roles = [
    'employee', 'supervisor', 'manager', 'admin'
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isSignUp) {
        // Register new user with REAL Firebase
        final userCredential = await FirebaseService.createUser(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (userCredential != null) {
          // Create user document with additional info
          await FirebaseService.createUserDocument(
            _emailController.text.trim(),
            _usernameController.text.trim().isNotEmpty ? _usernameController.text.trim() : 'User',
            _selectedDepartment,
            _selectedRole,
          );
          
          // Save login data for persistence
          await AuthService.saveLoginData(
            userData: {
              'name': _usernameController.text.trim().isNotEmpty ? _usernameController.text.trim() : 'User',
              'email': _emailController.text.trim(),
              'department': _selectedDepartment,
              'role': _selectedRole,
              'employeeId': 'EMP${DateTime.now().millisecondsSinceEpoch}',
              'phone': 'Not provided',
              'joinDate': DateTime.now().toString().split(' ')[0],
            },
            authToken: userCredential.user?.uid,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Account created successfully with REAL Firebase!'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/dashboard');
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Registration failed. User may already exist.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Sign in with REAL Firebase
        final userCredential = await FirebaseService.signInUser(
          _emailController.text.trim(),
          _passwordController.text,
        );
        
        if (userCredential != null) {
          // Get user data from Firestore
          final userData = await FirebaseService.getUserData(_emailController.text.trim());
          
          // Save login data for persistence
          await AuthService.saveLoginData(
            userData: userData ?? {
              'name': 'User',
              'email': _emailController.text.trim(),
              'department': 'Unknown',
              'role': 'employee',
              'employeeId': 'EMP${DateTime.now().millisecondsSinceEpoch}',
              'phone': 'Not provided',
              'joinDate': DateTime.now().toString().split(' ')[0],
            },
            authToken: userCredential.user?.uid,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Signed in successfully with REAL Firebase!'),
                backgroundColor: Colors.green,
              ),
            );
            context.go('/dashboard');
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Invalid email or password'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _quickSetupAdmin() async {
    setState(() => _isLoading = true);
    
    try {
      // Create admin user with REAL Firebase
      final success = await FirebaseService.quickAdminSetup();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Admin setup complete with REAL Firebase! Use admin@sews.com / admin123'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        _emailController.text = 'admin@sews.com';
        _passwordController.text = 'admin123';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Admin setup failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo and Title
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.business,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'SEWS Connect',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp ? 'Create Admin Account' : 'Welcome Back',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quick Admin Setup Button
                    if (!_isSignUp)
                      ElevatedButton.icon(
                        onPressed: _quickSetupAdmin,
                        icon: const Icon(Icons.admin_panel_settings),
                        label: const Text('Quick Admin Setup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    if (!_isSignUp) const SizedBox(height: 24),

                    // Form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Username (only for sign up)
                          if (_isSignUp) ...[
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (_isSignUp && (value == null || value.isEmpty)) {
                                  return 'Please enter a username';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          TextFormField(
                            controller: _passwordController,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Department (only for sign up)
                          if (_isSignUp) ...[
                            DropdownButtonFormField<String>(
                              value: _selectedDepartment,
                              decoration: const InputDecoration(
                                labelText: 'Department',
                                prefixIcon: Icon(Icons.business),
                                border: OutlineInputBorder(),
                              ),
                              items: _departments.map((dept) => DropdownMenuItem(
                                value: dept,
                                child: Text(dept),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedDepartment = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                                prefixIcon: Icon(Icons.work),
                                border: OutlineInputBorder(),
                              ),
                              items: _roles.map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(role.toUpperCase()),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedRole = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                          ],

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    )
                                  : Text(
                                      _isSignUp ? 'Create Admin Account' : 'Sign In',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Toggle Sign Up/Sign In
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                _emailController.clear();
                                _passwordController.clear();
                                _usernameController.clear();
                              });
                            },
                            child: Text(
                              _isSignUp ? 'Already have an account? Sign In' : 'Need to create admin account? Sign Up',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

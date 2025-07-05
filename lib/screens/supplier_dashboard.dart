import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Main Supplier Dashboard Page, now styled like the AgreementTenderAdmin
class SupplierDashboard extends StatefulWidget {
  const SupplierDashboard({Key? key}) : super(key: key);

  @override
  State<SupplierDashboard> createState() => _SupplierDashboardState();
}

class _SupplierDashboardState extends State<SupplierDashboard> {
  // Define a consistent color palette based on the provided AgreementTenderAdmin code
  static const Color _primaryBlue = Color(0xFF0071CE); // Walmart Blue
  static const Color _secondaryGrey = Colors.grey;

  // User and company information
  User? _currentUser;
  String _companyName = 'Loading...';

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadUserData();
  }

  // Check Firebase Auth and load user data
  void _checkAuthAndLoadUserData() {
    _currentUser = FirebaseAuth.instance.currentUser;
    
    if (_currentUser == null) {
      // User not authenticated, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/welcome');
      });
    } else {
      // Load company name from user data
      _loadCompanyName();
    }
  }

  // Load company name (you can modify this based on your data structure)
  void _loadCompanyName() {
    setState(() {
      // You can get this from Firestore, user displayName, or any other source
      // For now, using a placeholder. Replace with actual data fetching logic.
      _companyName = _currentUser?.displayName ?? 'Your Company Name';
      
      // If you want to extract company name from email (example: company@domain.com)
      if (_companyName == 'Your Company Name' && _currentUser?.email != null) {
        String email = _currentUser!.email!;
        if (email.contains('@')) {
          String domain = email.split('@')[0];
          _companyName = domain.split('.')[0].toUpperCase() + ' Corp';
        }
      }
    });
  }

  // Feature password dialog (default: 12345678)
  void _showFeaturePasswordDialog(BuildContext context, String featureName, String routeName) {
    TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Access $featureName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter password to access $featureName:'),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                // Check password (default: 12345678)
                if (passwordController.text == '12345678') {
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Access granted to $featureName!')),
                  );
                  // Navigate to the feature page
                  _navigateToPage(context, routeName);
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Incorrect password')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Placeholder for Admin Password similar to the previous request's lock icon
  void _showAdminPasswordDialog(BuildContext context) {
    TextEditingController passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Admin Access Required'),
          content: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Enter Admin Password',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Submit'),
              onPressed: () {
                // TODO: Implement actual password verification logic here
                if (passwordController.text == 'admin123') { // Example password
                  Navigator.of(dialogContext).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Admin access granted!')),
                  );
                  // You might navigate to an admin-specific settings page here
                  // Navigator.pushNamed(context, '/admin_settings');
                } else {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Incorrect password')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if user data is not loaded yet
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100], // Light grey background for scaffold
      body: SafeArea(
        child: Column(
          children: [
            // Blue Header Section (mimicking AgreementTenderAdmin)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 40),
              decoration: const BoxDecoration(
                color: _primaryBlue, // Walmart Blue
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  // Top Row with back button and settings/lock icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          // Show admin password dialog when lock icon is tapped
                          _showAdminPasswordDialog(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock, // Admin lock icon
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Company Name
                  Text(
                    _companyName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Title Section
                  const Text(
                    'Supplier Dashboard',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage your operations efficiently',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // User email
                  Text(
                    'Welcome, ${_currentUser?.email ?? 'User'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),

            // White Content Section
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Select Your Role/Section',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Options List (Changed to your specified roles)
                   Expanded(
  child: ListView(
    children: [
      _buildOptionCard(
        'Agreement Admin',
        'Oversee tenders, contracts, and supplier agreements.',
        Icons.admin_panel_settings,
        const Color(0xFF4A90E2),
        () => _showFeaturePasswordDialog(context, 'Agreement Admin', '/agreement_suppplier_page'), // Corrected route name
      ),
      const SizedBox(height: 20),
      _buildOptionCard(
        'Truck Driver',
        'View assigned routes, deliveries, and logs.',
        Icons.local_shipping,
        const Color(0xFF7ED321),
        () => _showFeaturePasswordDialog(context, 'Truck Driver', '/truck_driver_dashboard'), // Corrected route name
      ),
      const SizedBox(height: 20),
      _buildOptionCard(
        'Logistics',
        'Manage inventory, warehousing, and supply chain.',
        Icons.bar_chart,
        const Color(0xFFF5A623),
        () => _showFeaturePasswordDialog(context, 'Logistics', '/logistics_page'), // Already correct
      ),
      const SizedBox(height: 20),
      _buildOptionCard(
        'Order Management',
        'Track and process incoming and outgoing orders.',
        Icons.shopping_bag,
        const Color(0xFFBD10E0),
        () => _showFeaturePasswordDialog(context, 'Order Management', '/order_management_page'), // Already correct
      ),
      const SizedBox(height: 30),
                          // Logout Button
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await FirebaseAuth.instance.signOut();
                                  if (context.mounted) {
                                    Navigator.pushReplacementNamed(context, '/welcome');
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error signing out: $e')),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.logout, color: Colors.white),
                              label: const Text(
                                'Logout',
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable option card widget from the AgreementTenderAdmin
  Widget _buildOptionCard(String title, String description, IconData icon, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 20),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // Navigation method - now properly handles routing
  void _navigateToPage(BuildContext context, String routeName) {
    try {
      Navigator.pushNamed(context, routeName);
    } catch (e) {
      // If named route doesn't exist, show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Route $routeName not found. Please check your route definitions.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
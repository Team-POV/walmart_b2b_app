import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:walmart_b2b_app/screens/roles/agreement_auction/activeagreement.dart';
import 'package:walmart_b2b_app/screens/roles/agreement_auction/auctionandtender.dart';
import 'package:walmart_b2b_app/screens/roles/agreement_tender_admin.dart';
import 'package:walmart_b2b_app/screens/roles/inventatory_admin.dart';
import 'package:walmart_b2b_app/screens/roles/logistis_management.dart';
import 'package:walmart_b2b_app/screens/roles/suplier_admin.dart';
import 'package:walmart_b2b_app/screens/roles/supppliers/bidding_suppier.dart';
import 'package:walmart_b2b_app/screens/roles/supppliers/logistis_supplier.dart';
import 'package:walmart_b2b_app/screens/roles/supppliers/managing_agreement.dart';
import 'package:walmart_b2b_app/screens/roles/supppliers/order_management_supplier.dart';



import 'package:walmart_b2b_app/screens/roles/truck_driver.dart';
import 'package:walmart_b2b_app/screens/roles/unloading_goods_admin.dart';
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_signup_screen.dart';
import 'screens/supplier_login_screen.dart';
import 'screens/supplier_signup_screen.dart';
import 'screens/admin_dashboard.dart';
import 'screens/supplier_dashboard.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supply Chain Management',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0071CE), // Walmart blue
          primary: const Color(0xFF0071CE),
          secondary: const Color(0xFF004C91),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0071CE),
          foregroundColor: Colors.white,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/admin-login': (context) => const AdminLoginScreen(),
        '/admin-signup': (context) => const AdminSignupScreen(),
        '/supplier-login': (context) => const SupplierLoginScreen(),
        '/supplier-signup': (context) => const SupplierSignupScreen(),
        '/admin-dashboard': (context) => const AdminRoleSelectionPage(),

        '/supplier-dashboard': (context) => const SupplierDashboard(),
        '/inventory_admin_dashboard': (context) =>  InventatoryAdmin(),
        '/agreement_tender_admin_dashboard': (context) =>  AgreementTenderAdmin(), 
        '/unloading_goods_admin_dashboard': (context) => UnloadingGoodsAdmin(),
        '/logistics_management_dashboard': (context) =>  LogistisManagement(),
        '/supplier_admin_dashboard': (context) =>  SuplierAdmin(),
        '/agreement_auctions':(context) => Auctionandtender(),
        '/agreement_active_agreements' :(context) => Activeagreement(),

        
        '/order_management_page':(context) => OrderManagementSupplier(),
        '/logistics_page':(context) => LogistisSupplier(),
     '/agreement_suppplier_page': (context) => SuplierAdmin(),
        '/truck_driver_dashboard': (context) => TruckDriver(),
        '/suppier_bidding_page': (context) => BiddingSuppier(),
        '/manageing_agreement': (context) => ManagingAgreement() }
    );
  }
}
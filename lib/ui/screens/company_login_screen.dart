import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/screens/home_screen.dart';
import 'package:mtc2026/database/database_helper.dart';
import 'package:mtc2026/models/project_models.dart';

class CompanyLoginScreen extends StatefulWidget {
  const CompanyLoginScreen({super.key});

  @override
  State<CompanyLoginScreen> createState() => _CompanyLoginScreenState();
}

class _CompanyLoginScreenState extends State<CompanyLoginScreen> {
  final _companyController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiUrlController = TextEditingController();
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Theme.of(context).primaryColor, const Color(0xFF3A0CA3)],
          ),
        ),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
              elevation: 20,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.business_rounded, size: 64, color: Colors.blue),
                    const SizedBox(height: 16),
                    const Text(
                      "MTC ERP CLOUD",
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: 2),
                    ),
                    const Text(
                      "Σύνδεση στην Εταιρεία σας",
                      style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _companyController,
                      decoration: InputDecoration(
                        labelText: "Όνομα Εταιρείας",
                        prefixIcon: const Icon(Icons.domain),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Κωδικός Πρόσβασης",
                        prefixIcon: const Icon(Icons.lock_person_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text("Ξέχασα τον κωδικό μου", style: TextStyle(fontSize: 11)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isConnecting ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isConnecting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("ΣΥΝΔΕΣΗ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => _showRegisterDialog(),
                      child: const Text("ΔΕΝ ΕΧΕΤΕ ΛΟΓΑΡΙΑΣΜΟ; ΕΓΓΡΑΦΗ ΕΤΑΙΡΕΙΑΣ"),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showManagerPinDialog(context),
                      icon: const Icon(Icons.engineering_rounded, size: 18),
                      label: const Text("ΣΥΝΔΕΣΗ ΩΣ ΥΠΕΥΘΥΝΟΣ (ΜΕ PIN)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  void _showManagerPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    Manager? selectedManager;
    final provider = Provider.of<ProjectProvider>(context, listen: false);
    
    DatabaseHelper().getManagers().then((managers) {
      if (managers.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Δεν υπάρχουν καταχωρημένοι υπεύθυνοι έργων. Δημιουργήστε έναν από το Κέντρο Ελέγχου.")));
        }
        return;
      }
      selectedManager = managers.first;

      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("ΣΥΝΔΕΣΗ ΥΠΕΥΘΥΝΟΥ ΕΡΓΟΥ", style: TextStyle(fontWeight: FontWeight.w900)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Manager>(
                    value: selectedManager,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: "Επιλογή Υπευθύνου", border: OutlineInputBorder()),
                    items: managers.map((m) => DropdownMenuItem(value: m, child: Text(m.name, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (v) => setDialogState(() => selectedManager = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: "PIN Πρόσβασης", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedManager != null && pinController.text.trim() == selectedManager!.pin) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('is_logged_in', true);
                      await provider.setCurrentManagerId(selectedManager!.id);
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Λανθασμένο PIN")));
                      }
                    }
                  },
                  child: const Text("ΣΥΝΔΕΣΗ"),
                ),
              ],
            ),
          ),
        );
      }
    });
  }

  void _showRegisterDialog() {
    final regCompanyController = TextEditingController(text: _companyController.text);
    final regPasswordController = TextEditingController(text: _passwordController.text);
    final regPhoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("ΕΓΓΡΑΦΗ ΝΕΑΣ ΕΤΑΙΡΕΙΑΣ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Δημιουργήστε έναν νέο λογαριασμό Cloud."),
              const SizedBox(height: 20),
              TextField(
                controller: regCompanyController,
                decoration: InputDecoration(
                  labelText: "Όνομα Εταιρείας",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: regPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Κωδικός Πρόσβασης",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: regPhoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Τηλέφωνο (για ανάκτηση)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleRegister(regCompanyController.text, regPasswordController.text, regPhoneController.text);
            },
            child: const Text("ΔΗΜΙΟΥΡΓΙΑ"),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final recoverCompanyController = TextEditingController(text: _companyController.text);
    final recoverPhoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ΑΝΑΚΤΗΣΗ ΠΡΟΣΒΑΣΗΣ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Εισάγετε το τηλέφωνο που δηλώσατε κατά την εγγραφή για να συνδεθείτε."),
            const SizedBox(height: 16),
            TextField(
              controller: recoverCompanyController,
              decoration: const InputDecoration(labelText: "Όνομα Εταιρείας"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: recoverPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: "Τηλέφωνο Ανάκτησης"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLoginPhone(recoverCompanyController.text, recoverPhoneController.text);
            },
            child: const Text("ΣΥΝΔΕΣΗ ΜΕ ΤΗΛΕΦΩΝΟ"),
          ),
        ],
      ),
    );
  }

  String _getCleanUrl() {
    return "https://mtc-m9in.onrender.com"; 
  }

  Future<void> _handleRegister(String company, String password, String phone) async {
    if (company.isEmpty || password.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Παρακαλώ συμπληρώστε όλα τα πεδία.")));
      return;
    }
    
    setState(() => _isConnecting = true);
    try {
      final baseUrl = _getCleanUrl();
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "companyName": company.trim(),
          "password": password.trim(),
          "phoneNumber": phone.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('company_name', data['companyName']);
        await prefs.setString('auth_token', data['token']);
        await prefs.setBool('is_logged_in', true);

        if (mounted) {
          final provider = Provider.of<ProjectProvider>(context, listen: false);
          await provider.clearLocalData();
          await provider.manualDownloadFromCloud();
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Σφάλμα εγγραφής: ${error['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Αποτυχία εγγραφής: $e")));
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _handleLogin() async {
    if (_companyController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Παρακαλώ συμπληρώστε όλα τα πεδία.")));
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final baseUrl = _getCleanUrl();
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "companyName": _companyController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('company_name', data['companyName']);
        await prefs.setString('auth_token', data['token']);
        await prefs.setBool('is_logged_in', true);

        if (mounted) {
          final provider = Provider.of<ProjectProvider>(context, listen: false);
          await provider.setCurrentManagerId(null);
          await provider.clearLocalData();
          await provider.manualDownloadFromCloud();
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      } else {
        final error = jsonDecode(response.body);
        if (response.statusCode == 400 && error['message'] == 'Λάθος στοιχεία σύνδεσης') {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Λάθος κωδικός ή όνομα εταιρείας.")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Σφάλμα: ${error['message']}")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Αποτυχία σύνδεσης: $e")));
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _handleLoginPhone(String company, String phone) async {
    if (company.isEmpty || phone.isEmpty) return;
    
    setState(() => _isConnecting = true);
    try {
      final baseUrl = _getCleanUrl();
      final response = await http.post(
        Uri.parse("$baseUrl/api/auth/login-phone"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "companyName": company.trim(),
          "phoneNumber": phone.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('company_name', data['companyName']);
        await prefs.setString('auth_token', data['token']);
        await prefs.setBool('is_logged_in', true);

        if (mounted) {
          final provider = Provider.of<ProjectProvider>(context, listen: false);
          await provider.setCurrentManagerId(null);
          await provider.clearLocalData();
          await provider.manualDownloadFromCloud();
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
        }
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Σφάλμα: ${error['message']}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Αποτυχία σύνδεσης: $e")));
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }
}

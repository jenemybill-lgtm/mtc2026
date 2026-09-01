import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/database/database_helper.dart';
import 'package:mtc2026/ui/screens/company_login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _ownerNameController;
  late TextEditingController _companyNameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _taglineController;
  late TextEditingController _vatNumberController;
  late TextEditingController _dbApiUrlController;
  late TextEditingController _aiApiUrlController;
  late TextEditingController _aiApiKeyController;
  late String _appTheme;
  late bool _isReminderEnabled;
  String? _logoUri;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<ProjectProvider>(context, listen: false).settings;
    _ownerNameController = TextEditingController(text: settings.ownerName);
    _companyNameController = TextEditingController(text: settings.companyName);
    _phoneController = TextEditingController(text: settings.phone);
    _emailController = TextEditingController(text: settings.email);
    _taglineController = TextEditingController(text: settings.tagline);
    _vatNumberController = TextEditingController(text: settings.vatNumber);
    _dbApiUrlController = TextEditingController(text: settings.dbApiUrl);
    _aiApiUrlController = TextEditingController(text: settings.aiApiUrl);
    _aiApiKeyController = TextEditingController(text: settings.aiApiKey);
    _appTheme = settings.appTheme;
    _isReminderEnabled = settings.isPaymentReminderEnabled;
    _logoUri = settings.logoUri;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("ΡΥΘΜΙΣΕΙΣ ΕΤΑΙΡΕΙΑΣ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white, letterSpacing: 1.5)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3A0CA3), Color(0xFF4361EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  _buildLogoHeader(),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: "ΣΤΟΙΧΕΙΑ ΕΠΙΧΕΙΡΗΣΗΣ",
                    icon: Icons.business_rounded,
                    child: Column(
                      children: [
                        _buildSettingsField(_companyNameController, "Όνομα Εταιρείας", Icons.domain),
                        const SizedBox(height: 16),
                        _buildSettingsField(_vatNumberController, "Α.Φ.Μ.", Icons.badge_rounded),
                        const SizedBox(height: 16),
                        _buildSettingsField(_taglineController, "Tagline / Σύνθημα", Icons.auto_fix_high_rounded),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: "ΕΜΦΑΝΙΣΗ",
                    icon: Icons.palette_rounded,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: ["SYSTEM", "LIGHT", "DARK"].map((theme) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: ChoiceChip(
                              label: Text(theme == "SYSTEM" ? "Σύστημα" : theme == "LIGHT" ? "Φωτεινό" : "Σκούρο", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              selected: _appTheme == theme,
                              onSelected: (val) => setState(() => _appTheme = theme),
                              selectedColor: const Color(0xFF4361EE),
                              labelStyle: TextStyle(color: _appTheme == theme ? Colors.white : Colors.black87),
                              showCheckmark: false,
                            ),
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: "ΕΠΙΚΟΙΝΩΝΙΑ",
                    icon: Icons.contact_mail_rounded,
                    child: Column(
                      children: [
                        _buildSettingsField(_ownerNameController, "Υπεύθυνος", Icons.person_rounded),
                        const SizedBox(height: 16),
                        _buildSettingsField(_phoneController, "Τηλέφωνο", Icons.phone_android_rounded, type: TextInputType.phone),
                        const SizedBox(height: 16),
                        _buildSettingsField(_emailController, "Email", Icons.email_rounded, type: TextInputType.emailAddress),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: "ΤΕΧΝΗΤΗ ΝΟΗΜΟΣΥΝΗ (AI)",
                    icon: Icons.psychology_rounded,
                    child: Column(
                      children: [
                        _buildSettingsField(_aiApiUrlController, "AI API URL", Icons.link_rounded),
                        const SizedBox(height: 16),
                        _buildSettingsField(_aiApiKeyController, "AI API Key", Icons.key_rounded, type: TextInputType.visiblePassword),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SettingsSection(
                    title: "CLOUD & ΑΣΦΑΛΕΙΑ",
                    icon: Icons.cloud_done_rounded,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                label: "BACKUP",
                                icon: Icons.upload_rounded,
                                color: Colors.blueGrey,
                                onTap: () => DatabaseHelper().backupDatabase(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildActionButton(
                                label: "RESTORE",
                                icon: Icons.download_rounded,
                                color: const Color(0xFF4361EE),
                                onTap: _handleRestore,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _handleLogout,
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text("ΑΠΟΣΥΝΔΕΣΗ ΑΠΟ ΕΤΑΙΡΕΙΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSettings,
        backgroundColor: const Color(0xFF4361EE),
        label: const Text("ΑΠΟΘΗΚΕΥΣΗ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, color: Colors.white)),
        icon: const Icon(Icons.check_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          if (_logoUri != null && _logoUri!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(File(_logoUri!), height: 100, fit: BoxFit.contain),
            )
          else
            Container(
              height: 100, width: 100,
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: const Icon(Icons.business_rounded, size: 48, color: Colors.blue),
            ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _pickLogo,
            icon: const Icon(Icons.add_a_photo_rounded, size: 18),
            label: const Text("ΑΛΛΑΓΗ ΛΟΓΟΤΥΠΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: BorderSide(color: Colors.blue.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.blueGrey.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.grey.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildActionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Future<void> _handleRestore() async {
    try {
      PlatformFile? result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (result != null) {
        File file = File(result.path!);
        await DatabaseHelper().restoreDatabase(file);
        if (mounted) {
          Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Επιτυχής Επαναφορά!")));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Σφάλμα: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _logoUri = image.path);
    }
  }

  void _saveSettings() {
    final newSettings = Settings(
      ownerName: _ownerNameController.text,
      companyName: _companyNameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      tagline: _taglineController.text,
      vatNumber: _vatNumberController.text,
      appTheme: _appTheme,
      isPaymentReminderEnabled: _isReminderEnabled,
      logoUri: _logoUri,
      dbApiUrl: _dbApiUrlController.text,
      aiApiUrl: _aiApiUrlController.text,
      aiApiKey: _aiApiKeyController.text,
    );
    Provider.of<ProjectProvider>(context, listen: false).updateSettings(newSettings);
    Navigator.pop(context);
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const CompanyLoginScreen()),
        (route) => false,
      );
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _SettingsSection({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF4361EE)),
              const SizedBox(width: 8),
              Text(
                title, 
                style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 11, letterSpacing: 1.2)
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.black.withValues(alpha: 0.04), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 4)),
              BoxShadow(color: const Color(0xFF4361EE).withValues(alpha: 0.01), blurRadius: 40, offset: const Offset(0, 10)),
            ],
          ),
          child: child,
        ),
      ],
    );
  }
}

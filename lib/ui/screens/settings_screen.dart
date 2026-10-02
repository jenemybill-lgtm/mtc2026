import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:file_selector/file_selector.dart';
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
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: const Color(0xFFE2E8F0),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF3A0CA3),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3A0CA3), Color(0xFF4361EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            title: const Text(
              "ΡΥΘΜΙΣΕΙΣ ΕΤΑΙΡΕΙΑΣ", 
              style: TextStyle(
                fontWeight: FontWeight.w900, 
                fontSize: 16, 
                color: Colors.white, 
                letterSpacing: 1.2,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  children: [
                    _buildLogoHeader(),
                    const SizedBox(height: 24),
                    if (isDesktop)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                _buildCompanySection(),
                                const SizedBox(height: 24),
                                _buildContactSection(),
                                const SizedBox(height: 24),
                                _buildAppearanceSection(),
                                const SizedBox(height: 24),
                                _buildAiSection(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              children: [
                                _buildCloudSection(),
                                const SizedBox(height: 24),
                                _buildAccessSection(),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          _buildCompanySection(),
                          const SizedBox(height: 24),
                          _buildAppearanceSection(),
                          const SizedBox(height: 24),
                          _buildContactSection(),
                          const SizedBox(height: 24),
                          _buildAiSection(),
                          const SizedBox(height: 24),
                          _buildAccessSection(),
                          const SizedBox(height: 24),
                          _buildCloudSection(),
                        ],
                      ),
                    const SizedBox(height: 100),
                  ],
                ),
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

  Widget _buildCompanySection() {
    return _SettingsSection(
      title: "ΣΤΟΙΧΕΙA ΕΠΙΧΕΙΡΗΣΗΣ",
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
    );
  }

  Widget _buildAppearanceSection() {
    final provider = Provider.of<ProjectProvider>(context, listen: false);

    Widget buildThemeOption(String themeKey, String label, IconData icon) {
      final isSelected = _appTheme == themeKey;
      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() => _appTheme = themeKey);
            final updatedSettings = provider.settings.copyWith(appTheme: themeKey);
            provider.updateSettings(updatedSettings);
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4361EE) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF4361EE) : Colors.black.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: const Color(0xFF4361EE).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? Colors.white : const Color(0xFF4361EE),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _SettingsSection(
      title: "ΕΜΦΑΝΙΣΗ",
      icon: Icons.palette_rounded,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            buildThemeOption("SYSTEM", "Σύστημα", Icons.settings_suggest_rounded),
            const SizedBox(width: 8),
            buildThemeOption("LIGHT", "Φωτεινό", Icons.wb_sunny_rounded),
            const SizedBox(width: 8),
            buildThemeOption("DARK", "Σκούρο", Icons.nightlight_round),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return _SettingsSection(
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
    );
  }

  Widget _buildAiSection() {
    return _SettingsSection(
      title: "ΤΕΧΝΗΤΗ ΝΟΗΜΟΣΥΝΗ (AI)",
      icon: Icons.psychology_rounded,
      child: Column(
        children: [
          _buildSettingsField(_aiApiUrlController, "AI API URL", Icons.link_rounded),
          const SizedBox(height: 16),
          _buildSettingsField(_aiApiKeyController, "AI API Key", Icons.key_rounded, type: TextInputType.visiblePassword),
        ],
      ),
    );
  }

  Widget _buildAccessSection() {
    return _SettingsSection(
      title: "ΠΡΟΣΒΑΣΗ & ΥΠΕΥΘΥΝΟΙ ΕΡΓΩΝ",
      icon: Icons.engineering_rounded,
      child: FutureBuilder<List<Manager>>(
        future: DatabaseHelper().getManagers(),
        builder: (context, snapshot) {
          final managers = snapshot.data ?? [];
          final provider = Provider.of<ProjectProvider>(context);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                provider.currentManagerId == null 
                  ? "Τρέχων Ρόλος: ΔΙΑΧΕΙΡΙΣΤΗΣ / ΑΦΕΝΤΙΚΟ (Όλα τα έργα)" 
                  : "Τρέχων Ρόλος: Υπεύθυνος Έργου",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: provider.currentManagerId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: "Προβολή ανά Υπεύθυνο", border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text("Προβολή Όλων (Διαχειριστής)", style: TextStyle(fontWeight: FontWeight.bold))),
                  ...managers.map((m) => DropdownMenuItem<int?>(value: m.id, child: Text(m.name))),
                ],
                onChanged: (v) async {
                  await provider.setCurrentManagerId(v);
                  setState(() {});
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(v == null ? "Προβολή όλων των έργων" : "Προβολή έργων υπευθύνου")));
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCloudSection() {
    return _SettingsSection(
      title: "CLOUD & ΑΣΦΑΛΕΙΑ",
      icon: Icons.cloud_done_rounded,
      child: Consumer<ProjectProvider>(
        builder: (context, provider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ΣΥΓΧΡΟΝΙΣΜΟΣ ΔΕΔΟΜΕΝΩΝ (CLOUD SYNC)",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              if (provider.isSyncing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 12),
                        Text("Συγχρονισμός σε εξέλιξη...", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                      ],
                    ),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleCloudUpload(context, provider),
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: const Text("UPLOAD CLOUD", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleCloudDownload(context, provider),
                        icon: const Icon(Icons.cloud_download_rounded, size: 18),
                        label: const Text("DOWNLOAD CLOUD", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3A0CA3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                "ΤΟΠΙΚΑ ΑΝΤΙΓΡΑΦΑ ΑΣΦΑΛΕΙΑΣ (LOCAL BACKUP)",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Colors.blueGrey, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      label: "BACKUP",
                      icon: Icons.upload_file_rounded,
                      color: Colors.blueGrey,
                      onTap: _handleBackup,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      label: "RESTORE",
                      icon: Icons.restore_page_rounded,
                      color: const Color(0xFF4361EE),
                      onTap: _handleRestore,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAutoBackupsDialog,
                  icon: const Icon(Icons.history_rounded, size: 18),
                  label: const Text("ΜΗΧΑΝΗ ΤΟΥ ΧΡΟΝΟΥ (ΑΥΤΟΜΑΤΑ BACKUPS)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF72585),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text("ΑΠΟΣΥΝΔΕΣΗ ΑΠΟ ΕΤΑΙΡΕΙΑ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          );
        },
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
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF475569)),
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF4361EE)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF4361EE), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

  Future<void> _handleCloudUpload(BuildContext context, ProjectProvider provider) async {
    // 1. Take Auto Backup
    await DatabaseHelper().backupDatabase(autoBackup: true);

    final errorMsg = await provider.manualUploadToCloud(includePhotos: false);
    if (context.mounted) {
      final success = errorMsg == null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? "Τα δεδομένα ανέβηκαν επιτυχώς στο Cloud!" : errorMsg),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
    }
  }

  Future<void> _handleCloudDownload(BuildContext context, ProjectProvider provider) async {
    // 1. Take Auto Backup
    await DatabaseHelper().backupDatabase(autoBackup: true);

    final errorMsg = await provider.manualDownloadFromCloud();
    if (context.mounted) {
      final success = errorMsg == null;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? "Τα δεδομένα λήφθηκαν επιτυχώς από το Cloud!" : errorMsg),
        backgroundColor: success ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ));
    }
  }

  Future<void> _handleBackup() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Δημιουργία Αντιγράφου Ασφαλείας...", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final path = await DatabaseHelper().backupDatabase();
      if (mounted) Navigator.pop(context);

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Το Backup δημιουργήθηκε επιτυχώς!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Σφάλμα κατά το Backup: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Backups',
        extensions: <String>['json', 'zip'],
      );
      final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      
      if (file != null && file.path.isNotEmpty) {
        File backupFile = File(file.path);
        await DatabaseHelper().restoreDatabase(backupFile);
        if (mounted) {
          Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Επιτυχής Επαναφορά!"), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Σφάλμα: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _showAutoBackupsDialog() async {
    final files = await DatabaseHelper().getAutoBackups();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.history_rounded, color: Color(0xFFF72585)),
            SizedBox(width: 8),
            Text("ΜΗΧΑΝΗ ΤΟΥ ΧΡΟΝΟΥ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: files.isEmpty 
          ? const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Δεν υπάρχουν ακόμα αυτόματα backups. Θα δημιουργηθούν μόλις κάνετε Upload / Download από το Cloud.", style: TextStyle(color: Colors.grey)),
            )
          : ListView.separated(
              shrinkWrap: true,
              itemCount: files.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final file = files[index];
                final name = file.path.split(Platform.pathSeparator).last;
                final dateStr = name.replaceAll('auto_backup_', '').replaceAll('.zip', ''); // 20260930_0405
                String displayDate = name;
                if (dateStr.length == 13) {
                  try {
                    final year = dateStr.substring(0, 4);
                    final month = dateStr.substring(4, 6);
                    final day = dateStr.substring(6, 8);
                    final hour = dateStr.substring(9, 11);
                    final min = dateStr.substring(11, 13);
                    displayDate = "$day/$month/$year - $hour:$min";
                  } catch (_) {}
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFF72585).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.settings_backup_restore_rounded, color: Color(0xFFF72585)),
                  ),
                  title: const Text("Αυτόματο Αντίγραφο", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  subtitle: Text(displayDate, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4361EE), padding: const EdgeInsets.symmetric(horizontal: 12)),
                    onPressed: () async {
                      Navigator.pop(context);
                      await _restoreAutoBackup(file);
                    },
                    child: const Text("ΕΠΑΝΑΦΟΡΑ", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
                  ),
                );
              },
            ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("ΚΛΕΙΣΙΜΟ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey))
          ),
        ],
      ),
    );
  }

  Future<void> _restoreAutoBackup(File file) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Επαναφορά από το παρελθόν...", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      await DatabaseHelper().restoreDatabase(file);
      if (mounted) {
        Provider.of<ProjectProvider>(context, listen: false).fetchProjects();
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Επιτυχής Επαναφορά! Η εφαρμογή επέστρεψε στον χρόνο."), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Σφάλμα: $e"), backgroundColor: Colors.red));
      }
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

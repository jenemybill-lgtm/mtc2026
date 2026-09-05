import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/utils/responsive.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';
import 'package:mtc2026/ui/screens/project_main_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectProvider = Provider.of<ProjectProvider>(context);
    
    final leads = projectProvider.projects.where((p) => p.status == 0).toList();
    final activeProjects = projectProvider.projects.where((p) => p.status == 1).toList();
    final completedProjects = projectProvider.projects.where((p) => p.status == 2).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΔΙΑΧΕΙΡΙΣΗ ΕΡΓΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF4361EE),
                  boxShadow: [BoxShadow(color: const Color(0xFF4361EE).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.blueGrey,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: "ΠΡΟΣΦΟΡΕΣ (${leads.length})"),
                  Tab(text: "ΕΝΕΡΓΑ (${activeProjects.length})"),
                  Tab(text: "ΑΡΧΕΙΟ (${completedProjects.length})"),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProjectDialog(context),
        label: const Text("ΝΕΟ ΕΡΓΟ", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ProjectList(projects: leads, tabIndex: 0),
          _ProjectList(projects: activeProjects, tabIndex: 1),
          _ProjectList(projects: completedProjects, tabIndex: 2),
        ],
      ),
    );
  }

  void _showProjectDialog(BuildContext context, {Project? project}) {
    showDialog(
      context: context,
      builder: (context) => ProjectEntryDialog(
        initialProject: project,
        onConfirm: (name, client, address, phone, email, clientId, isCompleted, startDate, deliveryDate, isLead, proposalValue, managerId) {
          final status = isLead ? 0 : (isCompleted ? 2 : 1);
          if (project == null) {
            Provider.of<ProjectProvider>(context, listen: false).addProject(Project(
              name: name,
              clientName: client,
              clientId: clientId,
              address: address,
              clientPhone: phone,
              clientEmail: email,
              startDate: startDate,
              deliveryDate: deliveryDate,
              status: status,
              proposalValue: proposalValue,
              managerId: managerId,
            ));
          } else {
            Provider.of<ProjectProvider>(context, listen: false).updateProject(project.copyWith(
              name: name,
              clientName: client,
              clientId: clientId,
              address: address,
              clientPhone: phone,
              clientEmail: email,
              isCompleted: isCompleted,
              startDate: startDate,
              deliveryDate: deliveryDate,
              status: status,
              proposalValue: proposalValue,
              managerId: managerId,
            ));
          }
        },
      ),
    );
  }
}

class _ProjectList extends StatelessWidget {
  final List<Project> projects;
  final int tabIndex;
  const _ProjectList({required this.projects, required this.tabIndex});

  static const List<Color> projectPalette = [
    Color(0xFF4361EE), 
    Color(0xFF7209B7), 
    Color(0xFFF72585), 
    Color(0xFF4CC9F0), 
    Color(0xFF38B000)
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), shape: BoxShape.circle),
              child: Icon(Icons.business_center_rounded, size: 64, color: Colors.blueGrey.withValues(alpha: 0.2)),
            ),
            const SizedBox(height: 24),
            const Text("Δεν βρέθηκαν έργα", style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E293B), fontSize: 16)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF1E293B).withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 20),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("ΣΥΝΟΛΙΚΗ ΕΙΚΟΝΑ", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white60, letterSpacing: 1.5)),
                      SizedBox(height: 4),
                      Text("ΧΑΡΤΟΦΥΛΑΚΙΟ ΕΡΓΩΝ", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      "${projects.length}", 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)
                    ),
                  ),
                ],
              ),
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 4 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isDesktop ? 3.2 : 3.2,
          ),
          itemCount: projects.length,
          itemBuilder: (context, index) {
            final project = projects[index];
            final color = project.status == 2
                ? Colors.blueGrey
                : project.status == 0
                    ? Colors.orangeAccent
                    : projectPalette[index % projectPalette.length];
            
            return ProjectCardPremium(
              project: project,
              accentColor: color,
              onClick: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectMainScreen(project: project)));
              },
              onLongClick: () => _showManageDialog(context, project, tabIndex),
            );
          },
        ),
      ],
    );
  }

  void _showManageDialog(BuildContext context, Project project, int currentTabIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        title: PremiumHeader(title: project.name.toUpperCase(), icon: Icons.edit_note_rounded),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (project.status == 0)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.play_circle_fill_rounded, color: Colors.green, size: 20),
                ),
                title: const Text("ΕΝΑΡΞΗ ΕΡΓΟΥ (ACTIVE)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  Provider.of<ProjectProvider>(context, listen: false).updateProject(project.copyWith(status: 1));
                },
              ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
              ),
              title: const Text("ΕΠΕΞΕΡΓΑΣΙΑ ΣΤΟΙΧΕΙΩΝ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, project);
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.delete_forever_rounded, color: Colors.red, size: 20),
              ),
              title: const Text("ΔΙΑΓΡΑΦΗ ΕΡΓΟΥ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirm(context, project);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => ProjectEntryDialog(
        initialProject: project,
        onConfirm: (name, client, address, phone, email, clientId, isCompleted, startDate, deliveryDate, isLead, proposalValue, managerId) {
          final status = isLead ? 0 : (isCompleted ? 2 : 1);
          Provider.of<ProjectProvider>(context, listen: false).updateProject(project.copyWith(
            name: name,
            clientName: client,
            clientId: clientId,
            address: address,
            clientPhone: phone,
            clientEmail: email,
            isCompleted: isCompleted,
            startDate: startDate,
            deliveryDate: deliveryDate,
            status: status,
            proposalValue: proposalValue,
            managerId: managerId,
          ));
        },
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text("ΔΙΑΓΡΑΦΗ ΕΡΓΟΥ", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("Είστε σίγουροι ότι θέλετε να διαγράψετε το έργο '${project.name}'; Όλα τα δεδομένα θα χαθούν οριστικά."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
          ElevatedButton(
            onPressed: () {
              Provider.of<ProjectProvider>(context, listen: false).deleteProject(project.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("ΔΙΑΓΡΑΦΗ", style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class ProjectCardPremium extends StatelessWidget {
  final Project project;
  final Color accentColor;
  final VoidCallback onClick;
  final VoidCallback onLongClick;

  const ProjectCardPremium({super.key, required this.project, required this.accentColor, required this.onClick, required this.onLongClick});

  @override
  Widget build(BuildContext context) {
    final isCompleted = project.isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08), width: 1.0),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onClick,
          onLongPress: onLongClick,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle_outline_rounded : Icons.business_center_rounded,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          project.name.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A), letterSpacing: -0.2),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        project.clientName.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 8, color: accentColor.withValues(alpha: 0.8), letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.blueGrey.withValues(alpha: 0.2), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProjectEntryDialog extends StatefulWidget {
  final Project? initialProject;
  final Function(String, String, String, String, String, int?, bool, int, int?, bool, double, int?) onConfirm;

  const ProjectEntryDialog({super.key, this.initialProject, required this.onConfirm});

  @override
  State<ProjectEntryDialog> createState() => _ProjectEntryDialogState();
}

class _ProjectEntryDialogState extends State<ProjectEntryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _clientController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _proposalController;
  late bool _isCompleted;
  late bool _isLead;
  late int _startDate;
  int? _deliveryDate;
  Client? _selectedClient;
  int? _selectedManagerId;

  @override
  void initState() {
    super.initState();
    final clients = Provider.of<ProjectProvider>(context, listen: false).clients;
    _selectedClient = _findClientByProject(clients, widget.initialProject);
    _nameController = TextEditingController(text: widget.initialProject?.name ?? "");
    _clientController = TextEditingController(text: _selectedClient?.name ?? widget.initialProject?.clientName ?? "");
    _addressController = TextEditingController(text: widget.initialProject?.address ?? "");
    _phoneController = TextEditingController(text: _selectedClient?.phone ?? widget.initialProject?.clientPhone ?? "");
    _emailController = TextEditingController(text: _selectedClient?.email ?? widget.initialProject?.clientEmail ?? "");
    _proposalController = TextEditingController(text: widget.initialProject?.proposalValue.toString() ?? "0.0");
    _isCompleted = widget.initialProject?.status == 2;
    _isLead = widget.initialProject?.status == 0;
    _startDate = widget.initialProject?.startDate ?? DateTime.now().millisecondsSinceEpoch;
    _deliveryDate = widget.initialProject?.deliveryDate;
    _selectedManagerId = widget.initialProject?.managerId;
  }

  Client? _findClientByProject(List<Client> clients, Project? project) {
    if (project == null) return null;
    if (project.clientId != null) {
      return clients.firstWhere(
        (client) => client.id == project.clientId,
        orElse: () => clients.firstWhere(
          (client) => client.name.trim().toLowerCase() == project.clientName.trim().toLowerCase(),
          orElse: () => Client(name: project.clientName, phone: project.clientPhone, email: project.clientEmail),
        ),
      );
    }
    return clients.firstWhere(
      (client) => client.name.trim().toLowerCase() == project.clientName.trim().toLowerCase(),
      orElse: () => Client(name: project.clientName, phone: project.clientPhone, email: project.clientEmail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clients = Provider.of<ProjectProvider>(context).clients
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final managers = Provider.of<ProjectProvider>(context).managers;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      title: PremiumHeader(
        title: widget.initialProject == null ? "ΔΗΜΙΟΥΡΓΙΑ ΕΡΓΟΥ" : "ΕΠΕΞΕΡΓΑΣΙΑ ΣΤΟΙΧΕΙΩΝ",
        icon: Icons.add_business_rounded
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Όνομα Έργου", prefixIcon: Icon(Icons.business_rounded, size: 20))),
              const SizedBox(height: 12),
              Autocomplete<Client>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final query = textEditingValue.text.trim();
                  if (query.isEmpty) {
                    return clients;
                  }
                  return clients.where((client) =>
                    client.name.toLowerCase().contains(query.toLowerCase()) ||
                    client.phone.contains(query));
                },
                displayStringForOption: (client) => client.name,
                fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                  _clientController = controller;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: "Πελάτης (από το πελατολόγιο)",
                      prefixIcon: Icon(Icons.person_rounded, size: 20),
                    ),
                    onChanged: (value) {
                      final normalized = value.trim();
                      final match = clients.firstWhere(
                        (client) => client.name.trim().toLowerCase() == normalized.toLowerCase(),
                        orElse: () => Client(name: "", phone: "", email: ""),
                      );
                      if (normalized.isNotEmpty && match.name.isNotEmpty) {
                        setState(() {
                          _selectedClient = match;
                          _phoneController.text = match.phone;
                          _emailController.text = match.email;
                        });
                      } else if (normalized.isEmpty) {
                        setState(() {
                          _selectedClient = null;
                        });
                      } else {
                        setState(() {
                          _selectedClient = null;
                        });
                      }
                    },
                  );
                },
                onSelected: (client) {
                  setState(() {
                    _selectedClient = client;
                    _clientController.text = client.name;
                    _phoneController.text = client.phone;
                    _emailController.text = client.email;
                  });
                },
              ),
              if (clients.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    "Δεν υπάρχουν πελάτες στο πελατολόγιο. Δημιούργησε πρώτα έναν πελάτη.",
                    style: TextStyle(fontSize: 11, color: Colors.orange.shade800, fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(height: 12),
              TextField(controller: _phoneController, decoration: const InputDecoration(labelText: "Τηλέφωνο", prefixIcon: Icon(Icons.phone_rounded, size: 20)), keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email", prefixIcon: Icon(Icons.email_rounded, size: 20)), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              TextField(controller: _addressController, decoration: const InputDecoration(labelText: "Διεύθυνση", prefixIcon: Icon(Icons.location_on_rounded, size: 20))),
              const SizedBox(height: 12),
              TextField(controller: _proposalController, decoration: const InputDecoration(labelText: "Προϋπολογισμός (€)", prefixIcon: Icon(Icons.euro_rounded, size: 20)), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<int?>(
                value: _selectedManagerId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: "Υπεύθυνος Έργου", prefixIcon: Icon(Icons.engineering_rounded, size: 20)),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text("Χωρίς Υπεύθυνο (Γενικό)", style: TextStyle(color: Colors.grey, fontSize: 13))),
                  ...managers.map((m) => DropdownMenuItem<int?>(value: m.id, child: Text(m.name, style: const TextStyle(fontSize: 14)))),
                ],
                onChanged: (v) => setState(() => _selectedManagerId = v),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.fromMillisecondsSinceEpoch(_startDate),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => _startDate = date.millisecondsSinceEpoch);
                      },
                      child: Column(
                        children: [
                          const Text("ΕΝΑΡΞΗ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(DateFormat('dd/MM/yy').format(DateTime.fromMillisecondsSinceEpoch(_startDate)), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _deliveryDate != null ? DateTime.fromMillisecondsSinceEpoch(_deliveryDate!) : DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) setState(() => _deliveryDate = date.millisecondsSinceEpoch);
                      },
                      child: Column(
                        children: [
                          const Text("ΠΑΡΑΔΟΣΗ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1)),
                          const SizedBox(height: 4),
                          Text(_deliveryDate == null ? "ΟΡΙΣΜΟΣ" : DateFormat('dd/MM/yy').format(DateTime.fromMillisecondsSinceEpoch(_deliveryDate!)), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                child: SwitchListTile(
                  title: const Text("Μόνο Προσφορά (Lead)", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Δεν έχει ξεκινήσει ακόμα", style: TextStyle(fontSize: 10)),
                  value: _isLead,
                  onChanged: (value) => setState(() {
                    _isLead = value;
                    if (_isLead) _isCompleted = false;
                  }),
                ),
              ),
              if (widget.initialProject != null || !_isLead) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                  child: SwitchListTile(
                    title: const Text("Ολοκληρωμένο Έργο", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Μεταφορά στο αρχείο", style: TextStyle(fontSize: 10)),
                    value: _isCompleted,
                    onChanged: (value) => setState(() {
                      _isCompleted = value;
                      if (_isCompleted) _isLead = false;
                    }),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("ΑΚΥΡΟ", style: TextStyle(fontWeight: FontWeight.w900))),
        ElevatedButton(
          onPressed: () {
            final clientName = _clientController.text.trim();
            final validClient = Provider.of<ProjectProvider>(context, listen: false).clients.firstWhere(
              (client) => client.name.trim().toLowerCase() == clientName.toLowerCase(),
              orElse: () => Client(name: "", phone: "", email: ""),
            );
            if (_nameController.text.trim().isNotEmpty && (clientName.isNotEmpty || widget.initialProject != null)) {
              widget.onConfirm(
                _nameController.text.trim(),
                validClient.name.isNotEmpty ? validClient.name : clientName,
                _addressController.text.trim(),
                validClient.name.isNotEmpty ? validClient.phone : _phoneController.text.trim(),
                validClient.name.isNotEmpty ? validClient.email : _emailController.text.trim(),
                validClient.name.isNotEmpty ? validClient.id : widget.initialProject?.clientId,
                _isCompleted,
                _startDate,
                _deliveryDate,
                _isLead,
                double.tryParse(_proposalController.text.replaceAll(',', '.')) ?? 0.0,
                _selectedManagerId,
              );
              Navigator.pop(context);
            }
          },
          child: Text(widget.initialProject == null ? "ΔΗΜΙΟΥΡΓΙΑ" : "ΑΠΟΘΗΚΕΥΣΗ", style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}

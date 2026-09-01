import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtc2026/models/project_models.dart';
import 'package:mtc2026/providers/project_provider.dart';
import 'package:mtc2026/ui/components/premium_ui.dart';

class GlobalPayrollScreen extends StatefulWidget {
  const GlobalPayrollScreen({super.key});

  @override
  State<GlobalPayrollScreen> createState() => _GlobalPayrollScreenState();
}

class _GlobalPayrollScreenState extends State<GlobalPayrollScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProjectProvider>(context);
    final partners = provider.partners;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text("ΚΕΝΤΡΙΚΟ ΤΑΜΕΙΟ ΣΥΝΕΡΓΑΤΩΝ", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
      ),
      body: FutureBuilder<Map<String, _WorkerBalance>>(
        future: _calculateGlobalBalances(provider),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final balances = snapshot.data!;

          if (balances.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.blue.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  const Text("Δεν βρέθηκαν οικονομικά στοιχεία συνεργατών.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }

          final sortedNames = balances.keys.toList()..sort((a, b) => balances[b]!.owed.compareTo(balances[a]!.owed));

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: sortedNames.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final name = sortedNames[index];
              final data = balances[name]!;
              return _GlobalWorkerCard(name: name, data: data);
            },
          );
        },
      ),
    );
  }

  Future<Map<String, _WorkerBalance>> _calculateGlobalBalances(ProjectProvider provider) async {
    final Map<String, _WorkerBalance> results = {};

    // 1. Get all earnings (Attendance)
    final allAttendance = await provider.getAttendance(null, null, null);
    for (var att in allAttendance) {
      final balance = results.putIfAbsent(att.workerName, () => _WorkerBalance());
      balance.earned += att.dailyRate + att.overtimeAmount;
    }

    // 2. Get all payments (Expenses of type PAYMENT)
    final allExpenses = await provider.getAllExpenses();
    for (var exp in allExpenses) {
      if (exp.expenseType == "PAYMENT") {
        final balance = results.putIfAbsent(exp.workerName, () => _WorkerBalance());
        balance.paid += exp.amount;
      }
    }

    return results;
  }
}

class _WorkerBalance {
  double earned = 0.0;
  double paid = 0.0;
  double get owed => earned - paid;
}

class _GlobalWorkerCard extends StatelessWidget {
  final String name;
  final _WorkerBalance data;

  const _GlobalWorkerCard({required this.name, required this.data});

  @override
  Widget build(BuildContext context) {
    final color = data.owed > 0 ? Colors.redAccent : Colors.green;

    return PremiumCard(
      accentColor: color,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.person_rounded, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("ΥΠΟΛΟΙΠΟ", style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.blueGrey)),
                  Text("${data.owed.toStringAsFixed(2)} €", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: color, letterSpacing: -0.5)),
                ],
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat("ΔΕΔΟΥΛΕΥΜΕΝΑ", "${data.earned.toStringAsFixed(0)} €", Colors.blueGrey),
              _miniStat("ΠΛΗΡΩΜΕΣ", "${data.paid.toStringAsFixed(0)} €", Colors.blueGrey, align: CrossAxisAlignment.end),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color, {CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: color.withValues(alpha: 0.6), letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class BillsScreen extends StatelessWidget {
  static const String routeName = '/bills';

  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bills'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final bill = _mockBills[index];
          return _BillTile(bill: bill);
        },
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemCount: _mockBills.length,
      ),
    );
  }
}

class _BillTile extends StatefulWidget {
  final _Bill bill;

  const _BillTile({required this.bill});

  @override
  State<_BillTile> createState() => _BillTileState();
}

class _BillTileState extends State<_BillTile> {
  bool _remind = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon
          CircleAvatar(
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.08),
            child: Icon(widget.bill.icon, color: AppTheme.primaryGreen, size: 20),
          ),
          const SizedBox(width: 16),
          // Bill info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.bill.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  'Due ${widget.bill.dueDate}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          // Amount and switch
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.bill.amount,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Transform.scale(
                scale: 0.8,
                alignment: Alignment.centerRight,
                child: Switch.adaptive(
                  value: _remind,
                  onChanged: (v) {
                    setState(() => _remind = v);
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bill {
  final String name;
  final String amount;
  final String dueDate;
  final IconData icon;

  const _Bill({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.icon,
  });
}

// Mock bills, phỏng đoán từ context app.
const _mockBills = <_Bill>[
  _Bill(
    name: 'Electricity Bill',
    amount: '500,000',
    dueDate: '25 Nov 2025',
    icon: Icons.flash_on_outlined,
  ),
  _Bill(
    name: 'Internet',
    amount: '800,000',
    dueDate: '28 Nov 2025',
    icon: Icons.wifi_outlined,
  ),
  _Bill(
    name: 'Water Bill',
    amount: '200,000',
    dueDate: '30 Nov 2025',
    icon: Icons.water_drop_outlined,
  ),
];

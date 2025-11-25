import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/receipt_service.dart';
import '../../theme/app_theme.dart';
import 'select_category_screen.dart';

/// Transaction detail / Add transaction screen.
/// Layout được phỏng đoán dựa trên screenshot "Add transaction".
class TransactionDetailScreen extends StatefulWidget {
  static const String routeName = '/transaction-detail';

  const TransactionDetailScreen({super.key});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showCalculator = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _receiptImages = <XFile>[];
  String? _receiptError;
  final ReceiptRepository _receiptRepository = ReceiptRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isTablet = media.size.width > 600;
    final horizontalPadding = isTablet ? media.size.width * 0.08 : 16.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Add transaction'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
            Tab(text: 'Debt/Loan'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
              child: Column(
                children: [
                  _RowItem(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: 'Cash',
                    subtitle: 'Wallet · Tap to add bank account',
                    showChevron: true,
                    onTap: () {
                      _showAddAccountDialog(context);
                    },
                  ),
                  const SizedBox(height: 12),
                  _AmountField(
                    controller: _amountController,
                    onTap: () {
                      setState(() {
                        _showCalculator = !_showCalculator;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.category_outlined),
                    title: 'Select category',
                    subtitle: 'Tap to choose',
                    showChevron: true,
                    onTap: () {
                      Navigator.of(context)
                          .pushNamed(SelectCategoryScreen.routeName);
                    },
                  ),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.notes_outlined),
                    title: 'Write note',
                    subtitle: 'Optional',
                  ),
                  const SizedBox(height: 12),
                  _buildReceiptRow(context),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: _formatDate(_selectedDate),
                    subtitle: 'Date',
                    showChevron: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.person_outline),
                    title: 'With',
                    subtitle: 'None',
                    showChevron: true,
                  ),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.event_outlined),
                    title: 'Select event',
                    subtitle: 'No event',
                    showChevron: true,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: false,
                    onChanged: (_) {},
                    title: const Text('Exclude from report'),
                    subtitle: const Text(
                      'Don\'t include this transaction in reports such as Overview.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          if (_showCalculator)
            _CalculatorPad(
              controller: _amountController,
              onSubmit: () {
                setState(() {
                  _showCalculator = false;
                });
              },
            )
          else
            _SaveBar(
              onSave: _handleSave,
            ),
        ],
      ),
    );
  }

  void _handleSave() {
    // TODO: integrate with repository / controller when available.
    Navigator.of(context).pop();
  }

  void _showAddAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add bank account'),
          content: const Text('This is a placeholder for adding a bank account.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final weekday = weekdays[date.weekday - 1];
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$weekday, $day/$month/$year';
  }

  Widget _buildReceiptRow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: _pickReceipt,
          child: Row(
            children: [
              const Icon(Icons.image_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Attach receipt',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _receiptImages.isEmpty
                          ? 'JPG, PNG, WEBP, HEIC'
                          : '${_receiptImages.length} file(s) selected',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (_receiptImages.isNotEmpty)
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    shrinkWrap: true,
                    scrollDirection: Axis.horizontal,
                    itemCount: _receiptImages.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final file = _receiptImages[index];
                      return GestureDetector(
                        onTap: () => _showFullImage(index),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(file.path),
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        if (_receiptError != null) ...[
          const SizedBox(height: 4),
          Text(
            _receiptError!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.redAccent,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickReceipt() async {
    final pickedList = await _picker.pickMultiImage();
    if (pickedList.isEmpty) {
      return;
    }

    const allowedExt = ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'];
    final validFiles = <XFile>[];

    for (final file in pickedList) {
      final lowerPath = file.path.toLowerCase();
      final isValid = allowedExt.any((ext) => lowerPath.endsWith(ext));
      if (isValid) {
        validFiles.add(file);
      }
    }

    if (validFiles.isEmpty) {
      setState(() {
        _receiptError = 'Unsupported file type. Please select JPG, PNG, WEBP or HEIC images.';
      });
      return;
    }

    setState(() {
      _receiptImages
        ..clear()
        ..addAll(validFiles);
      _receiptError = null;
    });

    for (final file in validFiles) {
      await _runReceiptAnalysis(file);
    }
  }

  Future<void> _runReceiptAnalysis(XFile file) async {
    await _receiptRepository.analyzeReceipt(file);
  }

  void _showFullImage(int index) {
    if (_receiptImages.isEmpty || index < 0 || index >= _receiptImages.length) {
      return;
    }
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: InteractiveViewer(
              child: Image.file(
                File(_receiptImages[index].path),
                fit: BoxFit.contain,
              ),
            ),
          ),
        );
      },
    );
  }
}

extension on _CalculatorPad {
  void _onButtonPressed(String label) {
    var text = controller.text.replaceAll(',', '');
    switch (label) {
      case 'C':
        text = '';
        break;
      case '>':
        onSubmit();
        break;
      case '+':
        if (text.startsWith('-')) {
          text = text.replaceFirst('-', '');
        }
        break;
      case '-':
        if (!text.startsWith('-')) {
          text = '-$text';
        }
        break;
      default:
        text = text + label;
    }

    if (label != '>' && label != 'C') {
      controller.text = _formatWithCommas(text);
    } else if (label == 'C') {
      controller.text = '';
    }
  }

  String _formatWithCommas(String value) {
    if (value.isEmpty) return '';
    String sign = '';
    var text = value;
    if (text.startsWith('-')) {
      sign = '-';
      text = text.substring(1);
    }

    String integerPart = text;
    String decimalPart = '';
    if (text.contains('.')) {
      final parts = text.split('.');
      integerPart = parts[0];
      decimalPart = parts.sublist(1).join('.');
    }

    final chars = integerPart.split('').reversed.toList();
    final buffer = StringBuffer();
    for (int i = 0; i < chars.length; i++) {
      if (i != 0 && i % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(chars[i]);
    }
    final formattedInt = buffer.toString().split('').reversed.join();

    if (decimalPart.isNotEmpty) {
      return '$sign$formattedInt.$decimalPart';
    }
    return '$sign$formattedInt';
  }
}

class _RowItem extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final bool showChevron;
  final VoidCallback? onTap;

  const _RowItem({
    required this.leading,
    required this.title,
    this.subtitle,
    this.showChevron = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron) const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AmountField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onTap;

  const _AmountField({required this.controller, this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.left,
      style: const TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      decoration: const InputDecoration(
        prefixText: 'USD ',
        border: UnderlineInputBorder(),
      ),
      onTap: onTap,
    );
  }
}

class _SaveBar extends StatelessWidget {
  final VoidCallback onSave;

  const _SaveBar({required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onSave,
            child: const Text('Save transaction'),
          ),
        ),
      ),
    );
  }
}

class _CalculatorPad extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _CalculatorPad({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final buttons = [
      '7', '8', '9', 'C',
      '4', '5', '6', '+',
      '1', '2', '3', '-',
      '0', '00', '.', '>',
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.3,
            ),
            itemCount: buttons.length,
            itemBuilder: (context, index) {
              final label = buttons[index];
              final isAction = ['C', '+', '-', '>'].contains(label);
              final isPrimary = label == '>';
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPrimary ? AppTheme.primaryGreen : Colors.grey.shade100,
                  foregroundColor: isPrimary ? Colors.white : Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  _onButtonPressed(label);
                },
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: isAction ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

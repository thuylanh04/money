import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../models/transaction.dart';
import '../../../services/receipt_service.dart';
import '../../../theme/app_theme.dart';

class TransactionViewScreen extends StatefulWidget {
  final Transaction transaction;
  final bool isNewTransaction;
  final Function(Transaction)? onUpdate;

  const TransactionViewScreen({
    super.key,
    required this.transaction,
    this.isNewTransaction = false,
    this.onUpdate,
  });

  @override
  State<TransactionViewScreen> createState() => _TransactionViewScreenState();
}

class _TransactionViewScreenState extends State<TransactionViewScreen> {
  final _picker = ImagePicker();
  bool _isProcessing = false;
  String? _imagePath;
  final _receiptRepository = ReceiptRepository();

  Future<void> _processReceipt() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() {
        _isProcessing = true;
        _imagePath = image.path;
      });

      try {
        final receiptData = await _receiptRepository.processReceipt(image);

        final updatedTransaction = Transaction(
          idFE: widget.transaction.idFE,
          amount: receiptData.amount,
          date: widget.transaction.date,
          note: receiptData.note ?? widget.transaction.note,
          image: _imagePath,
          categoryIdFE: receiptData.categoryId ?? widget.transaction.categoryIdFE,
          walletIdFE: widget.transaction.walletIdFE,
        );

        widget.onUpdate?.call(updatedTransaction);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xử lý hóa đơn thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString()}')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = widget.transaction.amount < 0;
    final amountColor = isExpense ? AppTheme.errorRed : AppTheme.primaryGreen;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewTransaction ? 'Giao dịch mới' : 'Chi tiết giao dịch'),
        centerTitle: true,
        actions: [
          if (widget.isNewTransaction)
            IconButton(
              icon: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.receipt_long),
              onPressed: _isProcessing ? null : _processReceipt,
              tooltip: 'Quét hóa đơn',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount
            Center(
              child: Text(
                '${isExpense ? '-' : ''}${_formatCurrency(widget.transaction.amount.abs())} VND',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Transaction Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Danh mục', widget.transaction.categoryIdFE ?? 'Chưa phân loại'),
                    const Divider(),
                    _buildDetailRow('Ví', widget.transaction.walletIdFE ?? 'Chưa chọn'),
                    const Divider(),
                    _buildDetailRow('Ngày', DateFormat('dd/MM/yyyy').format(widget.transaction.date)),
                    if (widget.transaction.note?.isNotEmpty ?? false) ...[
                      const Divider(),
                      _buildDetailRow('Ghi chú', widget.transaction.note!), 
                    ],
                  ],
                ),
              ),
            ),

            // Receipt Image Preview
            _buildReceiptPreview(),

            // Receipt Image (if available)
            if (widget.transaction.image != null && widget.transaction.image!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Receipt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.transaction.image!,
                  fit: BoxFit.cover,
                  height: 200,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(Icons.receipt, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
            
            // Delete Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement delete functionality
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline, color: AppTheme.errorRed),
                label: const Text(
                  'Delete Transaction',
                  style: TextStyle(color: AppTheme.errorRed),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppTheme.errorRed),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add receipt image preview
  Widget _buildReceiptPreview() {
    if (_imagePath == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Hình ảnh hóa đơn',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(_imagePath!),
            fit: BoxFit.cover,
            height: 200,
            width: double.infinity,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 200,
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.receipt, size: 48, color: Colors.grey),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]},',
        );
  }
}

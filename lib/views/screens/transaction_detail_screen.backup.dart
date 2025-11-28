import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:money_manage/config/env_config.dart';

import '../../models/category_fe.dart';
import '../../models/category_group.dart';
import '../../models/transaction.dart';
import '../../models/wallet.dart';
import '../../services/api_client.dart';
import '../../services/group_service.dart';
import '../../services/receipt_service.dart';
import '../../services/transaction_service.dart';
import '../../services/wallet_service.dart';
import '../../services/category_service.dart';
import '../../theme/app_theme.dart';
import 'select_category_screen.dart';

/// Transaction detail / Add transaction screen.
/// Layout based on "Add transaction" screenshot.
class TransactionDetailScreen extends StatefulWidget {
  static const String routeName = '/transaction-detail';
  final Transaction? transaction;

  const TransactionDetailScreen({super.key, this.transaction});

  // Add this static method to handle route generation
  static Route<dynamic> generateRoute(RouteSettings settings) {
    if (settings.arguments != null) {
      final transaction = settings.arguments as Transaction;
      return MaterialPageRoute(
        builder: (context) => TransactionDetailScreen(transaction: transaction),
      );
    }
    return MaterialPageRoute(
      builder: (context) => const TransactionDetailScreen(),
    );
  }

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _showCalculator = false;
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _receiptImages = <XFile>[];
  File? _selectedImage;
  String? _receiptError;
  final ReceiptRepository _receiptRepository = ReceiptRepository();
  final GroupService _groupService = GroupService(ApiClient());
  final WalletService _walletService = WalletService(ApiClient());
  
  // Wallet related state
  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;
  bool _isLoadingWallets = false;
  String? _walletError;
  
  // Categories and AI state
  List<CategoryFE> _categories = [];
  bool _isAiRunning = false;
  bool _aiCompleted = false;

  String _expenseLabel = 'Expense';
  String _incomeLabel = 'Income';
  String _debtLabel = 'Debt/Loan';
  String? _expenseGroupIdFE;
  String? _incomeGroupIdFE;
  String? _debtGroupIdFE;
  CategoryFE? _selectedCategory;

  // Helper method to determine if a transaction is income
  bool _isIncome(Transaction transaction) {
    return transaction.amount >= 0;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChanged);
    _loadGroups();
    _fetchWallets();
    
    // Initialize transaction data
    if (widget.transaction != null) {
      _amountController.text = widget.transaction!.amount.abs().toString();
      _noteController.text = widget.transaction?.note ?? '';
      _selectedDate = widget.transaction?.date ?? DateTime.now();
      
      // Load image if exists
      if (widget.transaction?.image != null && widget.transaction!.image!.isNotEmpty) {
        _selectedImage = File(widget.transaction!.image!);
      }
    }
    _tabController.addListener(_handleTabChanged);
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    try {
      final categoryService = CategoryService(ApiClient());
      final categories = await categoryService.fetchCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể tải danh mục')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }
  
  
  Future<void> _runAiClassification() async {
    if (_selectedImage == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng đính kèm ít nhất một ảnh hóa đơn.')),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isAiRunning = true;
      });
    }

    try {
      await _runReceiptAnalysis(_selectedImage!);

      if (mounted) {
        setState(() {
          _aiCompleted = true;
        });
      }
    } catch (e) {
      debugPrint('AI classification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể phân tích hóa đơn. Vui lòng thử lại.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isAiRunning = false;
        });
      }
    }
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
        title: Text(widget.transaction != null ? 'Edit Transaction' : 'Add Transaction'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryGreen,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: [
            Tab(text: _expenseLabel),
            Tab(text: _incomeLabel),
            Tab(text: _debtLabel),
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
                  _buildWalletSelection(),
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
                    title: _selectedCategory?.categoryName ?? 'Select category',
                    subtitle: _selectedCategory == null ? 'Tap to choose' : null,
                    showChevron: true,
                    onTap: () async {
                      final result = await Navigator.of(context).pushNamed(
                        SelectCategoryScreen.routeName,
                      );
                      if (result is CategoryFE) {
                        setState(() {
                          _selectedCategory = result;
                          _updateTabForCategory(result);
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final result = await showDialog<String>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Add Note'),
                          content: TextField(
                            controller: _noteController,
                            autofocus: true,
                            decoration: const InputDecoration(
                              hintText: 'Enter your note here',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, _noteController.text),
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          _noteController.text = result;
                        });
                      }
                    },
                    child: _RowItem(
                      leading: const Icon(Icons.notes_outlined),
                      title: _noteController.text.isNotEmpty ? _noteController.text : 'Write note',
                      subtitle: _noteController.text.isEmpty ? 'Optional' : null,
                      showChevron: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildImagePicker(),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.calendar_today_outlined),
                    title: _formatDate(_selectedDate),
                    subtitle: 'Transaction Date',
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
                    subtitle: 'Select contact',
                    showChevron: true,
                  ),
                  const SizedBox(height: 12),
                  _RowItem(
                    leading: const Icon(Icons.event_outlined),
                    title: 'Select event',
                    subtitle: 'No event selected',
                    showChevron: true,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    value: false,
                    onChanged: (_) {},
                    title: const Text('Exclude from report'),
                    subtitle: const Text(
                      'This transaction will not be included in reports and statistics.',
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
              onAiClassify: _runAiClassification,
              canSave: _canSave,
              canAiClassify: _canAiClassify,
              isAiRunning: _isAiRunning,
            ),
        ],
      ),
    );
  }

  bool get _canSave {
    final hasAmount = _amountController.text.trim().isNotEmpty;
    final hasCategory = _selectedCategory != null;
    // Date is always set; allow save if user filled fields or AI has classified.
    return _aiCompleted || (hasAmount && hasCategory);
  }

  bool get _canAiClassify {
    return _selectedImage != null && !_isAiRunning;
  }

  Future<void> _loadGroups() async {
    try {
      final groups = await _groupService.fetchGroups();
      if (!mounted || groups.isEmpty) return;

      setState(() {
        if (groups.length > 0) {
          _expenseLabel = groups[0].groupName;
          _expenseGroupIdFE = groups[0].idFE;
        }
        if (groups.length > 1) {
          _incomeLabel = groups[1].groupName;
          _incomeGroupIdFE = groups[1].idFE;
        }
        if (groups.length > 2) {
          _debtLabel = groups[2].groupName;
          _debtGroupIdFE = groups[2].idFE;
        }
      });
    } catch (_) {
      // Keep default labels on error.
    }
  }

  Future<void> _fetchWallets() async {
    if (_isLoadingWallets) return;
    
    setState(() {
      _isLoadingWallets = true;
      _walletError = null;
    });

    try {
      final wallets = await _walletService.getWallets();
      if (mounted) {
        setState(() {
          _wallets = wallets;
          if (_wallets.isNotEmpty) {
            _selectedWallet = _wallets.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _walletError = 'Không thể tải danh sách ví. Vui lòng thử lại.';
        });
      }
      print('Error loading wallets: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWallets = false;
        });
      }
    }
  }

  Widget _buildWalletSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ví',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingWallets)
          const Center(child: CircularProgressIndicator()),
        if (_walletError != null)
          Text(
            _walletError!,
            style: const TextStyle(color: Colors.red),
          ),
        if (!_isLoadingWallets && _wallets.isEmpty)
          const Text('Không có ví nào'),
        if (_wallets.isNotEmpty)
          DropdownButtonFormField<Wallet>(
            value: _selectedWallet,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: _wallets.map((wallet) {
              return DropdownMenuItem<Wallet>(
                value: wallet,
                child: Text(wallet.walletName),
              );
            }).toList(),
            onChanged: (Wallet? newValue) {
              if (newValue != null) {
                setState(() {
                  _selectedWallet = newValue;
                });
              }
            },
          ),
      ],
    );
  }

  void _handleTabChanged() {
    if (!_tabController.indexIsChanging && _selectedCategory != null) {
      // If user switches tab manually to a type that does not match
      // the currently selected category's group, clear the selection
      // to avoid inconsistent state.
      final gid = _selectedCategory!.groupIdFE;
      int? expectedIndex;
      if (_expenseGroupIdFE != null && gid == _expenseGroupIdFE) {
        expectedIndex = 0;
      } else if (_incomeGroupIdFE != null && gid == _incomeGroupIdFE) {
        expectedIndex = 1;
      } else if (_debtGroupIdFE != null && gid == _debtGroupIdFE) {
        expectedIndex = 2;
      }

      if (expectedIndex != null && expectedIndex != _tabController.index) {
        setState(() {
          _selectedCategory = null;
        });
      }
    }
  }

  void _updateTabForCategory(CategoryFE category) {
    final gid = category.groupIdFE;
    if (gid.isEmpty) return;

    if (_expenseGroupIdFE != null && gid == _expenseGroupIdFE) {
      _tabController.index = 0;
    } else if (_incomeGroupIdFE != null && gid == _incomeGroupIdFE) {
      _tabController.index = 1;
    } else if (_debtGroupIdFE != null && gid == _debtGroupIdFE) {
      _tabController.index = 2;
    }
  }

  Future<void> _handleSave() async {
    try {
      await _saveTransaction();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${e.toString()}')),
        );
      }
    }
  }

  Future<Transaction> _saveTransaction() async {
    // Validate required fields
    if (_amountController.text.isEmpty) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng nhập số tiền')),
          );
        }
      }
      throw Exception('Amount is required');
    }

    if (_selectedCategory == null) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn danh mục')),
          );
        }
      }
      throw Exception('Category is required');
    }

    if (_selectedWallet == null) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng chọn ví')),
          );
        }
      }
      throw Exception('Wallet is required');
    }

    String? imageUrl;
    if (_selectedImage != null) {
      try {
        // Show loading indicator
        final navigator = Navigator.of(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );

        // Upload image
        imageUrl = await _uploadImage(_selectedImage!);
        
        // Close loading indicator
        if (context.mounted) {
          navigator.pop();
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lỗi khi tải lên ảnh')),
          );
        }
        rethrow;
      }
    }

    final amount = double.tryParse(_amountController.text.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    final isIncome = _tabController.index == 1; // Index 1 is Income tab
    final finalAmount = isIncome ? amount.abs() : -amount.abs();

    Transaction? result;
    
    if (widget.transaction != null) {
      // Update existing transaction
      final response = await TransactionService.updateTransaction(
        transactionId: widget.transaction!.idFE,
        amount: finalAmount,
        categoryIdFE: _selectedCategory!.idFE,
        note: _noteController.text,
        date: _selectedDate,
        walletIdFE: _selectedWallet!.idFE,
        imageUrl: imageUrl,
      );
      result = response;
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật giao dịch thành công')),
        );
      }
    } else {
      // Create new transaction
      final response = await TransactionService.createTransaction(
        amount: finalAmount,
        date: _selectedDate.toIso8601String(),
        categoryIdFE: _selectedCategory!.idFE,
        walletIdFE: _selectedWallet!.idFE,
        note: _noteController.text.isNotEmpty ? _noteController.text : null,
        image: imageUrl,
      );
      result = Transaction.fromJson(response);
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm giao dịch thành công')),
        );
      }
    }

    if (mounted && context.mounted) {
      Navigator.of(context).pop(result); // Return the created/updated transaction
    }
    return result!;
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

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hình ảnh giao dịch',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Chọn ảnh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _captureImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Chụp ảnh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        if (_receiptError != null) ...[
          const SizedBox(height: 8),
          Text(
            _receiptError!,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.redAccent,
            ),
          ),
        ],
        if (_selectedImage != null) ...[
          const SizedBox(height: 8),
          _buildImagePreview(),
        ],
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();
    
    final isNetworkImage = _selectedImage!.path.startsWith('http');
    
    return Container(
      width: 200,
      height: 200,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: isNetworkImage
            ? Image.network(
                _selectedImage!.path,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
              )
            : Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        if (mounted) {
          setState(() {
            _selectedImage = File(image.path);
            _receiptError = null;
          });
          if (widget.transaction?.image == null) {
            await _runReceiptAnalysis(image);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _receiptError = 'Không thể chọn ảnh. Vui lòng thử lại.';
        });
      }
    }
  }

  Future<void> _captureImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        if (mounted) {
          setState(() {
            _selectedImage = File(image.path);
            _receiptError = null;
          });
          await _runReceiptAnalysis(image);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _receiptError = 'Không thể chụp ảnh. Vui lòng thử lại.';
        });
      }
    }
  }

  Future<void> _runReceiptAnalysis(XFile file) async {
    if (!mounted) return;
    
    // Show loading indicator
    final navigator = Navigator.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Call the new API endpoint for AI classification
      final url = Uri.parse('${EnvConfig.apiBaseUrl}/api/v1/transactions/test-upload-multiple');
      final request = http.MultipartRequest('POST', url);
      
      // Add the image file
      final fileStream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        'files',
        fileStream,
        length,
        filename: file.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Send the request
      debugPrint('Sending request to: ${url.toString()}');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['code'] == 1000) {
          final result = responseData['result'];
          final totalAmount = result['total_amount'] as String?;
          final invoiceType = result['invoice_type'] as String?;
          
          if (mounted) {
            setState(() {
              // Update amount if available
              if (totalAmount != null && totalAmount.isNotEmpty) {
                try {
                  // First, remove all non-numeric characters and spaces
                  String cleanAmount = totalAmount.replaceAll(RegExp(r'[^0-9,.]'), '');
                  
                  // Check if the last comma or dot is a decimal separator
                  int lastComma = cleanAmount.lastIndexOf(',');
                  int lastDot = cleanAmount.lastIndexOf('.');
                  
                  if (lastComma > lastDot) {
                    // Comma is the decimal separator, dot is thousand separator
                    cleanAmount = cleanAmount
                        .replaceAll('.', '')   // Remove thousand separators
                        .replaceFirst(',', '.'); // Convert decimal comma to dot
                  } else if (lastDot > lastComma) {
                    // Dot is the decimal separator, comma is thousand separator
                    cleanAmount = cleanAmount.replaceAll(',', ''); // Remove thousand separators
                  } else if (lastComma == -1 && lastDot == -1) {
                    // No decimal point, just a whole number
                    cleanAmount = cleanAmount;
                  }
                  
                  // Parse to double and format without decimal places if it's a whole number
                  double amount = double.parse(cleanAmount);
                  if (amount == amount.truncate()) {
                    _amountController.text = amount.truncate().toString();
                  } else {
                    _amountController.text = amount.toString();
                  }
                  
                  debugPrint('Parsed amount: ${_amountController.text} from original: $totalAmount');
                } catch (e) {
                  debugPrint('Error parsing amount "$totalAmount": $e');
                  // Fallback: remove all non-numeric characters
                  String clean = totalAmount.replaceAll(RegExp(r'[^0-9]'), '');
                  if (clean.isNotEmpty) {
                    _amountController.text = clean;
                  } else {
                    _amountController.text = '0';
                  }
                }
              }

              // Find and set the matching category
              if (invoiceType != null && _categories.isNotEmpty) {
                try {
                  final matchedCategory = _categories.firstWhere(
                    (cat) => cat.categoryName?.toLowerCase() == invoiceType.toLowerCase(),
                    orElse: () => _categories.first,
                  );
                  _selectedCategory = matchedCategory;
                  _updateTabForCategory(_selectedCategory!);
                } catch (e) {
                  debugPrint('Error setting category: $e');
                }
              }
              // Clear any previous errors
              _receiptError = null;
            });
          }
          return;
        }
      }

      // If we get here, there was an error
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading indicator
      
      String errorMessage = 'Không thể xử lý hóa đơn. Vui lòng thử lại.';
      try {
        final errorData = json.decode(response.body);
        if (errorData['message'] != null) {
          errorMessage = errorData['message'];
        }
      } catch (e) {
        debugPrint('Error parsing error response: $e');
      }
      
      debugPrint('API Error (${response.statusCode}): $errorMessage');
      
      if (mounted) {
        setState(() {
          _receiptError = errorMessage;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss loading indicator
      if (mounted) {
        setState(() {
          _receiptError = 'Có lỗi xảy ra khi xử lý ảnh';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Có lỗi xảy ra khi xử lý ảnh')),
        );
      }
      debugPrint('Error processing receipt: $e');
    }
  }
  
  Future<String?> _uploadImage(File imageFile) async {
    try {
      // If the image is already a URL, return it directly
      if (imageFile.path.startsWith('http')) {
        return imageFile.path;
      }
      
      final url = Uri.parse('${EnvConfig.apiBaseUrl}/api/v1/upload');
      final request = http.MultipartRequest('POST', url);
      
      // Add the image file
      final fileStream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        length,
        filename: 'transaction_${DateTime.now().millisecondsSinceEpoch}${path.extension(imageFile.path)}',
      );
      request.files.add(multipartFile);

      // Add authorization header if needed
      if (EnvConfig.apiAuthHeader.isNotEmpty) {
        request.headers['Authorization'] = EnvConfig.apiAuthHeader;
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Return full URL if the response contains it, otherwise construct it
        if (responseData['url'] != null) {
          return responseData['url'] as String;
        } else if (responseData['filename'] != null) {
          return '${EnvConfig.apiBaseUrl}/uploads/${responseData['filename']}';
        }
      }
      
      debugPrint('Upload failed with status ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
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
        case 'x':
          if (text.isNotEmpty) {
            text = text.substring(0, text.length - 1);
          }
          break;
        default:
          if (label == '.') {
            // Không cho nhập nhiều hơn 1 dấu chấm
            if (text.contains('.')) {
              return;
            }
            // Nếu đang rỗng thì bắt đầu bằng 0.
            if (text.isEmpty) {
              text = '0.';
            } else {
              text = text + label;
            }
          } else {
            text = text + label;
          }
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
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'USD',
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

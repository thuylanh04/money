import 'dart:io';
import 'dart:convert';


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
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
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
  String? _receiptError;
  // Remote receipt URLs returned from the server
  List<String> _remoteReceiptUrls = [];
  final ReceiptRepository _receiptRepository = ReceiptRepository();
  final GroupService _groupService = GroupService(ApiClient());
  final WalletService _walletService = WalletService(ApiClient());


  // Wallet related state
  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;
  bool _isLoadingWallets = false;
  String? _walletError;
  // If passed transaction has a wallet id before wallets are loaded,
  // store it here and apply when wallets arrive to pick the same instance.
  String? _initialWalletId;
  String? _initialWalletName;


  // Categories and AI state
  List<CategoryFE> _categories = [];
  bool _isAiRunning = false;
  bool _aiCompleted = false;
  bool _isSaving = false;


  String _expenseLabel = 'Expense';
  String _incomeLabel = 'Income';
  String _debtLabel = 'Debt/Loan';
  String? _expenseGroupIdFE;
  String? _incomeGroupIdFE;
  String? _debtGroupIdFE;
  CategoryFE? _selectedCategory;
  Transaction? _transaction;


  // Field validation errors
  String? _amountError;
  String? _categoryError;
  String? _walletValidationError;


  // Helper method to determine if a transaction is income
  // Now we'll check the group type instead of amount sign
  bool _isIncome(Transaction transaction) {
    return transaction.groupType?.toLowerCase() == 'income';
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _fetchWallets();
    _loadCategories();


    // Pre-fill form if editing existing transaction
    if (widget.transaction != null) {
      // quick prefill from the passed object while we fetch the full detail
      _transaction = widget.transaction;
      final transaction = widget.transaction!;
      _amountController.text = transaction.amount.toString();
      _noteController.text = transaction.note ?? '';
      _selectedDate = transaction.date;


      // Set the transaction type tab (income/expense)
      final tabIndex = _isIncome(transaction) ? 0 : 1;
      _tabController.animateTo(tabIndex);


      // Try to set category and wallet from the shallow object; they will be
      // overwritten when full detail loads.
      if (transaction.categoryIdFE != null) {
        try {
          final category = _categories.firstWhere(
            (c) => c.idFE == transaction.categoryIdFE,
          );
          _selectedCategory = category;
        } catch (e) {
          _selectedCategory = CategoryFE(
            idFE: transaction.categoryIdFE!,
            categoryName: transaction.categoryName ?? 'Unknown',
            groupIdFE: '',
          );
        }
      }


      if (transaction.walletIdFE != null) {
        _initialWalletId = transaction.walletIdFE;
        _initialWalletName = transaction.walletName;
      }


      // If server provided image URLs, store them to display as remote receipts
      if (transaction.image != null && transaction.image!.isNotEmpty) {
        _remoteReceiptUrls = List<String>.from(transaction.image!);
      }
    }
    _tabController.addListener(_handleTabChanged);
    _loadGroups();
    _fetchWallets();
    _loadCategories();


    // If we have an initial transaction, fetch full details from server
    if (widget.transaction != null) {
      _loadTransactionDetail();
    }
  }


  Future<void> _loadTransactionDetail() async {
    if (widget.transaction == null) return;
    try {
      final service = TransactionService();
      final detail = await service.transactionDetail(widget.transaction!.idFE);
      if (!mounted) return;


      setState(() {
        _transaction = detail;
        _amountController.text = detail.amount.toString();
        _noteController.text = detail.note ?? '';
        _selectedDate = detail.date;


        // Set selected category if available
        if (detail.categoryIdFE != null) {
          try {
            final category = _categories.firstWhere(
              (c) => c.idFE == detail.categoryIdFE,
            );
            _selectedCategory = category;
          } catch (e) {
            _selectedCategory = CategoryFE(
              idFE: detail.categoryIdFE!,
              categoryName: detail.categoryName ?? 'Unknown',
              groupIdFE: detail.groupIdFE ?? '',
            );
          }
        }


        if (detail.walletIdFE != null) {
          // Prefer to pick the instance from _wallets when available to
          // avoid DropdownButton identity mismatch. If wallets not loaded yet,
          // remember the id and name and select later in _fetchWallets.
          if (_wallets.isNotEmpty) {
            try {
              _selectedWallet =
                  _wallets.firstWhere((w) => w.idFE == detail.walletIdFE);
            } catch (_) {
              _selectedWallet = null;
            }
          } else {
            _initialWalletId = detail.walletIdFE;
            _initialWalletName = detail.walletName;
          }
        }


        // Remote images
        _remoteReceiptUrls = detail.image ?? [];
      });
    } catch (e) {
      debugPrint('Error loading transaction detail: $e');
    }
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
          const SnackBar(content: Text('Failed to load categories')),
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
    if (_receiptImages.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please attach at least one receipt image.')),
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
      await _runReceiptAnalysis(_receiptImages.first);


      if (mounted) {
        setState(() {
          _aiCompleted = true;
        });
      }
    } catch (e) {
      debugPrint('AI classification error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to process receipt. Please try again.')),
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


  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.transaction == null
          ? 'Add Transaction'
          : 'Transaction Details'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Use maybePop to avoid Navigator locked assertion when a navigation
          // operation is already in progress.
          Navigator.of(context).maybePop();
        },
      ),
      actions: widget.transaction != null
          ? [
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _showDeleteConfirmation,
              ),
            ]
          : null,
      // TabBar moved into the body so it renders reliably on a white background.
    );
  }


  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );


    if (confirmed == true) {
      await _deleteTransaction();
    }
  }


  Future<void> _deleteTransaction() async {
    if (widget.transaction == null) return;


    try {
      final transactionService = TransactionService();
      final success =
          await transactionService.deleteTransaction(widget.transaction!.idFE);


      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted successfully')),
        );
        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate deletion
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete transaction: $e')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isTablet = media.size.width > 600;
    final horizontalPadding = isTablet ? media.size.width * 0.08 : 16.0;


    final mainContent = Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding, vertical: 16),
            child: Column(
              children: [
                // Tab selector (Expense / Income / Debt-Loan)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.primaryGreen,
                    labelColor: AppTheme.primaryGreen,
                    unselectedLabelColor: Colors.grey[600],
                    tabs: [
                      Tab(text: _expenseLabel),
                      Tab(text: _incomeLabel),
                      Tab(text: _debtLabel),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
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
                if (_amountError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _amountError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
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
                if (_categoryError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _categoryError!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
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
                            onPressed: () =>
                                Navigator.pop(context, _noteController.text),
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
                    title: _noteController.text.isNotEmpty
                        ? _noteController.text
                        : 'Write note',
                    subtitle: _noteController.text.isEmpty ? 'Optional' : null,
                    showChevron: true,
                  ),
                ),
                const SizedBox(height: 12),
                _buildReceiptRow(context),
                const SizedBox(height: 12),
                _RowItem(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: _formatDate(_selectedDate),
                  subtitle: 'Transaction Date',
                  showChevron: true,
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate.isAfter(DateTime.now()) ? DateTime.now() : _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
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
    );


    return Scaffold(
        appBar: _buildAppBar(),
        body: Transform.translate(
          offset: const Offset(0, -40),
          child: Stack(
            children: [
              mainContent,
              if (_isSaving)
                Positioned.fill(
                  child: AbsorbPointer(
                    absorbing: true,
                    child: Container(
                      color: Colors.black.withOpacity(0.45),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ));
  }


  bool get _canSave {
    final hasAmount = _amountController.text.trim().isNotEmpty;
    final hasCategory = _selectedCategory != null;
    // Date is always set; allow save if user filled fields or AI has classified.
    return _aiCompleted || (hasAmount && hasCategory);
  }


  bool get _canAiClassify {
    return _receiptImages.isNotEmpty && !_isAiRunning;
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
          // If the caller passed a wallet id earlier, prefer selecting the
          // matching instance from the freshly loaded list. This ensures the
          // DropdownButtonFormField's `value` matches one of the `items`.
          if (_initialWalletId != null) {
            try {
              _selectedWallet = _wallets.firstWhere(
                (w) => w.idFE == _initialWalletId,
              );
            } catch (_) {
              // If no matching wallet found, fall back to first available.
              if (_wallets.isNotEmpty) _selectedWallet = _wallets.first;
            }
            _initialWalletId = null;
            _initialWalletName = null;
          } else {
            if (_wallets.isNotEmpty) {
              _selectedWallet = _wallets.first;
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _walletError = 'Failed to load wallet list. Please try again.';
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
          'Wallet',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_isLoadingWallets) const Center(child: CircularProgressIndicator()),
        if (_walletError != null)
          Text(
            _walletError!,
            style: const TextStyle(color: Colors.red),
          ),
        if (!_isLoadingWallets && _wallets.isEmpty)
          const Text('No wallets available'),
        if (_wallets.isNotEmpty)
          DropdownButtonFormField<Wallet>(
            value: _selectedWallet,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  _walletValidationError = null;
                });
              }
            },
          ),
        if (_walletValidationError != null) ...[
          const SizedBox(height: 4),
          Text(
            _walletValidationError!,
            style: const TextStyle(color: Colors.red, fontSize: 12),
          ),
        ],
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
    // Clear previous validation errors
    setState(() {
      _amountError = null;
      _categoryError = null;
      _walletValidationError = null;
    });


    // Validate required fields (show inline errors)
    if (_amountController.text.isEmpty) {
      if (mounted) {
        setState(() {
          _amountError = 'Please enter amount';
        });
      }
      return;
    }


    if (_selectedCategory == null) {
      if (mounted) {
        setState(() {
          _categoryError = 'Please select a category';
        });
      }
      return;
    }


    if (_selectedWallet == null) {
      if (mounted) {
        setState(() {
          _walletValidationError = 'Please select a wallet';
        });
      }
      return;
    }


    // Parse and ensure amount is positive
    final amount = double.tryParse(
            _amountController.text.replaceAll(RegExp(r'[^\d.]'), '')) ??
        0.0;
    final finalAmount = amount.abs(); // Ensure amount is always positive


    // All validation passed — show saving overlay while performing network operations.
    setState(() {
      _isSaving = true;
    });


    try {
      if (widget.transaction != null) {
        // Update existing transaction
        final transactionService = TransactionService();
        // Convert picked XFile receipts to dart:io File instances
        final files = _receiptImages.map((x) => File(x.path)).toList();
        final updated = await transactionService.updateTransaction(
          transactionId: _transaction?.idFE ?? widget.transaction!.idFE,
          amount: finalAmount,
          categoryIdFE: _selectedCategory!.idFE,
          note: _noteController.text,
          date: _selectedDate,
          walletIdFE: _selectedWallet!.idFE,
          files: files.isNotEmpty ? files : null,
        );
        // response contains the updated Transaction; attach it to local state
        if (mounted) {
          setState(() {
            _transaction = updated;
            _remoteReceiptUrls = updated.image ?? [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction updated successfully')),
          );
        }
      } else {
        // Create new transaction
        final transactionService = TransactionService();
        await transactionService.createTransaction(
          amount: finalAmount,
          date: _selectedDate.toIso8601String(),
          categoryIdFE: _selectedCategory!.idFE,
          walletIdFE: _selectedWallet!.idFE,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
        );
        // response contains the created Transaction if needed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction added successfully')),
          );
        }
      }


      if (mounted) {
        // Hide saving overlay before navigating away
        setState(() {
          _isSaving = false;
        });
        // Return a simple success flag to callers (avoid mixing return types)
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Error saving transaction: $e');
      if (!mounted) return;
      final message = e.toString();
      // Hide overlay on error
      setState(() {
        _isSaving = false;
      });
      // Show an alert dialog for verification/server errors
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      // Ensure overlay is hidden if still mounted
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }


  void _showAddAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add bank account'),
          content:
              const Text('This is a placeholder for adding a bank account.'),
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
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
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
          onTap: () => _showReceiptSourceSheet(context),
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
                      (_remoteReceiptUrls.isEmpty && _receiptImages.isEmpty)
                          ? 'JPG, PNG, WEBP, HEIC'
                          : '${_remoteReceiptUrls.length + _receiptImages.length} file(s) selected',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_remoteReceiptUrls.isNotEmpty || _receiptImages.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.separated(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              itemCount: _remoteReceiptUrls.length + _receiptImages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index < _remoteReceiptUrls.length) {
                  final url = _remoteReceiptUrls[index];
                  return GestureDetector(
                    onTap: () => _showFullImage(index),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            url,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _remoteReceiptUrls.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }


                final localIndex = index - _remoteReceiptUrls.length;
                final file = _receiptImages[localIndex];
                return GestureDetector(
                  onTap: () => _showFullImage(index),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(file.path),
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _receiptImages.removeAt(localIndex);
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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


  Future<void> _pickReceiptFromGallery() async {
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
        _receiptError =
            'Unsupported file type. Please select JPG, PNG, WEBP or HEIC images.';
      });
      return;
    }


    setState(() {
      _receiptImages.addAll(validFiles);
      _receiptError = null;
    });
  }


  Future<void> _captureReceiptPhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) {
      return;
    }


    const allowedExt = ['.jpg', '.jpeg', '.png', '.webp', '.heic', '.heif'];
    final lowerPath = photo.path.toLowerCase();
    final isValid = allowedExt.any((ext) => lowerPath.endsWith(ext));
    if (!isValid) {
      setState(() {
        _receiptError =
            'Unsupported file type. Please capture JPG, PNG, WEBP or HEIC image.';
      });
      return;
    }


    setState(() {
      _receiptImages.add(photo);
      _receiptError = null;
    });
  }


  void _showReceiptSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _captureReceiptPhoto();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickReceiptFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }


  Future<void> _runReceiptAnalysis(XFile file) async {
    if (!mounted) return;


    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );


    try {
      // Call the new API endpoint for AI classification
      final url = Uri.parse(
          '${EnvConfig.apiBaseUrl}/api/v1/transactions/test-upload-multiple');
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


          if (!mounted) return;
          Navigator.of(context).pop(); // Dismiss loading indicator


          if (mounted) {
            setState(() {
              // Update amount if available
              if (totalAmount != null && totalAmount.isNotEmpty) {
                try {
                  // First, remove all non-numeric characters and spaces
                  String cleanAmount =
                      totalAmount.replaceAll(RegExp(r'[^0-9,.]'), '');


                  // Check if the last comma or dot is a decimal separator
                  int lastComma = cleanAmount.lastIndexOf(',');
                  int lastDot = cleanAmount.lastIndexOf('.');


                  if (lastComma > lastDot) {
                    // Comma is the decimal separator, dot is thousand separator
                    cleanAmount = cleanAmount
                        .replaceAll('.', '') // Remove thousand separators
                        .replaceFirst(',', '.'); // Convert decimal comma to dot
                  } else if (lastDot > lastComma) {
                    // Dot is the decimal separator, comma is thousand separator
                    cleanAmount = cleanAmount.replaceAll(
                        ',', ''); // Remove thousand separators
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


                  debugPrint(
                      'Parsed amount: ${_amountController.text} from original: $totalAmount');
                } catch (e) {
                  debugPrint('Error parsing amount "$totalAmount": $e');
                  // Fallback: remove all non-numeric characters except the last dot
                  String clean = totalAmount.replaceAll(RegExp(r'[^0-9]'), '');
                  if (clean.isNotEmpty) {
                    _amountController.text = clean;
                  } else {
                    _amountController.text = '0';
                  }
                }
              }


              // Find and set the matching category
              if (invoiceType != null) {
                // Find category that matches invoice_type
                try {
                  final matchedCategory = _categories.firstWhere(
                    (cat) =>
                        cat.categoryName.toLowerCase() ==
                        invoiceType.toLowerCase(),
                  );
                  _selectedCategory = matchedCategory;
                  _updateTabForCategory(_selectedCategory!);


                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Automatically selected category: ${matchedCategory.categoryName}')),
                  );
                } catch (e) {
                  // If no exact match, try to find 'Others' category
                  try {
                    _selectedCategory = _categories.firstWhere(
                      (cat) => cat.categoryName == 'Others',
                    );
                    _updateTabForCategory(_selectedCategory!);


                    // Show invoice type in snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Loại hóa đơn: $invoiceType')),
                    );
                  } catch (e) {
                    // If no 'Others' category, just select the first one
                    if (_categories.isNotEmpty) {
                      _selectedCategory = _categories.first;
                      _updateTabForCategory(_selectedCategory!);
                    }
                  }
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


      String errorMessage = 'Unable to process receipt. Please try again.';
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
          _receiptError = 'An error occurred while processing the image';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred while processing the image')),
        );
      }
      debugPrint('Error processing receipt: $e');
    }
  }


  void _showFullImage(int index) {
    if (index < 0) return;
    if (!mounted) return;


    Widget imageWidget;
    if (index < _remoteReceiptUrls.length) {
      final url = _remoteReceiptUrls[index];
      imageWidget =
          Image.network(url, fit: BoxFit.contain, errorBuilder: (_, __, ___) {
        return const Icon(Icons.broken_image, size: 64);
      });
    } else {
      final localIndex = index - _remoteReceiptUrls.length;
      if (localIndex < 0 || localIndex >= _receiptImages.length) return;
      imageWidget = Image.file(File(_receiptImages[localIndex].path),
          fit: BoxFit.contain);
    }


    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (BuildContext context) {
        return GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Dialog.fullscreen(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(child: imageWidget),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  readOnly: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    hintText: '0',
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                  onTap: onTap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Divider(thickness: 1.5),
        ],
      ),
    );
  }
}


class _SaveBar extends StatelessWidget {
  final VoidCallback onSave;
  final VoidCallback onAiClassify;
  final bool canSave;
  final bool canAiClassify;
  final bool isAiRunning;


  const _SaveBar({
    required this.onSave,
    required this.onAiClassify,
    required this.canSave,
    required this.canAiClassify,
    required this.isAiRunning,
  });


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed:
                    (!canAiClassify || isAiRunning) ? null : onAiClassify,
                child: isAiRunning
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('AI classify'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: canSave ? onSave : null,
                child: const Text('Save transaction'),
              ),
            ),
          ],
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
    // Layout yêu cầu:
    // 1   2   3   C
    // 4   5   6   x
    // 7   8   9   .
    // 00  0  000  >
    final buttons = [
      '1',
      '2',
      '3',
      'C',
      '4',
      '5',
      '6',
      'x',
      '7',
      '8',
      '9',
      '.',
      '00',
      '0',
      '000',
      '>',
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
              final isAction = ['C', 'x', '>'].contains(label);
              final isPrimary = label == '>';
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isPrimary ? AppTheme.primaryGreen : Colors.white,
                  foregroundColor: isPrimary
                      ? Colors.white
                      : (isAction ? AppTheme.primaryGreen : Colors.black87),
                  elevation: isPrimary ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isPrimary
                          ? Colors.transparent
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
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




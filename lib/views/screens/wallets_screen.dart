import 'package:flutter/material.dart';
import 'package:money_manage/models/wallet.dart';
import 'package:money_manage/services/api_client.dart';
import 'package:money_manage/services/wallet_service.dart';
import 'package:money_manage/theme/app_theme.dart';

class WalletsScreen extends StatefulWidget {
  static const String routeName = '/wallets';

  const WalletsScreen({super.key});

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  final WalletService _walletService = WalletService(ApiClient());
  List<Wallet> _wallets = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    try {
      final wallets = await _walletService.getUserWallets();
      setState(() {
        _wallets = wallets;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Failed to load wallet list. Please try again.';
      });
    }
  }

  Future<void> _addNewWallet() async {
    final nameController = TextEditingController();
    bool isLoading = false;
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Wallet'),
              content: TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Wallet Name',
                  hintText: 'e.g., Cash, Credit Card, Bank Account',
                ),
                enabled: !isLoading,
              ),
              actions: <Widget>[
                if (isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  )
                else
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: isLoading
                      ? null
                      : () async {
                          final name = nameController.text.trim();
                          if (name.isNotEmpty) {
                            try {
                              setState(() => isLoading = true);
                              
                              final newWallet = await _walletService.createWallet(name);
                              
                              if (newWallet != null && mounted) {
                                setState(() {
                                  _wallets.add(newWallet);
                                });
                                if (mounted) {
                                  Navigator.of(context).pop();
                                }
                              } else {
                                throw Exception('Failed to create wallet');
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                setState(() => isLoading = false);
                              }
                            }
                          }
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallets'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addNewWallet,
            tooltip: 'Add new wallet',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                )
              : _wallets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'You don\'t have any wallets yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _addNewWallet,
                            child: const Text('Add New Wallet'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _wallets.length,
                      itemBuilder: (context, index) {
                        final wallet = _wallets[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryGreenLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            title: Text(
                              wallet.walletName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            // subtitle: const Text(
                            //   'Balance: 0 ₫',
                            //   style: TextStyle(
                            //     color: Colors.grey,
                            //   ),
                            // ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              // View wallet details if needed
                            },
                          ),
                        );
                      },
                    ),
    );
  }
}

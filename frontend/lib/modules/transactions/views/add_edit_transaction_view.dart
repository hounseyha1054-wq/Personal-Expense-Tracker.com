import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/card_container.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/transaction_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../analytics/controllers/analytics_controller.dart';
import '../controllers/transaction_controller.dart';

class AddEditTransactionView extends StatefulWidget {
  const AddEditTransactionView({super.key});

  @override
  State<AddEditTransactionView> createState() => _AddEditTransactionViewState();
}

class _AddEditTransactionViewState extends State<AddEditTransactionView> {
  final _formKey = GlobalKey<FormState>();
  late final TransactionController _controller;

  TransactionModel? _editingTransaction;
  bool get _isEditing => _editingTransaction != null;

  late String _selectedType;
  String? _selectedCategoryId;
  late String _selectedCurrency;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final List<String> _paymentMethods = [
    'Cash',
    'Credit Card',
    'Debit Card',
    'Bank Transfer',
    'Mobile Payment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<TransactionController>()
        ? Get.find<TransactionController>()
        : Get.put(TransactionController());

    // Ensure categories are loaded
    if (_controller.categories.isEmpty) {
      _controller.loadCategories();
    }

    _initFromArguments();
  }

  void _initFromArguments() {
    final args = Get.arguments;

    // Detect user's active/preferred currency
    String defaultCurrency = 'USD';
    if (Get.isRegistered<AuthController>()) {
      final pref = Get.find<AuthController>().userModel.value?.preferredCurrency;
      if (pref != null && pref.isNotEmpty) {
        defaultCurrency = pref;
      }
    } else if (Get.isRegistered<AnalyticsController>()) {
      defaultCurrency = Get.find<AnalyticsController>().selectedCurrency.value;
    }

    if (args is TransactionModel) {
      _editingTransaction = args;
      _selectedType = args.type;
      _selectedCategoryId = args.categoryId;
      _selectedCurrency = args.currency;
      _selectedPaymentMethod = args.paymentMethod;
      _selectedDate = args.transactionDate;
      _amountController.text = CurrencyFormatter.minorToFormString(
        args.amountMinor,
        currency: args.currency,
      );
      _descriptionController.text = args.description;
      _noteController.text = args.note;
    } else if (args is Map<String, dynamic>) {
      _selectedType = args['type'] ?? 'expense';
      _selectedCategoryId = null;
      _selectedCurrency = args['currency'] ?? defaultCurrency;
      _selectedPaymentMethod = 'Cash';
      _selectedDate = DateTime.now();
    } else {
      _selectedType = 'expense';
      _selectedCategoryId = null;
      _selectedCurrency = defaultCurrency;
      _selectedPaymentMethod = 'Cash';
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'Cash':
        return Icons.payments_rounded;
      case 'Credit Card':
      case 'Debit Card':
        return Icons.credit_card_rounded;
      case 'Bank Transfer':
        return Icons.account_balance_rounded;
      case 'Mobile Payment':
        return Icons.phone_android_rounded;
      default:
        return Icons.wallet_rounded;
    }
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _selectedType == 'expense'
                      ? AppColors.expense
                      : AppColors.income,
                ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );

      setState(() {
        _selectedDate = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime?.hour ?? _selectedDate.hour,
          pickedTime?.minute ?? _selectedDate.minute,
        );
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      Get.snackbar(
        'Missing Category',
        'Please select a category for this transaction.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange.shade700,
        colorText: Colors.white,
      );
      return;
    }

    final amountMinor = CurrencyFormatter.parseToMinor(
      _amountController.text.trim(),
      currency: _selectedCurrency,
    );

    if (amountMinor <= 0) {
      Get.snackbar(
        'Invalid Amount',
        'Amount must be greater than zero.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade600,
        colorText: Colors.white,
      );
      return;
    }

    final payload = {
      'type': _selectedType,
      'amountMinor': amountMinor,
      'currency': _selectedCurrency,
      'categoryId': _selectedCategoryId,
      'description': _descriptionController.text.trim(),
      'paymentMethod': _selectedPaymentMethod,
      'transactionDate': _selectedDate.toIso8601String(),
      'note': _noteController.text.trim(),
    };

    if (_isEditing) {
      _controller.updateTransaction(_editingTransaction!.id, payload);
    } else {
      _controller.createTransaction(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = _selectedType == 'expense' ? AppColors.expense : AppColors.income;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'edit_transaction'.tr : 'add_transaction'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // Segmented Type Selector (Expense vs Income)
              _buildTypeSelector(isDark),

              const SizedBox(height: 20),

              // Hero Amount Card
              _buildAmountCard(primaryColor, isDark),

              const SizedBox(height: 24),

              // Category Selector
              _buildCategorySection(primaryColor, isDark),

              const SizedBox(height: 24),

              // Description Field
              CustomTextField(
                controller: _descriptionController,
                label: 'description'.tr,
                hint: 'description_hint'.tr,
                prefixIcon: Icons.edit_note_rounded,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'enter_description'.tr;
                  }
                  if (val.trim().length > 200) {
                    return 'Description cannot exceed 200 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Date & Time Picker
              _buildDatePicker(primaryColor, isDark),

              const SizedBox(height: 18),

              // Payment Method Chips
              _buildPaymentMethodSection(primaryColor, isDark),

              const SizedBox(height: 18),

              // Note Field (Optional)
              CustomTextField(
                controller: _noteController,
                label: 'note_optional'.tr,
                hint: 'note_hint'.tr,
                prefixIcon: Icons.notes_rounded,
                maxLines: 3,
                validator: (val) {
                  if (val != null && val.trim().length > 500) {
                    return 'Note cannot exceed 500 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Submit Button
              Obx(() => CustomButton(
                    text: _isEditing
                        ? 'update_transaction'.tr
                        : (_selectedType == 'expense' ? 'record_expense'.tr : 'record_income'.tr),
                    icon: _isEditing ? Icons.save_rounded : Icons.check_circle_rounded,
                    backgroundColor: primaryColor,
                    isLoading: _controller.isSubmitting.value,
                    onPressed: _submit,
                  )),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'expense';
                  _selectedCategoryId = null; // reset category on type switch
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'expense'
                      ? AppColors.expense
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedType == 'expense'
                      ? [
                          BoxShadow(
                            color: AppColors.expense.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_downward_rounded,
                      size: 18,
                      color: _selectedType == 'expense'
                          ? Colors.white
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'expense'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _selectedType == 'expense'
                            ? Colors.white
                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedType = 'income';
                  _selectedCategoryId = null; // reset category on type switch
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedType == 'income'
                      ? AppColors.income
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _selectedType == 'income'
                      ? [
                          BoxShadow(
                            color: AppColors.income.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.arrow_upward_rounded,
                      size: 18,
                      color: _selectedType == 'income'
                          ? Colors.white
                          : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'income'.tr,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: _selectedType == 'income'
                            ? Colors.white
                            : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(Color primaryColor, bool isDark) {
    final isKhr = _selectedCurrency == 'KHR';
    final currencySymbol = isKhr ? '៛' : '\$';
    final quickOptions = isKhr ? [5000, 10000, 20000, 50000] : [10, 20, 50, 100];

    return CardContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'amount'.tr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              // Currency Switcher
              Container(
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCurrencyChip('USD', primaryColor),
                    _buildCurrencyChip('KHR', primaryColor),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                currencySymbol,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: isKhr ? '0' : '0.00',
                    hintStyle: TextStyle(
                      color: primaryColor.withValues(alpha: 0.35),
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Enter an amount';
                    }
                    final parsed = double.tryParse(val.replaceAll(',', '').trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Quick amount increment buttons
          Wrap(
            spacing: 8,
            children: quickOptions.map((quickAdd) {
              final label = isKhr
                  ? '+${NumberFormat('#,##0').format(quickAdd)} ៛'
                  : '+\$$quickAdd';
              return ActionChip(
                label: Text(label),
                padding: EdgeInsets.zero,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
                backgroundColor: primaryColor.withValues(alpha: 0.08),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                onPressed: () {
                  final current = double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0.0;
                  final updated = current + quickAdd;
                  _amountController.text = isKhr
                      ? updated.round().toString()
                      : updated.toStringAsFixed(2);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyChip(String curr, Color primaryColor) {
    final isSelected = _selectedCurrency == curr;
    return GestureDetector(
      onTap: () {
        if (_selectedCurrency != curr) {
          setState(() {
            _selectedCurrency = curr;
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          curr == 'KHR' ? '៛ KHR' : '\$ USD',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(Color primaryColor, bool isDark) {
    return Obx(() {
      final filteredCategories = _controller.categories
          .where((cat) => cat.type == _selectedType)
          .toList();

      if (_controller.categories.isNotEmpty &&
          _selectedCategoryId == null &&
          filteredCategories.isNotEmpty) {
        _selectedCategoryId = filteredCategories.first.id;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'category'.tr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              Text(
                '${filteredCategories.length} available',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (filteredCategories.isEmpty)
            CardContainer(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  'No $_selectedType categories found.\nPlease check your categories in backend.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: filteredCategories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final cat = filteredCategories[index];
                  final isSelected = _selectedCategoryId == cat.id;
                  final catColor = cat.displayColor;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategoryId = cat.id;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 82,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? catColor.withValues(alpha: 0.18)
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? catColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(cat.displayIcon, size: 22, color: catColor),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? catColor : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    });
  }

  Widget _buildDatePicker(Color primaryColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'date_time'.tr,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_month_rounded, size: 20, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormatter.formatRelativeOrDate(_selectedDate),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  'Change',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getLocalizedPaymentMethod(String method) {
    switch (method) {
      case 'Cash':
        return 'payment_cash'.tr;
      case 'Credit Card':
        return 'payment_credit_card'.tr;
      case 'Debit Card':
        return 'payment_debit_card'.tr;
      case 'Bank Transfer':
        return 'payment_bank_transfer'.tr;
      case 'Mobile Payment':
        return 'payment_mobile_payment'.tr;
      default:
        return 'payment_other'.tr;
    }
  }

  Widget _buildPaymentMethodSection(Color primaryColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'payment_method'.tr,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paymentMethods.map((method) {
            final isSelected = _selectedPaymentMethod == method;
            return ChoiceChip(
              avatar: Icon(
                _getPaymentIcon(method),
                size: 16,
                color: isSelected ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade700),
              ),
              label: Text(_getLocalizedPaymentMethod(method)),
              selected: isSelected,
              selectedColor: primaryColor,
              backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : null,
              ),
              side: BorderSide(
                color: isSelected ? primaryColor : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedPaymentMethod = method;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

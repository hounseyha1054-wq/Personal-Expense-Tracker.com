const Budget = require('../models/Budget');
const Transaction = require('../models/Transaction');
const { Category } = require('../models/Category');

class BudgetService {
  /**
   * List all budgets for a user and month, with live calculation of actual spending from transactions
   * Strictly isolated by currency (USD or KHR) to avoid summing different currencies together
   */
  async listBudgets(firebaseUid, month, currency = null) {
    const currentMonth = month || new Date().toISOString().slice(0, 7); // 'YYYY-MM'
    
    // Parse month bounds
    const [yearStr, monthStr] = currentMonth.split('-');
    const year = parseInt(yearStr, 10);
    const mIndex = parseInt(monthStr, 10) - 1;
    const startOfMonth = new Date(year, mIndex, 1);
    const endOfMonth = new Date(year, mIndex + 1, 0, 23, 59, 59, 999);

    const budgetFilter = {
      firebaseUid,
      month: currentMonth,
    };
    if (currency) {
      budgetFilter.currency = currency;
    }

    // Fetch user budgets for this month
    const budgets = await Budget.find(budgetFilter)
      .populate('categoryId', 'name icon color type')
      .lean();

    const expenseFilter = {
      firebaseUid,
      type: 'expense',
      transactionDate: { $gte: startOfMonth, $lte: endOfMonth },
    };
    if (currency) {
      expenseFilter.currency = currency;
    }

    // Fetch actual expense spending grouped by category for this month
    const expenses = await Transaction.aggregate([
      {
        $match: expenseFilter,
      },
      {
        $group: {
          _id: '$categoryId',
          spentMinor: { $sum: '$amountMinor' },
        },
      },
    ]);

    const spendingMap = {};
    expenses.forEach((item) => {
      spendingMap[item._id.toString()] = item.spentMinor;
    });

    // Augment budgets with spending, remaining, percentUsed, warnings
    let totalBudgetMinor = 0;
    let totalSpentMinor = 0;

    const enrichedBudgets = budgets.map((b) => {
      const categoryIdStr = b.categoryId ? b.categoryId._id.toString() : '';
      const spentMinor = spendingMap[categoryIdStr] || 0;
      const budgetMinor = b.amountMinor;
      const remainingMinor = budgetMinor - spentMinor;
      const percentageUsed = budgetMinor > 0 ? Math.round((spentMinor / budgetMinor) * 100) : 0;
      
      const isWarning = percentageUsed >= 80 && percentageUsed <= 100;
      const isOverBudget = percentageUsed > 100;

      totalBudgetMinor += budgetMinor;
      totalSpentMinor += spentMinor;

      return {
        ...b,
        spentMinor,
        remainingMinor,
        percentageUsed,
        isWarning,
        isOverBudget,
      };
    });

    const overallRemainingMinor = totalBudgetMinor - totalSpentMinor;
    const overallPercentageUsed = totalBudgetMinor > 0 ? Math.round((totalSpentMinor / totalBudgetMinor) * 100) : 0;

    return {
      month: currentMonth,
      summary: {
        totalBudgetMinor,
        totalSpentMinor,
        remainingMinor: overallRemainingMinor,
        percentageUsed: overallPercentageUsed,
        isWarning: overallPercentageUsed >= 80 && overallPercentageUsed <= 100,
        isOverBudget: overallPercentageUsed > 100,
      },
      budgets: enrichedBudgets,
    };
  }

  async createBudget(firebaseUid, data) {
    // Validate category
    const category = await Category.findOne({
      _id: data.categoryId,
      firebaseUid,
    });
    if (!category) {
      const error = new Error('Category not found');
      error.statusCode = 404;
      throw error;
    }

    if (category.type !== 'expense') {
      const error = new Error('Budgets can only be configured for expense categories');
      error.statusCode = 400;
      throw error;
    }

    // Check existing budget for this category and month
    const existing = await Budget.findOne({
      firebaseUid,
      categoryId: data.categoryId,
      month: data.month,
    });
    if (existing) {
      const error = new Error(`A budget for "${category.name}" in month ${data.month} already exists. Please update it instead.`);
      error.statusCode = 409;
      throw error;
    }

    const budget = await Budget.create({
      ...data,
      firebaseUid,
    });

    return await budget.populate('categoryId', 'name icon color type');
  }

  async updateBudget(firebaseUid, budgetId, data) {
    const budget = await Budget.findOne({ _id: budgetId, firebaseUid });
    if (!budget) {
      const error = new Error('Budget not found');
      error.statusCode = 404;
      throw error;
    }

    if (data.categoryId) {
      const category = await Category.findOne({ _id: data.categoryId, firebaseUid });
      if (!category) {
        const error = new Error('Category not found');
        error.statusCode = 404;
        throw error;
      }
      if (category.type !== 'expense') {
        const error = new Error('Budgets can only be configured for expense categories');
        error.statusCode = 400;
        throw error;
      }
      budget.categoryId = data.categoryId;
    }

    if (data.amountMinor !== undefined) budget.amountMinor = data.amountMinor;
    if (data.currency) budget.currency = data.currency;
    if (data.month) budget.month = data.month;

    await budget.save();
    return await budget.populate('categoryId', 'name icon color type');
  }

  async deleteBudget(firebaseUid, budgetId) {
    const budget = await Budget.findOneAndDelete({ _id: budgetId, firebaseUid });
    if (!budget) {
      const error = new Error('Budget not found');
      error.statusCode = 404;
      throw error;
    }
    return { message: 'Budget deleted successfully', deletedId: budgetId };
  }
}

module.exports = new BudgetService();

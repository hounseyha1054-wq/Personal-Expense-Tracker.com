const mongoose = require('mongoose');
const Transaction = require('../models/Transaction');

class AnalyticsService {
  /**
   * Overall financial summary for dashboard, strictly isolated by currency (USD or KHR)
   */
  async getSummary(firebaseUid, currency = 'USD', startDate = null, endDate = null) {
    const now = new Date();
    const startOfCurrentMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const endOfCurrentMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);

    // Lifetime totals for the selected currency only
    const lifetimeAggregation = await Transaction.aggregate([
      { $match: { firebaseUid, currency } },
      {
        $group: {
          _id: '$type',
          totalMinor: { $sum: '$amountMinor' },
          count: { $sum: 1 },
        },
      },
    ]);

    let totalIncomeMinor = 0;
    let totalExpenseMinor = 0;
    let totalTransactions = 0;

    lifetimeAggregation.forEach((item) => {
      totalTransactions += item.count;
      if (item._id === 'income') {
        totalIncomeMinor = item.totalMinor;
      } else if (item._id === 'expense') {
        totalExpenseMinor = item.totalMinor;
      }
    });

    const totalBalanceMinor = totalIncomeMinor - totalExpenseMinor;

    // Current month totals for the selected currency only
    const monthAggregation = await Transaction.aggregate([
      {
        $match: {
          firebaseUid,
          currency,
          transactionDate: { $gte: startOfCurrentMonth, $lte: endOfCurrentMonth },
        },
      },
      {
        $group: {
          _id: '$type',
          totalMinor: { $sum: '$amountMinor' },
        },
      },
    ]);

    let currentMonthIncomeMinor = 0;
    let currentMonthExpenseMinor = 0;

    monthAggregation.forEach((item) => {
      if (item._id === 'income') {
        currentMonthIncomeMinor = item.totalMinor;
      } else if (item._id === 'expense') {
        currentMonthExpenseMinor = item.totalMinor;
      }
    });

    const currentMonthBalanceMinor = currentMonthIncomeMinor - currentMonthExpenseMinor;

    // Optional period summary (e.g. for custom month or year selection)
    let periodSummary = null;
    if (startDate || endDate) {
      const periodFilter = { firebaseUid, currency };
      periodFilter.transactionDate = {};
      if (startDate) periodFilter.transactionDate.$gte = new Date(startDate);
      if (endDate) {
        const end = new Date(endDate);
        if (endDate.length <= 10) end.setHours(23, 59, 59, 999);
        periodFilter.transactionDate.$lte = end;
      }

      const periodAgg = await Transaction.aggregate([
        { $match: periodFilter },
        {
          $group: {
            _id: '$type',
            totalMinor: { $sum: '$amountMinor' },
            count: { $sum: 1 },
          },
        },
      ]);

      let periodIncomeMinor = 0;
      let periodExpenseMinor = 0;
      let periodCount = 0;

      periodAgg.forEach((item) => {
        periodCount += item.count;
        if (item._id === 'income') {
          periodIncomeMinor = item.totalMinor;
        } else if (item._id === 'expense') {
          periodExpenseMinor = item.totalMinor;
        }
      });

      periodSummary = {
        startDate,
        endDate,
        incomeMinor: periodIncomeMinor,
        expenseMinor: periodExpenseMinor,
        balanceMinor: periodIncomeMinor - periodExpenseMinor,
        transactionCount: periodCount,
      };
    }

    // Recent 5 transactions for the selected currency only
    const recentTransactions = await Transaction.find({ firebaseUid, currency })
      .populate('categoryId', 'name icon color type')
      .sort({ transactionDate: -1 })
      .limit(5)
      .lean();

    return {
      currency,
      totalBalanceMinor,
      totalIncomeMinor,
      totalExpenseMinor,
      totalTransactions,
      currentMonth: {
        monthString: now.toISOString().slice(0, 7),
        incomeMinor: currentMonthIncomeMinor,
        expenseMinor: currentMonthExpenseMinor,
        balanceMinor: currentMonthBalanceMinor,
      },
      periodSummary,
      recentTransactions,
    };
  }

  /**
   * Monthly breakdown for line/bar charts, strictly isolated by currency
   */
  async getMonthlyBreakdown(firebaseUid, monthsCount = 6, year = null, currency = 'USD') {
    if (year) {
      const startOfYear = new Date(year, 0, 1);
      const endOfYear = new Date(year, 11, 31, 23, 59, 59, 999);

      const monthlyStats = await Transaction.aggregate([
        {
          $match: {
            firebaseUid,
            currency,
            transactionDate: { $gte: startOfYear, $lte: endOfYear },
          },
        },
        {
          $group: {
            _id: {
              yearMonth: { $dateToString: { format: '%Y-%m', date: '$transactionDate' } },
              type: '$type',
            },
            totalMinor: { $sum: '$amountMinor' },
          },
        },
      ]);

      const result = [];
      const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      for (let m = 0; m < 12; m++) {
        const monthNum = String(m + 1).padStart(2, '0');
        const key = `${year}-${monthNum}`;
        const label = monthNames[m];

        const incomeItem = monthlyStats.find((s) => s._id.yearMonth === key && s._id.type === 'income');
        const expenseItem = monthlyStats.find((s) => s._id.yearMonth === key && s._id.type === 'expense');

        const incomeMinor = incomeItem ? incomeItem.totalMinor : 0;
        const expenseMinor = expenseItem ? expenseItem.totalMinor : 0;

        result.push({
          month: key,
          monthIndex: m + 1,
          label,
          incomeMinor,
          expenseMinor,
          netSavingsMinor: incomeMinor - expenseMinor,
        });
      }

      return result;
    }

    const now = new Date();
    const startDate = new Date(now.getFullYear(), now.getMonth() - (monthsCount - 1), 1);

    const monthlyStats = await Transaction.aggregate([
      {
        $match: {
          firebaseUid,
          currency,
          transactionDate: { $gte: startDate },
        },
      },
      {
        $group: {
          _id: {
            yearMonth: { $dateToString: { format: '%Y-%m', date: '$transactionDate' } },
            type: '$type',
          },
          totalMinor: { $sum: '$amountMinor' },
        },
      },
    ]);

    // Build ordered list of the past N months
    const result = [];
    for (let i = monthsCount - 1; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const key = d.toISOString().slice(0, 7);
      const monthLabel = d.toLocaleString('en-US', { month: 'short' });

      const incomeItem = monthlyStats.find((s) => s._id.yearMonth === key && s._id.type === 'income');
      const expenseItem = monthlyStats.find((s) => s._id.yearMonth === key && s._id.type === 'expense');

      const incomeMinor = incomeItem ? incomeItem.totalMinor : 0;
      const expenseMinor = expenseItem ? expenseItem.totalMinor : 0;

      result.push({
        month: key,
        monthIndex: d.getMonth() + 1,
        label: monthLabel,
        incomeMinor,
        expenseMinor,
        netSavingsMinor: incomeMinor - expenseMinor,
      });
    }

    return result;
  }

  /**
   * Category spending breakdown (for pie charts), strictly isolated by currency
   */
  async getCategoryBreakdown(firebaseUid, query = {}) {
    const { startDate, endDate, type = 'expense', currency = 'USD' } = query;

    const matchFilter = { firebaseUid, type, currency };
    if (startDate || endDate) {
      matchFilter.transactionDate = {};
      if (startDate) matchFilter.transactionDate.$gte = new Date(startDate);
      if (endDate) {
        const end = new Date(endDate);
        if (endDate.length <= 10) end.setHours(23, 59, 59, 999);
        matchFilter.transactionDate.$lte = end;
      }
    }

    const aggregation = await Transaction.aggregate([
      { $match: matchFilter },
      {
        $group: {
          _id: '$categoryId',
          totalAmountMinor: { $sum: '$amountMinor' },
          transactionCount: { $sum: 1 },
        },
      },
      {
        $lookup: {
          from: 'categories',
          localField: '_id',
          foreignField: '_id',
          as: 'category',
        },
      },
      { $unwind: '$category' },
      { $sort: { totalAmountMinor: -1 } },
    ]);

    const totalPeriodMinor = aggregation.reduce((sum, item) => sum + item.totalAmountMinor, 0);

    const breakdown = aggregation.map((item) => {
      const percentage = totalPeriodMinor > 0 ? parseFloat(((item.totalAmountMinor / totalPeriodMinor) * 100).toFixed(1)) : 0;
      return {
        categoryId: item._id,
        categoryName: item.category.name,
        icon: item.category.icon,
        color: item.category.color,
        type: item.category.type,
        totalAmountMinor: item.totalAmountMinor,
        transactionCount: item.transactionCount,
        percentage,
      };
    });

    return {
      totalAmountMinor: totalPeriodMinor,
      type,
      breakdown,
    };
  }

  /**
   * Financial trends, weekly spending and top spending category, isolated by currency
   */
  async getTrends(firebaseUid, currency = 'USD') {
    const now = new Date();
    // Past 4 weeks (28 days)
    const twentyEightDaysAgo = new Date(now.getTime() - 28 * 24 * 60 * 60 * 1000);

    const weeklyExpenses = await Transaction.aggregate([
      {
        $match: {
          firebaseUid,
          currency,
          type: 'expense',
          transactionDate: { $gte: twentyEightDaysAgo },
        },
      },
      {
        $group: {
          _id: {
            week: { $isoWeek: '$transactionDate' },
            year: { $isoWeekYear: '$transactionDate' },
          },
          totalMinor: { $sum: '$amountMinor' },
          count: { $sum: 1 },
        },
      },
      { $sort: { '_id.year': 1, '_id.week': 1 } },
    ]);

    // Top expense category lifetime for selected currency
    const topCategoryAgg = await Transaction.aggregate([
      { $match: { firebaseUid, currency, type: 'expense' } },
      {
        $group: {
          _id: '$categoryId',
          totalSpentMinor: { $sum: '$amountMinor' },
        },
      },
      { $sort: { totalSpentMinor: -1 } },
      { $limit: 1 },
      {
        $lookup: {
          from: 'categories',
          localField: '_id',
          foreignField: '_id',
          as: 'cat',
        },
      },
      { $unwind: '$cat' },
    ]);

    const topCategory = topCategoryAgg[0]
      ? {
          name: topCategoryAgg[0].cat.name,
          icon: topCategoryAgg[0].cat.icon,
          color: topCategoryAgg[0].cat.color,
          totalSpentMinor: topCategoryAgg[0].totalSpentMinor,
        }
      : null;

    return {
      weeklyExpenses: weeklyExpenses.map((w) => ({
        week: `Week ${w._id.week}`,
        totalMinor: w.totalMinor,
        count: w.count,
      })),
      mostExpensiveCategory: topCategory,
    };
  }
}

module.exports = new AnalyticsService();

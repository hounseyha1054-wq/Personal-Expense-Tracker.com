const Transaction = require('../models/Transaction');
const { Category } = require('../models/Category');

class TransactionService {
  async listTransactions(firebaseUid, query = {}) {
    const {
      type,
      categoryId,
      currency,
      startDate,
      endDate,
      search,
      page = 1,
      limit = 20,
      sortBy = 'transactionDate',
      sortOrder = 'desc',
    } = query;

    const filter = { firebaseUid };

    if (type) {
      filter.type = type;
    }

    if (categoryId) {
      filter.categoryId = categoryId;
    }

    if (currency) {
      filter.currency = currency;
    }

    if (startDate || endDate) {
      filter.transactionDate = {};
      if (startDate) {
        filter.transactionDate.$gte = new Date(startDate);
      }
      if (endDate) {
        // Set end of day if only YYYY-MM-DD
        const end = new Date(endDate);
        if (endDate.length <= 10) {
          end.setHours(23, 59, 59, 999);
        }
        filter.transactionDate.$lte = end;
      }
    }

    if (search && search.trim()) {
      filter.description = { $regex: search.trim(), $options: 'i' };
    }

    const pageNum = parseInt(page, 10);
    const limitNum = parseInt(limit, 10);
    const skip = (pageNum - 1) * limitNum;
    const sort = { [sortBy]: sortOrder === 'asc' ? 1 : -1 };

    const [transactions, total] = await Promise.all([
      Transaction.find(filter)
        .populate('categoryId', 'name icon color type')
        .sort(sort)
        .skip(skip)
        .limit(limitNum)
        .lean(),
      Transaction.countDocuments(filter),
    ]);

    return {
      transactions,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum) || 1,
      },
    };
  }

  async getTransactionById(firebaseUid, transactionId) {
    const transaction = await Transaction.findOne({
      _id: transactionId,
      firebaseUid,
    }).populate('categoryId', 'name icon color type');

    return transaction;
  }

  async createTransaction(firebaseUid, data) {
    // Verify that category exists and belongs to user
    const category = await Category.findOne({
      _id: data.categoryId,
      firebaseUid,
    });

    if (!category) {
      const error = new Error('Selected category not found or does not belong to you');
      error.statusCode = 404;
      throw error;
    }

    // Ensure category type matches transaction type
    if (category.type !== data.type) {
      const error = new Error(`Category type '${category.type}' does not match transaction type '${data.type}'`);
      error.statusCode = 400;
      throw error;
    }

    const transaction = await Transaction.create({
      ...data,
      firebaseUid,
    });

    return await transaction.populate('categoryId', 'name icon color type');
  }

  async updateTransaction(firebaseUid, transactionId, data) {
    const transaction = await Transaction.findOne({ _id: transactionId, firebaseUid });
    if (!transaction) {
      const error = new Error('Transaction not found');
      error.statusCode = 404;
      throw error;
    }

    if (data.categoryId) {
      const category = await Category.findOne({
        _id: data.categoryId,
        firebaseUid,
      });
      if (!category) {
        const error = new Error('Selected category not found');
        error.statusCode = 404;
        throw error;
      }
      const targetType = data.type || transaction.type;
      if (category.type !== targetType) {
        const error = new Error(`Category type '${category.type}' does not match transaction type '${targetType}'`);
        error.statusCode = 400;
        throw error;
      }
    }

    Object.assign(transaction, data);
    await transaction.save();

    return await transaction.populate('categoryId', 'name icon color type');
  }

  async deleteTransaction(firebaseUid, transactionId) {
    const transaction = await Transaction.findOneAndDelete({
      _id: transactionId,
      firebaseUid,
    });

    if (!transaction) {
      const error = new Error('Transaction not found');
      error.statusCode = 404;
      throw error;
    }

    return transaction;
  }
}

module.exports = new TransactionService();

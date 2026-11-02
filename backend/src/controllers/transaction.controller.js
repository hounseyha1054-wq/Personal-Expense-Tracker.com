const transactionService = require('../services/transaction.service');

class TransactionController {
  /**
   * GET /api/v1/transactions
   */
  async list(req, res, next) {
    try {
      const result = await transactionService.listTransactions(req.user.uid, req.query);
      return res.status(200).json({
        success: true,
        data: result.transactions,
        pagination: result.pagination,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/transactions
   */
  async create(req, res, next) {
    try {
      const transaction = await transactionService.createTransaction(req.user.uid, req.body);
      return res.status(201).json({
        success: true,
        message: 'Transaction recorded successfully',
        data: transaction,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/transactions/:id
   */
  async getById(req, res, next) {
    try {
      const transaction = await transactionService.getTransactionById(req.user.uid, req.params.id);
      if (!transaction) {
        return res.status(404).json({
          success: false,
          message: 'Transaction not found',
        });
      }
      return res.status(200).json({
        success: true,
        data: transaction,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/v1/transactions/:id
   */
  async update(req, res, next) {
    try {
      const transaction = await transactionService.updateTransaction(req.user.uid, req.params.id, req.body);
      return res.status(200).json({
        success: true,
        message: 'Transaction updated successfully',
        data: transaction,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/v1/transactions/:id
   */
  async delete(req, res, next) {
    try {
      await transactionService.deleteTransaction(req.user.uid, req.params.id);
      return res.status(200).json({
        success: true,
        message: 'Transaction deleted successfully',
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new TransactionController();

const budgetService = require('../services/budget.service');

class BudgetController {
  /**
   * GET /api/v1/budgets
   */
  async list(req, res, next) {
    try {
      const result = await budgetService.listBudgets(
        req.user.uid,
        req.query.month,
        req.query.currency
      );
      return res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/budgets
   */
  async create(req, res, next) {
    try {
      const budget = await budgetService.createBudget(req.user.uid, req.body);
      return res.status(201).json({
        success: true,
        message: 'Budget created successfully',
        data: budget,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/v1/budgets/:id
   */
  async update(req, res, next) {
    try {
      const budget = await budgetService.updateBudget(req.user.uid, req.params.id, req.body);
      return res.status(200).json({
        success: true,
        message: 'Budget updated successfully',
        data: budget,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/v1/budgets/:id
   */
  async delete(req, res, next) {
    try {
      const result = await budgetService.deleteBudget(req.user.uid, req.params.id);
      return res.status(200).json({
        success: true,
        message: result.message,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new BudgetController();

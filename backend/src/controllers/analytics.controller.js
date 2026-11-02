const analyticsService = require('../services/analytics.service');

class AnalyticsController {
  /**
   * GET /api/v1/analytics/summary
   */
  async getSummary(req, res, next) {
    try {
      const { currency, startDate, endDate } = req.query;
      const summary = await analyticsService.getSummary(
        req.user.uid,
        currency,
        startDate,
        endDate
      );
      return res.status(200).json({
        success: true,
        data: summary,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/analytics/monthly
   */
  async getMonthly(req, res, next) {
    try {
      const months = req.query.months ? parseInt(req.query.months, 10) : 6;
      const year = req.query.year ? parseInt(req.query.year, 10) : null;
      const currency = req.query.currency || 'USD';
      const data = await analyticsService.getMonthlyBreakdown(req.user.uid, months, year, currency);
      return res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/analytics/categories
   */
  async getCategories(req, res, next) {
    try {
      const data = await analyticsService.getCategoryBreakdown(req.user.uid, req.query);
      return res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/analytics/trends
   */
  async getTrends(req, res, next) {
    try {
      const currency = req.query.currency || 'USD';
      const data = await analyticsService.getTrends(req.user.uid, currency);
      return res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AnalyticsController();

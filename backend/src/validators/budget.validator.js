const { body, param, query } = require('express-validator');

const createBudgetValidator = [
  body('categoryId')
    .isMongoId()
    .withMessage('Valid categoryId is required'),
  body('amountMinor')
    .isInt({ gt: 0 })
    .withMessage('Budget amount must be a positive integer in minor units'),
  body('currency')
    .optional()
    .isIn(['USD', 'KHR'])
    .withMessage("Currency must be 'USD' or 'KHR'"),
  body('month')
    .matches(/^\d{4}-(0[1-9]|1[0-2])$/)
    .withMessage('Month must be in YYYY-MM format'),
];

const updateBudgetValidator = [
  param('id')
    .isMongoId()
    .withMessage('Valid budget ID parameter is required'),
  body('amountMinor')
    .optional()
    .isInt({ gt: 0 })
    .withMessage('Budget amount must be a positive integer in minor units'),
  body('currency')
    .optional()
    .isIn(['USD', 'KHR'])
    .withMessage("Currency must be 'USD' or 'KHR'"),
  body('month')
    .optional()
    .matches(/^\d{4}-(0[1-9]|1[0-2])$/)
    .withMessage('Month must be in YYYY-MM format'),
];

const budgetIdValidator = [
  param('id')
    .isMongoId()
    .withMessage('Valid budget ID parameter is required'),
];

const listBudgetsValidator = [
  query('month')
    .optional()
    .matches(/^\d{4}-(0[1-9]|1[0-2])$/)
    .withMessage('Month must be in YYYY-MM format'),
];

module.exports = {
  createBudgetValidator,
  updateBudgetValidator,
  budgetIdValidator,
  listBudgetsValidator,
};

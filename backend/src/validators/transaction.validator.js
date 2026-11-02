const { body, param, query } = require('express-validator');

const createTransactionValidator = [
  body('type')
    .isIn(['income', 'expense'])
    .withMessage("Transaction type must be 'income' or 'expense'"),
  body('amountMinor')
    .isInt({ gt: 0 })
    .withMessage('Amount in minor units must be a positive integer'),
  body('currency')
    .optional()
    .isIn(['USD', 'KHR'])
    .withMessage("Currency must be 'USD' or 'KHR'"),
  body('categoryId')
    .isMongoId()
    .withMessage('Valid categoryId is required'),
  body('description')
    .trim()
    .notEmpty()
    .withMessage('Description is required')
    .isLength({ max: 200 })
    .withMessage('Description cannot exceed 200 characters'),
  body('paymentMethod')
    .optional()
    .isIn(['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Mobile Payment', 'Other'])
    .withMessage('Invalid payment method'),
  body('transactionDate')
    .optional()
    .isISO8601()
    .toDate()
    .withMessage('Invalid transaction date format'),
  body('note')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Note cannot exceed 500 characters'),
];

const updateTransactionValidator = [
  param('id')
    .isMongoId()
    .withMessage('Valid transaction ID is required in URL parameter'),
  body('type')
    .optional()
    .isIn(['income', 'expense'])
    .withMessage("Transaction type must be 'income' or 'expense'"),
  body('amountMinor')
    .optional()
    .isInt({ gt: 0 })
    .withMessage('Amount in minor units must be a positive integer'),
  body('currency')
    .optional()
    .isIn(['USD', 'KHR'])
    .withMessage("Currency must be 'USD' or 'KHR'"),
  body('categoryId')
    .optional()
    .isMongoId()
    .withMessage('Valid categoryId is required'),
  body('description')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Description cannot be empty')
    .isLength({ max: 200 })
    .withMessage('Description cannot exceed 200 characters'),
  body('paymentMethod')
    .optional()
    .isIn(['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Mobile Payment', 'Other'])
    .withMessage('Invalid payment method'),
  body('transactionDate')
    .optional()
    .isISO8601()
    .toDate()
    .withMessage('Invalid transaction date format'),
  body('note')
    .optional()
    .isLength({ max: 500 })
    .withMessage('Note cannot exceed 500 characters'),
];

const transactionIdValidator = [
  param('id')
    .isMongoId()
    .withMessage('Valid transaction ID parameter is required'),
];

const listTransactionsValidator = [
  query('type')
    .optional()
    .isIn(['income', 'expense'])
    .withMessage("Type filter must be 'income' or 'expense'"),
  query('categoryId')
    .optional()
    .isMongoId()
    .withMessage('Category filter must be a valid MongoId'),
  query('startDate')
    .optional()
    .isISO8601()
    .withMessage('startDate must be in valid ISO8601 date format'),
  query('endDate')
    .optional()
    .isISO8601()
    .withMessage('endDate must be in valid ISO8601 date format'),
  query('page')
    .optional()
    .isInt({ min: 1 })
    .withMessage('Page must be a positive integer'),
  query('limit')
    .optional()
    .isInt({ min: 1, max: 100 })
    .withMessage('Limit must be between 1 and 100'),
  query('search')
    .optional()
    .trim(),
  query('sortBy')
    .optional()
    .isIn(['transactionDate', 'amountMinor'])
    .withMessage("Sort field must be 'transactionDate' or 'amountMinor'"),
  query('sortOrder')
    .optional()
    .isIn(['asc', 'desc'])
    .withMessage("Sort order must be 'asc' or 'desc'"),
];

module.exports = {
  createTransactionValidator,
  updateTransactionValidator,
  transactionIdValidator,
  listTransactionsValidator,
};

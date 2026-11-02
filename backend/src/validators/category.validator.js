const { body, param, query } = require('express-validator');

const createCategoryValidator = [
  body('name')
    .trim()
    .notEmpty()
    .withMessage('Category name is required')
    .isLength({ max: 50 })
    .withMessage('Category name cannot exceed 50 characters'),
  body('type')
    .isIn(['income', 'expense'])
    .withMessage("Category type must be 'income' or 'expense'"),
  body('icon')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Icon cannot be empty'),
  body('color')
    .optional()
    .matches(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/)
    .withMessage('Color must be a valid hex color code (e.g. #4F46E5)'),
];

const updateCategoryValidator = [
  param('id')
    .isMongoId()
    .withMessage('Valid category ID parameter is required'),
  body('name')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Category name cannot be empty')
    .isLength({ max: 50 })
    .withMessage('Category name cannot exceed 50 characters'),
  body('type')
    .optional()
    .isIn(['income', 'expense'])
    .withMessage("Category type must be 'income' or 'expense'"),
  body('icon')
    .optional()
    .trim()
    .notEmpty()
    .withMessage('Icon cannot be empty'),
  body('color')
    .optional()
    .matches(/^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$/)
    .withMessage('Color must be a valid hex color code'),
];

const categoryIdValidator = [
  param('id')
    .isMongoId()
    .withMessage('Valid category ID parameter is required'),
];

const listCategoriesValidator = [
  query('type')
    .optional()
    .isIn(['income', 'expense'])
    .withMessage("Type must be 'income' or 'expense'"),
];

module.exports = {
  createCategoryValidator,
  updateCategoryValidator,
  categoryIdValidator,
  listCategoriesValidator,
};

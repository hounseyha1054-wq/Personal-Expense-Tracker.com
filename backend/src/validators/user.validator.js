const { body } = require('express-validator');

const updateProfileValidator = [
  body('name')
    .optional()
    .trim()
    .isLength({ max: 100 })
    .withMessage('Name cannot exceed 100 characters'),
  body('photoURL')
    .optional()
    .trim(),
];

const updatePreferencesValidator = [
  body('preferredCurrency')
    .optional()
    .isIn(['USD', 'KHR'])
    .withMessage("Preferred currency must be 'USD' or 'KHR'"),
  body('preferredLanguage')
    .optional()
    .isIn(['en', 'km', 'zh'])
    .withMessage("Preferred language must be 'en', 'km', or 'zh'"),
];

module.exports = {
  updateProfileValidator,
  updatePreferencesValidator,
};

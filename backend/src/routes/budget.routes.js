const express = require('express');
const budgetController = require('../controllers/budget.controller');
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');
const validateRequest = require('../middleware/validateRequest');
const {
  createBudgetValidator,
  updateBudgetValidator,
  budgetIdValidator,
  listBudgetsValidator,
} = require('../validators/budget.validator');

const router = express.Router();

router.use(verifyFirebaseToken);

router.get('/', listBudgetsValidator, validateRequest, budgetController.list);
router.post('/', createBudgetValidator, validateRequest, budgetController.create);
router.put('/:id', updateBudgetValidator, validateRequest, budgetController.update);
router.delete('/:id', budgetIdValidator, validateRequest, budgetController.delete);

module.exports = router;

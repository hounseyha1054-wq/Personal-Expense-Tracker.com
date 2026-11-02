const express = require('express');
const transactionController = require('../controllers/transaction.controller');
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');
const validateRequest = require('../middleware/validateRequest');
const {
  createTransactionValidator,
  updateTransactionValidator,
  transactionIdValidator,
  listTransactionsValidator,
} = require('../validators/transaction.validator');

const router = express.Router();

router.use(verifyFirebaseToken);

router.get('/', listTransactionsValidator, validateRequest, transactionController.list);
router.post('/', createTransactionValidator, validateRequest, transactionController.create);
router.get('/:id', transactionIdValidator, validateRequest, transactionController.getById);
router.put('/:id', updateTransactionValidator, validateRequest, transactionController.update);
router.delete('/:id', transactionIdValidator, validateRequest, transactionController.delete);

module.exports = router;

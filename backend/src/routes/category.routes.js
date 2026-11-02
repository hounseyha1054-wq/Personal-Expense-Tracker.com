const express = require('express');
const categoryController = require('../controllers/category.controller');
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');
const validateRequest = require('../middleware/validateRequest');
const {
  createCategoryValidator,
  updateCategoryValidator,
  categoryIdValidator,
  listCategoriesValidator,
} = require('../validators/category.validator');

const router = express.Router();

router.use(verifyFirebaseToken);

router.get('/', listCategoriesValidator, validateRequest, categoryController.list);
router.post('/', createCategoryValidator, validateRequest, categoryController.create);
router.put('/:id', updateCategoryValidator, validateRequest, categoryController.update);
router.delete('/:id', categoryIdValidator, validateRequest, categoryController.delete);

module.exports = router;

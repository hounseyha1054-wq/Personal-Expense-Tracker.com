const categoryService = require('../services/category.service');

class CategoryController {
  /**
   * GET /api/v1/categories
   */
  async list(req, res, next) {
    try {
      const categories = await categoryService.listCategories(req.user.uid, req.query.type);
      return res.status(200).json({
        success: true,
        data: categories,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/categories
   */
  async create(req, res, next) {
    try {
      const category = await categoryService.createCategory(req.user.uid, req.body);
      return res.status(201).json({
        success: true,
        message: 'Category created successfully',
        data: category,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/v1/categories/:id
   */
  async update(req, res, next) {
    try {
      const category = await categoryService.updateCategory(req.user.uid, req.params.id, req.body);
      return res.status(200).json({
        success: true,
        message: 'Category updated successfully',
        data: category,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * DELETE /api/v1/categories/:id
   */
  async delete(req, res, next) {
    try {
      const result = await categoryService.deleteCategory(req.user.uid, req.params.id);
      return res.status(200).json({
        success: true,
        message: result.message,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new CategoryController();

const { Category } = require('../models/Category');
const Transaction = require('../models/Transaction');
const Budget = require('../models/Budget');

class CategoryService {
  async listCategories(firebaseUid, type) {
    const filter = { firebaseUid };
    if (type) {
      filter.type = type;
    }
    const categories = await Category.find(filter).sort({ name: 1 }).lean();
    return categories;
  }

  async getCategoryById(firebaseUid, categoryId) {
    const category = await Category.findOne({ _id: categoryId, firebaseUid });
    return category;
  }

  async createCategory(firebaseUid, data) {
    // Check if category with same name & type already exists for this user
    const existing = await Category.findOne({
      firebaseUid,
      type: data.type,
      name: { $regex: new RegExp(`^${data.name.trim()}$`, 'i') },
    });

    if (existing) {
      const error = new Error(`A ${data.type} category named "${data.name}" already exists`);
      error.statusCode = 409;
      throw error;
    }

    const category = await Category.create({
      ...data,
      name: data.name.trim(),
      firebaseUid,
      isDefault: false,
    });

    return category;
  }

  async updateCategory(firebaseUid, categoryId, data) {
    const category = await Category.findOne({ _id: categoryId, firebaseUid });
    if (!category) {
      const error = new Error('Category not found');
      error.statusCode = 404;
      throw error;
    }

    if (data.name) {
      const existing = await Category.findOne({
        firebaseUid,
        type: data.type || category.type,
        name: { $regex: new RegExp(`^${data.name.trim()}$`, 'i') },
        _id: { $ne: categoryId },
      });
      if (existing) {
        const error = new Error(`A category named "${data.name}" already exists`);
        error.statusCode = 409;
        throw error;
      }
      category.name = data.name.trim();
    }

    if (data.icon) category.icon = data.icon;
    if (data.color) category.color = data.color;
    if (data.type) category.type = data.type;

    await category.save();
    return category;
  }

  async deleteCategory(firebaseUid, categoryId) {
    const category = await Category.findOne({ _id: categoryId, firebaseUid });
    if (!category) {
      const error = new Error('Category not found');
      error.statusCode = 404;
      throw error;
    }

    // Check if category is used in any transactions
    const transactionCount = await Transaction.countDocuments({
      firebaseUid,
      categoryId,
    });

    if (transactionCount > 0) {
      const error = new Error(
        `Cannot delete category "${category.name}" because it is currently used by ${transactionCount} transaction(s). Please reassign or delete those transactions first.`
      );
      error.statusCode = 400;
      throw error;
    }

    // Check if category is used in any budgets
    const budgetCount = await Budget.countDocuments({
      firebaseUid,
      categoryId,
    });

    if (budgetCount > 0) {
      const error = new Error(
        `Cannot delete category "${category.name}" because an active budget is configured for it.`
      );
      error.statusCode = 400;
      throw error;
    }

    await Category.deleteOne({ _id: categoryId, firebaseUid });
    return { message: 'Category deleted successfully', deletedId: categoryId };
  }
}

module.exports = new CategoryService();

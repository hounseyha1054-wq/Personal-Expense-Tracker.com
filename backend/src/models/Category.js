const mongoose = require('mongoose');

const categorySchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      required: true,
      index: true,
      trim: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      required: true,
      enum: ['income', 'expense'],
    },
    icon: {
      type: String,
      default: 'category',
    },
    color: {
      type: String,
      default: '#4F46E5', // Indigo primary
    },
    isDefault: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Compound index to prevent duplicate category names per user per type
categorySchema.index({ firebaseUid: 1, type: 1, name: 1 }, { unique: true });

const DEFAULT_EXPENSE_CATEGORIES = [
  { name: 'Food & Drinks', type: 'expense', icon: 'restaurant', color: '#EF4444', isDefault: true },
  { name: 'Shopping', type: 'expense', icon: 'shopping_bag', color: '#F59E0B', isDefault: true },
  { name: 'Transportation', type: 'expense', icon: 'directions_car', color: '#3B82F6', isDefault: true },
  { name: 'Bills', type: 'expense', icon: 'receipt_long', color: '#8B5CF6', isDefault: true },
  { name: 'Entertainment', type: 'expense', icon: 'sports_esports', color: '#EC4899', isDefault: true },
  { name: 'Education', type: 'expense', icon: 'school', color: '#10B981', isDefault: true },
  { name: 'Health', type: 'expense', icon: 'favorite', color: '#E11D48', isDefault: true },
  { name: 'Travel', type: 'expense', icon: 'flight', color: '#06B6D4', isDefault: true },
  { name: 'Other', type: 'expense', icon: 'more_horiz', color: '#64748B', isDefault: true },
];

const DEFAULT_INCOME_CATEGORIES = [
  { name: 'Salary', type: 'income', icon: 'payments', color: '#10B981', isDefault: true },
  { name: 'Freelance', type: 'income', icon: 'laptop_mac', color: '#059669', isDefault: true },
  { name: 'Business', type: 'income', icon: 'store', color: '#2563EB', isDefault: true },
  { name: 'Gift', type: 'income', icon: 'card_giftcard', color: '#D97706', isDefault: true },
  { name: 'Investment', type: 'income', icon: 'trending_up', color: '#7C3AED', isDefault: true },
  { name: 'Other', type: 'income', icon: 'attach_money', color: '#64748B', isDefault: true },
];

const Category = mongoose.model('Category', categorySchema);

module.exports = {
  Category,
  DEFAULT_EXPENSE_CATEGORIES,
  DEFAULT_INCOME_CATEGORIES,
};

const mongoose = require('mongoose');

const budgetSchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      required: true,
      index: true,
      trim: true,
    },
    categoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      required: true,
    },
    amountMinor: {
      type: Number,
      required: true,
      min: [1, 'Budget amount must be greater than zero'],
      validate: {
        validator: Number.isInteger,
        message: '{VALUE} is not an integer value for amountMinor',
      },
    },
    currency: {
      type: String,
      enum: ['USD', 'KHR'],
      default: 'USD',
    },
    month: {
      type: String,
      required: true, // Format: YYYY-MM
      match: [/^\d{4}-(0[1-9]|1[0-2])$/, 'Month must be in YYYY-MM format'],
      index: true,
    },
  },
  {
    timestamps: true,
  }
);

budgetSchema.index({ firebaseUid: 1, categoryId: 1, month: 1, currency: 1 }, { unique: true });

const Budget = mongoose.model('Budget', budgetSchema);

module.exports = Budget;

const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      required: true,
      index: true,
      trim: true,
    },
    type: {
      type: String,
      required: true,
      enum: ['income', 'expense'],
    },
    amountMinor: {
      type: Number,
      required: true,
      min: [1, 'Amount must be greater than zero'],
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
    categoryId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Category',
      required: true,
    },
    description: {
      type: String,
      required: true,
      trim: true,
      maxlength: 200,
    },
    paymentMethod: {
      type: String,
      enum: ['Cash', 'Credit Card', 'Debit Card', 'Bank Transfer', 'Mobile Payment', 'Other'],
      default: 'Cash',
    },
    transactionDate: {
      type: Date,
      default: Date.now,
      index: true,
    },
    note: {
      type: String,
      default: '',
      trim: true,
      maxlength: 500,
    },
  },
  {
    timestamps: true,
  }
);

// Compound indexes for fast filtered queries with currency isolation
transactionSchema.index({ firebaseUid: 1, currency: 1, transactionDate: -1 });
transactionSchema.index({ firebaseUid: 1, currency: 1, type: 1, transactionDate: -1 });
transactionSchema.index({ firebaseUid: 1, transactionDate: -1 });
transactionSchema.index({ firebaseUid: 1, type: 1, transactionDate: -1 });
transactionSchema.index({ firebaseUid: 1, categoryId: 1 });

const Transaction = mongoose.model('Transaction', transactionSchema);

module.exports = Transaction;

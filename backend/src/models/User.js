const mongoose = require('mongoose');

const userSchema = new mongoose.Schema(
  {
    firebaseUid: {
      type: String,
      required: true,
      unique: true,
      index: true,
      trim: true,
    },
    name: {
      type: String,
      default: '',
      trim: true,
    },
    email: {
      type: String,
      default: '',
      trim: true,
      lowercase: true,
    },
    photoURL: {
      type: String,
      default: '',
      trim: true,
    },
    preferredCurrency: {
      type: String,
      enum: ['USD', 'KHR'],
      default: 'USD',
    },
    preferredLanguage: {
      type: String,
      enum: ['en', 'km', 'zh'],
      default: 'en',
    },
    emailVerified: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

const User = mongoose.model('User', userSchema);
module.exports = User;

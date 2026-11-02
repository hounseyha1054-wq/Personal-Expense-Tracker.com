const User = require('../models/User');

class UserController {
  /**
   * GET /api/v1/users/profile
   */
  async getProfile(req, res, next) {
    try {
      const user = await User.findOne({ firebaseUid: req.user.uid });
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User profile not found',
        });
      }

      const isVerified = Boolean(req.user.email_verified || user.emailVerified);
      if (user.emailVerified !== isVerified) {
        user.emailVerified = isVerified;
        await user.save();
      }

      const data = user.toObject();
      data.emailVerified = isVerified;

      return res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/v1/users/profile
   */
  async updateProfile(req, res, next) {
    try {
      const { name, photoURL } = req.body;
      const user = await User.findOne({ firebaseUid: req.user.uid });

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User profile not found',
        });
      }

      if (name !== undefined) user.name = name;
      if (photoURL !== undefined) user.photoURL = photoURL;

      await user.save();

      return res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * POST /api/v1/users/avatar
   */
  async uploadAvatar(req, res, next) {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No image file provided',
        });
      }

      const user = await User.findOne({ firebaseUid: req.user.uid });
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User profile not found',
        });
      }

      // Store relative path
      const photoURL = `/uploads/avatars/${req.file.filename}`;
      user.photoURL = photoURL;
      await user.save();

      return res.status(200).json({
        success: true,
        message: 'Avatar uploaded successfully',
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * PUT /api/v1/users/preferences
   */
  async updatePreferences(req, res, next) {
    try {
      const { preferredCurrency, preferredLanguage } = req.body;
      const user = await User.findOne({ firebaseUid: req.user.uid });

      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User profile not found',
        });
      }

      if (preferredCurrency) {
        user.preferredCurrency = preferredCurrency;
      }
      if (preferredLanguage) {
        user.preferredLanguage = preferredLanguage;
      }
      await user.save();

      return res.status(200).json({
        success: true,
        message: 'Preferences updated successfully',
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new UserController();

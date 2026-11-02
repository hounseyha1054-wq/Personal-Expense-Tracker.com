const authService = require('../services/auth.service');

class AuthController {
  /**
   * POST /api/v1/auth/sync
   * Synchronize authenticated Firebase user with MongoDB
   */
  async sync(req, res, next) {
    try {
      const user = await authService.syncUser(req.user, req.body);
      return res.status(200).json({
        success: true,
        message: 'User profile synchronized successfully',
        data: user,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * GET /api/v1/auth/me
   * Return verified user profile from MongoDB
   */
  async getMe(req, res, next) {
    try {
      const user = await authService.getUserProfile(req.user.uid);
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User profile not found. Please sync first.',
        });
      }
      return res.status(200).json({
        success: true,
        data: {
          ...user.toObject(),
          emailVerified: req.user.email_verified,
        },
      });
    } catch (error) {
      next(error);
    }
  }
}

module.exports = new AuthController();

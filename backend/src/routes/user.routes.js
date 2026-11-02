const express = require('express');
const userController = require('../controllers/user.controller');
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');
const validateRequest = require('../middleware/validateRequest');
const uploadAvatar = require('../middleware/upload.middleware');
const { updateProfileValidator, updatePreferencesValidator } = require('../validators/user.validator');

const router = express.Router();

router.use(verifyFirebaseToken);

router.get('/profile', userController.getProfile);
router.put('/profile', updateProfileValidator, validateRequest, userController.updateProfile);
router.post(
  '/avatar',
  (req, res, next) => {
    uploadAvatar.single('avatar')(req, res, (err) => {
      if (err) {
        return res.status(400).json({
          success: false,
          message: err.message || 'File upload failed',
        });
      }
      next();
    });
  },
  userController.uploadAvatar
);
router.put('/preferences', updatePreferencesValidator, validateRequest, userController.updatePreferences);

module.exports = router;

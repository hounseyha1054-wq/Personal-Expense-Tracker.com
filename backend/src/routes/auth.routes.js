const express = require('express');
const authController = require('../controllers/auth.controller');
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');

const router = express.Router();

router.use(verifyFirebaseToken);

router.post('/sync', authController.sync);
router.get('/me', authController.getMe);

module.exports = router;

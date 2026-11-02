const express = require('express');
const analyticsController = require('../controllers/analytics.controller');
const verifyFirebaseToken = require('../middleware/verifyFirebaseToken');

const router = express.Router();

router.use(verifyFirebaseToken);

router.get('/summary', analyticsController.getSummary);
router.get('/monthly', analyticsController.getMonthly);
router.get('/categories', analyticsController.getCategories);
router.get('/trends', analyticsController.getTrends);

module.exports = router;

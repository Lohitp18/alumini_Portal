const express = require('express');
const router = express.Router();
const {
  getAllReports,
  updateReportStatus,
  getReportStats
} = require('../controllers/reportController');
const { verifyAdmin } = require('../middlewares/adminMiddleware');

// All report routes require admin authentication
router.use(verifyAdmin);

// Get all reports
router.get('/', getAllReports);

// Get report statistics
router.get('/stats', getReportStats);

// Update report status
router.patch('/:reportId/status', updateReportStatus);

module.exports = router;

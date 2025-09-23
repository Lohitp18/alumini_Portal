const express = require('express');
const router = express.Router();
const { getPendingUsers, approveUser, rejectUser } = require('../controllers/adminController');
const { verifyAdmin } = require('../middleware/adminMiddleware');

router.get('/users', verifyAdmin, getPendingUsers);        // Get all pending users
router.patch('/approve/:id', verifyAdmin, approveUser);    // Approve user
router.patch('/reject/:id', verifyAdmin, rejectUser);      // Reject user

module.exports = router;

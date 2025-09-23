const express = require('express');
const router = express.Router();
const { getPendingUsers, getApprovedUsers, approveUser, rejectUser } = require('../controllers/adminController');
const { verifyAdmin } = require('../middlewares/adminMiddleware');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/users', authMiddleware, verifyAdmin, getPendingUsers);        // Get all pending users
router.get('/approved-users', authMiddleware, verifyAdmin, getApprovedUsers); // Get all approved users
router.patch('/approve/:id', authMiddleware, verifyAdmin, approveUser);    // Approve user
router.patch('/reject/:id', authMiddleware, verifyAdmin, rejectUser);      // Reject user

module.exports = router;

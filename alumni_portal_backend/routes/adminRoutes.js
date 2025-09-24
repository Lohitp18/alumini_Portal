const express = require('express');
const router = express.Router();
const { getPendingUsers, getApprovedUsers, approveUser, rejectUser } = require('../controllers/adminController');
const { 
  getPendingEvents, 
  getPendingOpportunities, 
  getPendingPosts,
  updateEventStatus,
  updateOpportunityStatus,
  updatePostStatus,
  getApprovedEvents,
  getApprovedOpportunities,
  getApprovedPosts
} = require('../controllers/contentController');
const { verifyAdmin } = require('../middlewares/adminMiddleware');
const authMiddleware = require('../middlewares/authMiddleware');

// User management routes
router.get('/users', authMiddleware, verifyAdmin, getPendingUsers);        // Get all pending users
router.get('/approved-users', authMiddleware, verifyAdmin, getApprovedUsers); // Get all approved users
router.patch('/approve/:id', authMiddleware, verifyAdmin, approveUser);    // Approve user
router.patch('/reject/:id', authMiddleware, verifyAdmin, rejectUser);      // Reject user

// Content management routes
router.get('/pending-events', authMiddleware, verifyAdmin, getPendingEvents);
router.get('/pending-opportunities', authMiddleware, verifyAdmin, getPendingOpportunities);
router.get('/pending-posts', authMiddleware, verifyAdmin, getPendingPosts);
router.get('/approved-events', authMiddleware, verifyAdmin, getApprovedEvents);
router.get('/approved-opportunities', authMiddleware, verifyAdmin, getApprovedOpportunities);
router.get('/approved-posts', authMiddleware, verifyAdmin, getApprovedPosts);
router.put('/events/:id/status', authMiddleware, verifyAdmin, updateEventStatus);
router.put('/opportunities/:id/status', authMiddleware, verifyAdmin, updateOpportunityStatus);
router.put('/posts/:id/status', authMiddleware, verifyAdmin, updatePostStatus);

module.exports = router;

const express = require("express");
const {
  getApprovedEvents,
  createEvent,
  getApprovedOpportunities,
  createOpportunity,
  getApprovedPosts,
  getApprovedInstitutionPosts,
  createInstitutionPost,
  getPendingEvents,
  getPendingOpportunities,
  getPendingPosts,
  updateEventStatus,
  updateOpportunityStatus,
  updatePostStatus,
  uploadOptionalImage,
} = require("../controllers/contentController");
const authMiddleware = require("../middlewares/authMiddleware");

const router = express.Router();

// Public routes - get approved content
router.get("/events", getApprovedEvents);
router.get("/opportunities", getApprovedOpportunities);
router.get("/posts", authMiddleware, getApprovedPosts); // Require auth for like info
router.get("/institution-posts", getApprovedInstitutionPosts);

// Protected routes - create content (requires auth)
router.post("/events", authMiddleware, uploadOptionalImage, createEvent);
router.post("/opportunities", authMiddleware, uploadOptionalImage, createOpportunity);
router.post("/institution-posts", authMiddleware, uploadOptionalImage, createInstitutionPost);

// Admin routes - manage pending content
router.get("/admin/pending-events", getPendingEvents);
router.get("/admin/pending-opportunities", getPendingOpportunities);
router.get("/admin/pending-posts", getPendingPosts);
router.put("/admin/events/:id/status", updateEventStatus);
router.put("/admin/posts/:id/status", updatePostStatus);
router.put("/admin/opportunities/:id/status", updateOpportunityStatus);

module.exports = router;




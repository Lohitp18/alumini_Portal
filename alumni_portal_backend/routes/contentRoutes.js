const express = require("express");
const {
  getApprovedEvents,
  createEvent,
  getApprovedOpportunities,
  createOpportunity,
  getApprovedPosts,
  getApprovedInstitutionPosts,
  getPendingEvents,
  getPendingOpportunities,
  updateEventStatus,
  updateOpportunityStatus,
  uploadOptionalImage,
} = require("../controllers/contentController");
const authMiddleware = require("../middlewares/authMiddleware");

const router = express.Router();

// Public routes - get approved content
router.get("/events", getApprovedEvents);
router.get("/opportunities", getApprovedOpportunities);
router.get("/posts", getApprovedPosts);
router.get("/institution-posts", getApprovedInstitutionPosts);

// Protected routes - create content (requires auth)
router.post("/events", authMiddleware, uploadOptionalImage, createEvent);
router.post("/opportunities", authMiddleware, uploadOptionalImage, createOpportunity);

// Admin routes - manage pending content
router.get("/admin/pending-events", getPendingEvents);
router.get("/admin/pending-opportunities", getPendingOpportunities);
router.put("/admin/events/:id/status", updateEventStatus);
router.put("/admin/opportunities/:id/status", updateOpportunityStatus);

module.exports = router;




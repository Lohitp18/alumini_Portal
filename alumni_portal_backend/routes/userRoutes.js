const express = require("express");
const { 
  getApprovedAlumni, 
  getProfile, 
  updateProfile, 
  updatePrivacySettings, 
  changePassword 
} = require("../controllers/userController");
const authMiddleware = require("../middlewares/authMiddleware");

const router = express.Router();

// Public routes
router.get("/approved", getApprovedAlumni);

// Protected routes (require authentication)
router.get("/profile", authMiddleware, getProfile);
router.put("/profile", authMiddleware, updateProfile);
router.put("/privacy-settings", authMiddleware, updatePrivacySettings);
router.put("/change-password", authMiddleware, changePassword);

module.exports = router;



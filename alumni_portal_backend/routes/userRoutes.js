const express = require("express");
const { getApprovedAlumni } = require("../controllers/userController");
const authMiddleware = require("../middlewares/authMiddleware");

const router = express.Router();

router.get("/approved", authMiddleware, getApprovedAlumni);

module.exports = router;



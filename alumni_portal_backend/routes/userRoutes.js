const express = require("express");
const { getApprovedAlumni } = require("../controllers/userController");

const router = express.Router();

router.get("/approved", getApprovedAlumni);

module.exports = router;



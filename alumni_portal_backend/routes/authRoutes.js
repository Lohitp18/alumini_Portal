const express = require("express");
const { registerUser, loginUser } = require("../controllers/uthController");
const { resetPasswordByEmail } = require("../controllers/userController");

const router = express.Router();

router.post("/signup", registerUser);
router.post("/signin", loginUser);
router.post("/reset-password", resetPasswordByEmail);

module.exports = router;

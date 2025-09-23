const User = require("../models/User");
const bcrypt = require("bcryptjs");
const generateToken = require("../utils/generateToken");

// ✅ User Registration (Sign Up)
const registerUser = async (req, res) => {
  try {
    const { name, email, phone, dob, institution, course, year, password, favTeacher, socialMedia } = req.body;

    const userExists = await User.findOne({ email });
    if (userExists) return res.status(400).json({ message: "User already exists" });

    const hashedPassword = await bcrypt.hash(password, 10);

    const user = await User.create({
      name, email, phone, dob, institution, course, year,
      password: hashedPassword, favTeacher, socialMedia
    });

    res.status(201).json({
      _id: user._id,
      email: user.email,
      status: user.status,
      token: generateToken(user._id)
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

// ✅ User Login (Sign In)
const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) return res.status(400).json({ message: "Invalid credentials" });

    const isPasswordMatch = await bcrypt.compare(password, user.password);
    if (!isPasswordMatch) return res.status(400).json({ message: "Invalid credentials" });

    // Check if admin approved
    if (user.status !== "approved") {
      return res.status(403).json({ message: "Account not approved yet" });
    }

    res.json({
      _id: user._id,
      email: user.email,
      status: user.status,
      token: generateToken(user._id)
    });
  } catch (error) {
    res.status(500).json({ message: "Server error", error: error.message });
  }
};

module.exports = { registerUser, loginUser };

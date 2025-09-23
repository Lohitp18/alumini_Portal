const jwt = require("jsonwebtoken");
const User = require("../models/User");

const authMiddleware = async (req, res, next) => {
  try {
    console.log("Auth middleware - Headers:", req.headers);
    const token = req.header("Authorization")?.replace("Bearer ", "");
    console.log("Auth middleware - Token:", token);
    
    if (!token) {
      console.log("Auth middleware - No token found");
      return res.status(401).json({ message: "No token, authorization denied" });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || "your-secret-key");
    console.log("Auth middleware - Decoded token:", decoded);
    
    const user = await User.findById(decoded.id).select("-password");
    console.log("Auth middleware - User found:", user);
    
    if (!user) {
      return res.status(401).json({ message: "Token is not valid" });
    }

    req.user = user;
    next();
  } catch (error) {
    console.error("Auth middleware error:", error);
    res.status(401).json({ message: "Token is not valid" });
  }
};

module.exports = authMiddleware;

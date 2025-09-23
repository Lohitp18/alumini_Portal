const authMiddleware = require('./authMiddleware');

exports.verifyAdmin = [
    authMiddleware, // First check if user is authenticated
    (req, res, next) => {
        if (req.user && req.user.isAdmin) {
            next();
        } else {
            res.status(403).json({ message: "Access denied. Admins only." });
        }
    }
];

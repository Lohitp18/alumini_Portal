const User = require('../models/User');

// Get all pending users
exports.getPendingUsers = async (req, res) => {
    try {
        const users = await User.find({ status: 'pending' });
        res.json(users);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Get all approved users
exports.getApprovedUsers = async (req, res) => {
    try {
        const users = await User.find({ status: 'approved' });
        res.json(users);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Approve a user
exports.approveUser = async (req, res) => {
    try {
        const userId = req.params.id;
        const user = await User.findByIdAndUpdate(userId, { status: 'approved' }, { new: true });
        res.json(user);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

// Reject a user
exports.rejectUser = async (req, res) => {
    try {
        const userId = req.params.id;
        const user = await User.findByIdAndUpdate(userId, { status: 'rejected' }, { new: true });
        res.json(user);
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
};

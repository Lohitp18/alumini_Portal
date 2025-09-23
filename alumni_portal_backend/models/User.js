const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    phone: String,
    dob: Date,
    institution: String,
    course: String,
    year: String,
    password: { type: String, required: true },
    favouriteTeacher: String,
    socialMedia: String,
    status: { type: String, default: "pending" }, // pending, approved, rejected
    isAdmin: { type: Boolean, default: false }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);

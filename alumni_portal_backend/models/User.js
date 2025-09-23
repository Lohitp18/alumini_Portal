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
    isAdmin: { type: Boolean, default: false },
    
    // LinkedIn-like profile fields
    profileImage: String,
    coverImage: String,
    headline: String, // Professional headline
    bio: String, // About section
    location: String,
    website: String,
    linkedin: String,
    twitter: String,
    github: String,
    
    // Professional experience
    experience: [{
        title: String,
        company: String,
        location: String,
        startDate: Date,
        endDate: Date,
        current: { type: Boolean, default: false },
        description: String
    }],
    
    // Education
    education: [{
        school: String,
        degree: String,
        fieldOfStudy: String,
        startDate: Date,
        endDate: Date,
        current: { type: Boolean, default: false },
        description: String
    }],
    
    // Skills
    skills: [String],
    
    // Privacy settings
    privacySettings: {
        profileVisibility: { type: String, enum: ['public', 'private'], default: 'public' },
        showEmail: { type: Boolean, default: false },
        showPhone: { type: Boolean, default: false },
        showExperience: { type: Boolean, default: true },
        showEducation: { type: Boolean, default: true },
        showSkills: { type: Boolean, default: true },
        showConnections: { type: Boolean, default: true },
        allowMessages: { type: Boolean, default: true }
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);

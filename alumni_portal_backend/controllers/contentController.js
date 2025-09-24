const Event = require("../models/Event");
const Opportunity = require("../models/Opportunity");
const Post = require("../models/Post");
const InstitutionPost = require("../models/InstitutionPost");
const { createNotification } = require("./notificationController");
const multer = require("multer");
const path = require("path");
const fs = require("fs");

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = "uploads/";
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + "-" + Math.round(Math.random() * 1e9);
    cb(null, file.fieldname + "-" + uniqueSuffix + path.extname(file.originalname));
  },
});

const upload = multer({ 
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith("image/")) {
      cb(null, true);
    } else {
      cb(new Error("Only image files are allowed"), false);
    }
  },
});

// Optional image upload middleware
const uploadOptional = multer({ 
  storage: storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith("image/")) {
      cb(null, true);
    } else {
      cb(new Error("Only image files are allowed"), false);
    }
  },
}).single("image");

const listApproved = async (Model, res, userId = null) => {
  let items;
  
  // For posts, get all posts (approved and pending) for home page
  if (Model.modelName === 'Post') {
    items = await Model.find({})
      .populate('authorId', 'name profileImage headline')
      .sort({ createdAt: -1 })
      .limit(50);
  } else {
    // For other content types, only show approved
    items = await Model.find({ status: "approved" })
      .populate('postedBy', 'name profileImage headline')
      .sort({ createdAt: -1 })
      .limit(50);
  }
  
  // For posts, add like information
  if (Model.modelName === 'Post') {
    items = items.map(post => {
      const postObj = post.toObject();
      postObj.isLiked = userId ? post.likes.includes(userId) : false;
      postObj.likeCount = post.likes.length;
      return postObj;
    });
  }
  
  return res.json(items);
};

module.exports = {
  getApprovedEvents: async (_req, res) => listApproved(Event, res),

  createEvent: async (req, res) => {
    try {
      const { title, description, date, location, status } = req.body;
      if (!title || !description || !date) {
        return res.status(400).json({ message: "title, description, date are required" });
      }
      
      const eventData = {
        title,
        description,
        date,
        location: location || null,
        status: status || "pending",
        postedBy: req.user?.id,
      };

      if (req.file) {
        eventData.imageUrl = `/uploads/${req.file.filename}`;
      }

      const event = await Event.create(eventData);
      return res.status(201).json(event);
    } catch (err) {
      console.error("createEvent error", err);
      return res.status(500).json({ message: "Failed to create event" });
    }
  },

  createOpportunity: async (req, res) => {
    try {
      const { title, description, company, applyLink, type, status } = req.body;
      if (!title || !description) {
        return res.status(400).json({ message: "title and description are required" });
      }

      const opportunityData = {
        title,
        description,
        company: company || null,
        applyLink: applyLink || null,
        type: type || null,
        status: status || "pending",
        postedBy: req.user?.id,
      };

      if (req.file) {
        opportunityData.imageUrl = `/uploads/${req.file.filename}`;
      }

      const opportunity = await Opportunity.create(opportunityData);
      return res.status(201).json(opportunity);
    } catch (err) {
      console.error("createOpportunity error", err);
      return res.status(500).json({ message: "Failed to create opportunity" });
    }
  },

  getApprovedOpportunities: async (_req, res) => listApproved(Opportunity, res),
  getApprovedPosts: async (_req, res) => listApproved(Post, res),
  getApprovedInstitutionPosts: async (_req, res) => listApproved(InstitutionPost, res),
  createInstitutionPost: async (req, res) => {
    try {
      const { institution, title, content, status } = req.body;
      if (!institution || !title || !content) {
        return res.status(400).json({ message: "institution, title, content are required" });
      }
      const data = {
        institution,
        title,
        content,
        status: status || "approved", // admin-created posts can be approved immediately
      };
      if (req.file) data.imageUrl = `/uploads/${req.file.filename}`;
      const post = await InstitutionPost.create(data);
      
      // Create notification for institution post (since it's approved immediately)
      await createNotification(
        'institution_post',
        'New Institution Post',
        `A new post from ${institution}: "${title}"`,
        post._id,
        'InstitutionPost',
        { institution: institution }
      );
      
      return res.status(201).json(post);
    } catch (err) {
      console.error("createInstitutionPost error", err);
      return res.status(500).json({ message: "Failed to create institution post" });
    }
  },

  getPendingEvents: async (_req, res) => {
    try {
      const events = await Event.find({ status: "pending" })
        .populate("postedBy", "name email")
        .sort({ createdAt: -1 });
      return res.json(events);
    } catch (err) {
      console.error("getPendingEvents error", err);
      return res.status(500).json({ message: "Failed to fetch pending events" });
    }
  },

  getPendingOpportunities: async (_req, res) => {
    try {
      const opportunities = await Opportunity.find({ status: "pending" })
        .populate("postedBy", "name email")
        .sort({ createdAt: -1 });
      return res.json(opportunities);
    } catch (err) {
      console.error("getPendingOpportunities error", err);
      return res.status(500).json({ message: "Failed to fetch pending opportunities" });
    }
  },

  getPendingPosts: async (_req, res) => {
    try {
      const posts = await Post.find({ status: "pending" }).sort({ createdAt: -1 });
      return res.json(posts);
    } catch (err) {
      console.error("getPendingPosts error", err);
      return res.status(500).json({ message: "Failed to fetch pending posts" });
    }
  },

  updateEventStatus: async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;
      if (!["approved", "rejected"].includes(status)) {
        return res.status(400).json({ message: "Status must be 'approved' or 'rejected'" });
      }

      const event = await Event.findByIdAndUpdate(
        id,
        { status },
        { new: true }
      ).populate("postedBy", "name email");

      if (!event) return res.status(404).json({ message: "Event not found" });

      // Create notification when event is approved
      if (status === "approved") {
        await createNotification(
          'event',
          'New Event Available',
          `A new event "${event.title}" has been posted`,
          event._id,
          'Event',
          { postedBy: event.postedBy }
        );
      }

      return res.json(event);
    } catch (err) {
      console.error("updateEventStatus error", err);
      return res.status(500).json({ message: "Failed to update event status" });
    }
  },

  updateOpportunityStatus: async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;
      if (!["approved", "rejected"].includes(status)) {
        return res.status(400).json({ message: "Status must be 'approved' or 'rejected'" });
      }

      const opportunity = await Opportunity.findByIdAndUpdate(
        id,
        { status },
        { new: true }
      ).populate("postedBy", "name email");

      if (!opportunity) return res.status(404).json({ message: "Opportunity not found" });

      // Create notification when opportunity is approved
      if (status === "approved") {
        await createNotification(
          'opportunity',
          'New Opportunity Available',
          `A new opportunity "${opportunity.title}" has been posted`,
          opportunity._id,
          'Opportunity',
          { postedBy: opportunity.postedBy }
        );
      }

      return res.json(opportunity);
    } catch (err) {
      console.error("updateOpportunityStatus error", err);
      return res.status(500).json({ message: "Failed to update opportunity status" });
    }
  },

  updatePostStatus: async (req, res) => {
    try {
      const { id } = req.params;
      const { status } = req.body;
      if (!["approved", "rejected"].includes(status)) {
        return res.status(400).json({ message: "Status must be 'approved' or 'rejected'" });
      }

      const post = await Post.findByIdAndUpdate(id, { status }, { new: true });

      if (!post) return res.status(404).json({ message: "Post not found" });

      // Create notification when post is approved
      if (status === "approved") {
        await createNotification(
          'post',
          'New Post Available',
          `A new post "${post.title}" has been posted`,
          post._id,
          'Post',
          { postedBy: post.authorId }
        );
      }

      return res.json(post);
    } catch (err) {
      console.error("updatePostStatus error", err);
      return res.status(500).json({ message: "Failed to update post status" });
    }
  },

  // Middleware for optional image upload
  uploadOptionalImage: (req, res, next) => {
    uploadOptional(req, res, (err) => {
      if (err instanceof multer.MulterError) {
        if (err.code === "LIMIT_FILE_SIZE") {
          return res.status(400).json({ message: "File too large. Maximum size is 5MB." });
        }
        return res.status(400).json({ message: err.message });
      } else if (err) {
        return res.status(400).json({ message: err.message });
      }
      next();
    });
  },

  upload, // Export multer middleware
};

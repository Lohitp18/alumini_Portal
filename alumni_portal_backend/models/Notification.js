const mongoose = require("mongoose");

const notificationSchema = new mongoose.Schema(
  {
    userId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User', 
      required: true 
    },
    type: { 
      type: String, 
      enum: ['post', 'event', 'opportunity', 'institution_post'], 
      required: true 
    },
    title: { type: String, required: true },
    message: { type: String, required: true },
    relatedItemId: { 
      type: mongoose.Schema.Types.ObjectId, 
      required: true 
    },
    relatedItemType: { 
      type: String, 
      enum: ['Post', 'Event', 'Opportunity', 'InstitutionPost'], 
      required: true 
    },
    isRead: { type: Boolean, default: false },
    metadata: { 
      type: mongoose.Schema.Types.Mixed,
      default: {}
    }
  },
  { timestamps: true }
);

// Index for efficient queries
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });

module.exports = mongoose.model("Notification", notificationSchema);

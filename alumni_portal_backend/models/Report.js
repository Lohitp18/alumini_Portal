const mongoose = require("mongoose");

const reportSchema = new mongoose.Schema(
  {
    reporterId: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User', 
      required: true 
    },
    reportedItemId: { 
      type: mongoose.Schema.Types.ObjectId, 
      required: true 
    },
    reportedItemType: { 
      type: String, 
      enum: ['Post', 'Event', 'Opportunity', 'InstitutionPost'], 
      required: true 
    },
    reason: { 
      type: String, 
      enum: [
        'spam', 
        'inappropriate_content', 
        'harassment', 
        'false_information', 
        'copyright_violation', 
        'other'
      ], 
      required: true 
    },
    description: { type: String },
    status: { 
      type: String, 
      enum: ['pending', 'reviewed', 'resolved', 'dismissed'], 
      default: 'pending' 
    },
    adminNotes: { type: String },
    reviewedBy: { 
      type: mongoose.Schema.Types.ObjectId, 
      ref: 'User' 
    },
    reviewedAt: { type: Date }
  },
  { timestamps: true }
);

// Index for efficient queries
reportSchema.index({ reporterId: 1 });
reportSchema.index({ reportedItemId: 1, reportedItemType: 1 });
reportSchema.index({ status: 1 });
reportSchema.index({ createdAt: -1 });

module.exports = mongoose.model("Report", reportSchema);

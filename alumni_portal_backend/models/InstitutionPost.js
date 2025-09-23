const mongoose = require("mongoose");

const institutionPostSchema = new mongoose.Schema(
  {
    institution: { type: String, required: true },
    title: { type: String, required: true },
    content: { type: String, required: true },
    imageUrl: { type: String },
    status: { type: String, enum: ["pending", "approved", "rejected"], default: "pending" },
  },
  { timestamps: true }
);

module.exports = mongoose.model("InstitutionPost", institutionPostSchema);




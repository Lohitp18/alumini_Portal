const User = require("../models/User");
const Connection = require("../models/Connection");

// GET /api/users/approved?year=&institution=&course=&q=
exports.getApprovedAlumni = async (req, res) => {
  try {
    const { year, institution, course, q } = req.query;
    const currentUserId = req.user?._id;
    
    const filter = { status: "approved" };

    if (year) filter.year = year;
    if (institution) filter.institution = { $regex: institution, $options: "i" };
    if (course) filter.course = { $regex: course, $options: "i" };

    // Text search on name or email if q provided
    if (q) {
      filter.$or = [
        { name: { $regex: q, $options: "i" } },
        { email: { $regex: q, $options: "i" } },
      ];
    }

    // Exclude current user
    if (currentUserId) {
      filter._id = { $ne: currentUserId };
    }

    let users = await User.find(filter)
      .select("name email phone institution course year createdAt")
      .sort({ createdAt: -1 })
      .limit(200);

    // If user is authenticated, exclude already connected alumni
    if (currentUserId) {
      const connections = await Connection.find({
        $or: [
          { requester: currentUserId },
          { recipient: currentUserId }
        ]
      });

      const connectedUserIds = new Set();
      connections.forEach(conn => {
        if (conn.requester.toString() !== currentUserId.toString()) {
          connectedUserIds.add(conn.requester.toString());
        }
        if (conn.recipient.toString() !== currentUserId.toString()) {
          connectedUserIds.add(conn.recipient.toString());
        }
      });

      // Filter out connected users
      users = users.filter(user => !connectedUserIds.has(user._id.toString()));
    }

    return res.json(users);
  } catch (err) {
    console.error("getApprovedAlumni error", err);
    return res.status(500).json({ message: "Failed to fetch alumni" });
  }
};



const User = require("../models/User");

// GET /api/users/approved?year=&institution=&course=&q=
exports.getApprovedAlumni = async (req, res) => {
  try {
    const { year, institution, course, q } = req.query;
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

    const users = await User.find(filter)
      .select("name email phone institution course year createdAt")
      .sort({ createdAt: -1 })
      .limit(200);

    return res.json(users);
  } catch (err) {
    console.error("getApprovedAlumni error", err);
    return res.status(500).json({ message: "Failed to fetch alumni" });
  }
};



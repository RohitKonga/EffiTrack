const mongoose = require('mongoose');

const AnnouncementSchema = new mongoose.Schema({
  title: { type: String, required: true },
  message: { type: String, required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  targetRoles: [{ type: String, enum: ['Admin', 'Manager', 'Employee'] }],
  targetDepartment: { type: String }, // For department-specific announcements
  isGlobal: { type: Boolean, default: false }, // true for admin announcements, false for department-specific
}, { timestamps: true });

module.exports = mongoose.model('Announcement', AnnouncementSchema); 
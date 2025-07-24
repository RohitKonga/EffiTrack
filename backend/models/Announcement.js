const mongoose = require('mongoose');

const AnnouncementSchema = new mongoose.Schema({
  title: { type: String, required: true },
  message: { type: String, required: true },
  createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  targetRoles: [{ type: String, enum: ['Employee', 'Manager', 'Admin'] }],
}, { timestamps: true });

module.exports = mongoose.model('Announcement', AnnouncementSchema); 
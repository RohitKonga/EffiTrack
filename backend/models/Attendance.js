const mongoose = require('mongoose');

const AttendanceSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  checkIn: { type: Date, required: true },
  checkOut: { type: Date },
  workingHours: { type: Number },
  // Add timezone information
  checkInTimezone: { type: String },
  checkOutTimezone: { type: String },
}, { timestamps: true });

module.exports = mongoose.model('Attendance', AttendanceSchema); 
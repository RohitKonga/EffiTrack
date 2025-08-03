const mongoose = require('mongoose');

const AttendanceSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  checkIn: { type: String, required: true }, // Store as string to preserve device time
  checkOut: { type: String }, // Store as string to preserve device time
  workingHours: { type: Number },
}, { timestamps: false }); // Disable timestamps to prevent server time interference

module.exports = mongoose.model('Attendance', AttendanceSchema); 
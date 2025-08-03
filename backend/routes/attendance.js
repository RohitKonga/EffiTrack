const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { checkIn, checkOut, getHistory, getAttendanceReports, getTeamAttendance, testNewCode } = require('../controllers/attendanceController');
const User = require('../models/User');
const Attendance = require('../models/Attendance'); // Added missing import for Attendance

// Simple test endpoint
router.get('/test', (req, res) => {
  res.json({ message: 'Attendance routes are working!', timestamp: new Date().toISOString() });
});

router.post('/checkin', auth, checkIn);
router.post('/checkout', auth, checkOut);
router.get('/history', auth, getHistory);
router.get('/reports', auth, getAttendanceReports);
router.get('/team/:department', auth, getTeamAttendance);
router.post('/test-new-code', testNewCode);

// Debug endpoint to check database status (no auth required for testing)
router.get('/debug', async (req, res) => {
  try {
    const userCount = await User.countDocuments();
    const users = await User.find().select('name role department');
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    const todayAttendance = await Attendance.find({
      checkIn: { $gte: today, $lt: tomorrow }
    }).populate('user', 'name department role');
    
    res.json({
      totalUsers: userCount,
      users: users,
      todayAttendance: todayAttendance.length,
      attendanceRecords: todayAttendance,
      message: 'Database status check'
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router; 
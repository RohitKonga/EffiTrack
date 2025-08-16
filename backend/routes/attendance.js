const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { checkIn, checkOut, getHistory, getAttendanceReports, getTeamAttendance } = require('../controllers/attendanceController');
const User = require('../models/User');
const Attendance = require('../models/Attendance'); // Added missing import for Attendance

router.post('/checkin', auth, checkIn);
router.post('/checkout', auth, checkOut);
router.get('/history', auth, getHistory);
router.get('/reports', auth, getAttendanceReports);
router.get('/team/:department', auth, getTeamAttendance);

module.exports = router; 
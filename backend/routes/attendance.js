const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { checkIn, checkOut, getHistory, getAttendanceReports } = require('../controllers/attendanceController');

router.post('/checkin', auth, checkIn);
router.post('/checkout', auth, checkOut);
router.get('/history', auth, getHistory);
router.get('/reports', auth, getAttendanceReports);

module.exports = router; 
const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { requestLeave, getMyLeaves, getAllLeaves, updateLeaveStatus } = require('../controllers/leaveController');

// Request leave (Employee)
router.post('/request', auth, requestLeave);
// List leaves for logged-in user (Employee)
router.get('/my', auth, getMyLeaves);
// List all leave requests (Manager/Admin)
router.get('/all', auth, getAllLeaves);
// Approve or reject leave (Manager/Admin)
router.put('/:id/status', auth, updateLeaveStatus);

module.exports = router; 
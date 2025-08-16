const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { requestLeave, getMyLeaves, getAllLeaves, updateLeaveStatus, getLeavesByDepartment } = require('../controllers/leaveController');

// Request leave (Employee)
router.post('/request', auth, requestLeave);
// List leaves for logged-in user (Employee)
router.get('/my', auth, getMyLeaves);
// List all leave requests (Manager/Admin)
router.get('/all', auth, getAllLeaves);
// List leaves by department (Manager)
router.get('/department/:department', auth, getLeavesByDepartment);
// Approve or reject leave (Manager/Admin)
router.put('/:id/status', auth, updateLeaveStatus);

module.exports = router; 
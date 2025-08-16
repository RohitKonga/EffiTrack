const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { requestLeave, getMyLeaves, getAllLeaves, updateLeaveStatus, getLeavesByDepartment } = require('../controllers/leaveController');

// Test endpoint (no auth required for debugging)
router.get('/test', (req, res) => {
  res.json({ 
    message: 'Leave routes are working!', 
    timestamp: new Date().toISOString(),
    endpoints: [
      'POST /request - Request leave',
      'GET /my - Get my leaves',
      'GET /all - Get all leaves',
      'GET /department/:department - Get leaves by department',
      'PUT /:id/status - Update leave status'
    ]
  });
});

// Debug endpoint to check database status (no auth required for testing)
router.get('/debug', async (req, res) => {
  try {
    const Leave = require('../models/Leave');
    const User = require('../models/User');
    
    const leaveCount = await Leave.countDocuments();
    const userCount = await User.countDocuments();
    const users = await User.find().select('name email department role');
    const leaves = await Leave.find().populate('user', 'name email department role');
    
    res.json({
      totalLeaves: leaveCount,
      totalUsers: userCount,
      users: users,
      leaves: leaves,
      message: 'Database status check for leaves'
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

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
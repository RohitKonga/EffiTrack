const express = require('express');
const router = express.Router();

// Add error handling for middleware and controller imports
let auth, leaveController;
try {
  auth = require('../middleware/auth');
  console.log('Auth middleware loaded successfully');
} catch (error) {
  console.error('Error loading auth middleware:', error);
}

try {
  leaveController = require('../controllers/leaveController');
  console.log('Leave controller loaded successfully');
  console.log('Available methods:', Object.keys(leaveController));
} catch (error) {
  console.error('Error loading leave controller:', error);
}

// Super simple test route
router.get('/', (req, res) => {
  res.json({ message: 'Leave router is working!' });
});

// Basic test endpoint
router.get('/ping', (req, res) => {
  res.json({ message: 'Leave routes are working!', timestamp: new Date().toISOString() });
});

// Test endpoint
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

// Request leave (Employee)
if (leaveController && leaveController.requestLeave) {
  router.post('/request', auth, leaveController.requestLeave);
}
// List leaves for logged-in user (Employee)
if (leaveController && leaveController.getMyLeaves) {
  router.get('/my', auth, leaveController.getMyLeaves);
}
// List all leave requests (Manager/Admin)
if (leaveController && leaveController.getAllLeaves) {
  router.get('/all', auth, leaveController.getAllLeaves);
}
// List leaves by department (Manager)
if (leaveController && leaveController.getLeavesByDepartment) {
  router.get('/department/:department', auth, leaveController.getLeavesByDepartment);
}
// Approve or reject leave (Manager/Admin)
if (leaveController && leaveController.updateLeaveStatus) {
  router.put('/:id/status', auth, leaveController.updateLeaveStatus);
}

module.exports = router; 
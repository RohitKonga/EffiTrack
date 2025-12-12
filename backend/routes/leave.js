const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { requestLeave, getMyLeaves, getAllLeaves, updateLeaveStatus, getLeavesByDepartment } = require('../controllers/leaveController');

router.post('/request', auth, requestLeave);
router.get('/my', auth, getMyLeaves);
router.get('/all', auth, getAllLeaves);
router.get('/department/:department', auth, getLeavesByDepartment);
router.put('/:id/status', auth, updateLeaveStatus);

module.exports = router; 
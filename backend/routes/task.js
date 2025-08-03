const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { assignTask, getMyTasks, updateStatus, getAllTasks } = require('../controllers/taskController');

// Assign a task (Manager)
router.post('/assign', auth, assignTask);
// List tasks for logged-in user (Employee)
router.get('/my', auth, getMyTasks);
// Update task status (Employee)
router.put('/:id/status', auth, updateStatus);
// List all tasks (Manager/Admin)
router.get('/all', auth, getAllTasks);

module.exports = router; 
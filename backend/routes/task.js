const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');

const { assignTask, getMyTasks, updateStatus, getAllTasks, getTasksByDepartment } = require('../controllers/taskController');

// Assign a task (Manager) 
router.post('/create', auth, assignTask);
router.post('/assign', auth, assignTask);
// List tasks for logged-in user 
router.get('/my', auth, getMyTasks);
// Update task status
router.put('/:id/status', auth, updateStatus);
// List all tasks
router.get('/all', auth, getAllTasks);
// List tasks by department 
router.get('/department/:department', auth, getTasksByDepartment);

module.exports = router; 
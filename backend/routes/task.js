const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { assignTask, getMyTasks, updateStatus, getAllTasks, getTasksByDepartment } = require('../controllers/taskController');

// Assign a task (Manager) - both routes for compatibility
router.post('/', auth, assignTask);
router.post('/assign', auth, assignTask);
// List tasks for logged-in user (Employee)
router.get('/my', auth, getMyTasks);
// Update task status (Employee)
router.put('/:id/status', auth, updateStatus);
// List all tasks (Manager/Admin)
router.get('/all', auth, getAllTasks);
// List tasks by department (Manager)
router.get('/department/:department', auth, getTasksByDepartment);

module.exports = router; 
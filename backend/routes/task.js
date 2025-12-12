const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');

const { assignTask, getMyTasks, updateStatus, getAllTasks, getTasksByDepartment } = require('../controllers/taskController');

router.post('/create', auth, assignTask);
router.post('/assign', auth, assignTask);
router.get('/my', auth, getMyTasks);
router.put('/:id/status', auth, updateStatus);
router.get('/all', auth, getAllTasks);
router.get('/department/:department', auth, getTasksByDepartment);

module.exports = router; 
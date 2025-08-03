const Task = require('../models/Task');
const User = require('../models/User');

// Assign a new task (Manager)
exports.assignTask = async (req, res) => {
  try {
    const { title, description, deadline, assignedTo } = req.body;
    const assignedBy = req.user.id;
    const user = await User.findById(assignedTo);
    if (!user) return res.status(404).json({ msg: 'Assigned user not found' });
    const task = new Task({ title, description, deadline, assignedTo, assignedBy });
    await task.save();
    res.json(task);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// List tasks for the logged-in user (Employee)
exports.getMyTasks = async (req, res) => {
  try {
    const tasks = await Task.find({ assignedTo: req.user.id }).sort({ deadline: 1 });
    res.json(tasks);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// Update task status (Employee)
exports.updateStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const task = await Task.findOne({ _id: req.params.id, assignedTo: req.user.id });
    if (!task) return res.status(404).json({ msg: 'Task not found' });
    task.status = status;
    await task.save();
    res.json(task);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// List all tasks (Manager/Admin)
exports.getAllTasks = async (req, res) => {
  try {
    const tasks = await Task.find().populate('assignedTo', 'name email').sort({ deadline: 1 });
    res.json(tasks);
  } catch (err) {
    res.status(500).send('Server error');
  }
}; 
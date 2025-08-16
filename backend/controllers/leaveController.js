const Leave = require('../models/Leave');
const User = require('../models/User');

// Debug: Log when controller is loaded
console.log('LeaveController loaded successfully');
console.log('Available methods:', Object.keys(exports));

// Request leave (Employee)
exports.requestLeave = async (req, res) => {
  try {
    const { type, startDate, endDate, reason } = req.body;
    const leave = new Leave({
      user: req.user.id,
      type,
      startDate,
      endDate,
      reason,
    });
    await leave.save();
    res.json(leave);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// List leaves for the logged-in user (Employee)
exports.getMyLeaves = async (req, res) => {
  try {
    const leaves = await Leave.find({ user: req.user.id }).sort({ startDate: -1 });
    res.json(leaves);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// List all leave requests (Manager/Admin)
exports.getAllLeaves = async (req, res) => {
  try {
    const leaves = await Leave.find().populate('user', 'name email').sort({ startDate: -1 });
    res.json(leaves);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// Approve or reject leave (Manager/Admin)
exports.updateLeaveStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const leave = await Leave.findById(req.params.id);
    if (!leave) return res.status(404).json({ msg: 'Leave request not found' });
    leave.status = status;
    leave.approver = req.user.id;
    await leave.save();
    res.json(leave);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// Get leaves by department (for managers)
exports.getLeavesByDepartment = async (req, res) => {
  try {
    const { department } = req.params;
    console.log('Fetching leaves for department:', department);
    
    // First get all users in the department (case-insensitive)
    const users = await User.find({ 
      department: { $regex: new RegExp(department, 'i') } 
    }).select('_id');
    console.log('Users found in department:', users.length);
    
    const userIds = users.map(user => user._id);
    console.log('User IDs:', userIds);
    
    // Then get all leaves requested by these users
    const leaves = await Leave.find({ user: { $in: userIds } })
      .populate('user', 'name email department')
      .sort({ startDate: -1 });
    
    console.log('Leaves found for department:', leaves.length);
    console.log('Leaves:', leaves);
    
    res.json(leaves);
  } catch (err) {
    console.error('Error fetching leaves by department:', err);
    res.status(500).send('Server error');
  }
}; 
const Leave = require('../models/Leave');
const User = require('../models/User');

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
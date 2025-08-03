const User = require('../models/User');
const Task = require('../models/Task');
const Attendance = require('../models/Attendance');
const Leave = require('../models/Leave');

exports.getStats = async (req, res) => {
  try {
    const numEmployees = await User.countDocuments({ role: 'Employee' });
    const totalTasks = await Task.countDocuments();
    const completedTasks = await Task.countDocuments({ status: 'Completed' });
    const totalAttendance = await Attendance.countDocuments();
    const presentAttendance = await Attendance.countDocuments({ workingHours: { $gt: 0 } });
    const attendancePercent = totalAttendance > 0 ? ((presentAttendance / totalAttendance) * 100).toFixed(2) : 0;
    const leavesRequested = await Leave.countDocuments();
    const leavesApproved = await Leave.countDocuments({ status: 'Approved' });

    res.json({
      numEmployees,
      totalTasks,
      completedTasks,
      attendancePercent,
      leavesRequested,
      leavesApproved
    });
  } catch (err) {
    res.status(500).send('Server error');
  }
}; 
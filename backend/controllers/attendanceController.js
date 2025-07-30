const Attendance = require('../models/Attendance');
const User = require('../models/User');

exports.checkIn = async (req, res) => {
  try {
    // Prevent multiple check-ins without check-out
    const openAttendance = await Attendance.findOne({ user: req.user.id, checkOut: null });
    if (openAttendance) {
      return res.status(400).json({ msg: 'Already checked in. Please check out first.' });
    }
    const attendance = new Attendance({
      user: req.user.id,
      checkIn: new Date(),
    });
    await attendance.save();
    res.json(attendance);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

exports.checkOut = async (req, res) => {
  try {
    const attendance = await Attendance.findOne({ user: req.user.id, checkOut: null });
    if (!attendance) {
      return res.status(400).json({ msg: 'No active check-in found.' });
    }
    attendance.checkOut = new Date();
    attendance.workingHours = (attendance.checkOut - attendance.checkIn) / (1000 * 60 * 60); // hours
    await attendance.save();
    res.json(attendance);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

exports.getHistory = async (req, res) => {
  try {
    const history = await Attendance.find({ user: req.user.id }).sort({ checkIn: -1 });
    res.json(history);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// Get attendance reports (admin only)
exports.getAttendanceReports = async (req, res) => {
  try {
    // Get all users with their departments
    const users = await User.find().select('name department role');
    
    // Get today's date
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    // Get today's attendance records
    const todayAttendance = await Attendance.find({
      checkIn: { $gte: today, $lt: tomorrow }
    }).populate('user', 'name department role');
    
    // Group by department
    const departmentStats = {};
    const totalStats = { present: 0, absent: 0, total: users.length };
    
    // Initialize department stats
    users.forEach(user => {
      if (user.department) {
        if (!departmentStats[user.department]) {
          departmentStats[user.department] = { present: 0, absent: 0, total: 0 };
        }
        departmentStats[user.department].total++;
      }
    });
    
    // Count present users
    todayAttendance.forEach(attendance => {
      if (attendance.user && attendance.user.department) {
        if (!departmentStats[attendance.user.department]) {
          departmentStats[attendance.user.department] = { present: 0, absent: 0, total: 0 };
        }
        departmentStats[attendance.user.department].present++;
        totalStats.present++;
      }
    });
    
    // Calculate absent users
    Object.keys(departmentStats).forEach(dept => {
      departmentStats[dept].absent = departmentStats[dept].total - departmentStats[dept].present;
    });
    totalStats.absent = totalStats.total - totalStats.present;
    
    // Convert to array format
    const reports = Object.keys(departmentStats).map(dept => ({
      department: dept,
      present: departmentStats[dept].present.toString(),
      absent: departmentStats[dept].absent.toString(),
      total: departmentStats[dept].total.toString(),
      percentage: departmentStats[dept].total > 0 
        ? ((departmentStats[dept].present / departmentStats[dept].total) * 100).toFixed(1)
        : '0.0'
    }));
    
    res.json({
      reports,
      totalStats: {
        present: totalStats.present.toString(),
        absent: totalStats.absent.toString(),
        total: totalStats.total.toString(),
        percentage: totalStats.total > 0 
          ? ((totalStats.present / totalStats.total) * 100).toFixed(1)
          : '0.0'
      },
      date: today.toISOString().split('T')[0]
    });
  } catch (err) {
    console.error('Attendance reports error:', err);
    res.status(500).send('Server error');
  }
}; 
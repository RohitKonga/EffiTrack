const Attendance = require('../models/Attendance');
const User = require('../models/User');

exports.checkIn = async (req, res) => {
  try {
    // Check if user is admin (admins don't need to check in)
    const user = await User.findById(req.user.id);
    if (user.role === 'Admin') {
      return res.status(400).json({ msg: 'Admins do not need to check in/out.' });
    }
    
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
    // Check if user is admin (admins don't need to check out)
    const user = await User.findById(req.user.id);
    if (user.role === 'Admin') {
      return res.status(400).json({ msg: 'Admins do not need to check in/out.' });
    }
    
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
    // Get all users with their departments (excluding admins)
    const users = await User.find({ role: { $ne: 'Admin' } }).select('name department role');
    console.log('Users found (excluding admins):', users.map(u => ({ name: u.name, role: u.role, department: u.department })));
    
    // Double-check: filter out any admin users that might have slipped through
    const nonAdminUsers = users.filter(user => user.role !== 'Admin');
    console.log('Users after double-check (excluding admins):', nonAdminUsers.map(u => ({ name: u.name, role: u.role, department: u.department })));
    
    // Get today's date
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    
    // Get today's attendance records
    const todayAttendance = await Attendance.find({
      checkIn: { $gte: today, $lt: tomorrow }
    }).populate('user', 'name department role');
    
    console.log('Today\'s attendance records:', todayAttendance.map(a => ({ 
      userName: a.user?.name, 
      userRole: a.user?.role, 
      department: a.user?.department 
    })));
    
    // Group by department
    const departmentStats = {};
    const totalStats = { present: 0, absent: 0, total: nonAdminUsers.length };
    
    // Initialize department stats (only for non-admin users)
    nonAdminUsers.forEach(user => {
      if (user.department) {
        if (!departmentStats[user.department]) {
          departmentStats[user.department] = { present: 0, absent: 0, total: 0 };
        }
        departmentStats[user.department].total++;
      }
    });
    
    console.log('Department stats after initialization:', departmentStats);
    
    // Count present users (employees and managers, excluding admins)
    todayAttendance.forEach(attendance => {
      // Extra safety check: ensure user exists and is not admin
      if (attendance.user && 
          attendance.user.department && 
          attendance.user.role !== 'Admin' && 
          attendance.user.role !== 'admin') { // Check both cases
        
        if (!departmentStats[attendance.user.department]) {
          departmentStats[attendance.user.department] = { present: 0, absent: 0, total: 0 };
        }
        departmentStats[attendance.user.department].present++;
        totalStats.present++;
        console.log(`Marking ${attendance.user.name} (${attendance.user.role}) as present in ${attendance.user.department}`);
      } else {
        console.log(`Skipping ${attendance.user?.name} (${attendance.user?.role}) - not eligible for attendance`);
      }
    });
    
    // Calculate absent users
    Object.keys(departmentStats).forEach(dept => {
      departmentStats[dept].absent = departmentStats[dept].total - departmentStats[dept].present;
    });
    totalStats.absent = totalStats.total - totalStats.present;
    
    console.log('Final department stats:', departmentStats);
    console.log('Final total stats:', totalStats);
    
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
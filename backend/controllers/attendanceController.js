const Attendance = require('../models/Attendance');
const User = require('../models/User');

exports.checkIn = async (req, res) => {
  try {
    const openAttendance = await Attendance.findOne({ user: req.user.id, checkOut: null });
    if (openAttendance) {
      return res.status(400).json({ msg: 'Already checked in. Please check out first.' });
    }

    if (!req.body.checkIn) {
      return res.status(400).json({ msg: 'Device time is required for check-in' });
    }

    const deviceTime = new Date(req.body.checkIn);
    
    const now = new Date();
    const timeDiff = Math.abs(now - deviceTime);
    const maxDiff = 24 * 60 * 60 * 1000; 
    
    if (timeDiff > maxDiff) {
      return res.status(400).json({ msg: 'Device time seems incorrect. Please check your device clock.' });
    }

    const today = new Date(deviceTime);
    today.setHours(0, 0, 0, 0);
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    const todayAttendance = await Attendance.findOne({
      user: req.user.id,
      checkIn: { $gte: today, $lt: tomorrow }
    });

    if (todayAttendance) {
      return res.status(400).json({ 
        msg: 'You have already checked in today. Only one check-in per day is allowed.' 
      });
    }

    const attendance = new Attendance({
      user: req.user.id,
      checkIn: deviceTime,
      checkInTimezone: req.body.timezone || 'UTC',
    });

    await attendance.save();
    res.json(attendance);
  } catch (err) {
    console.error(err);
    res.status(500).send('Server error');
  }
};

exports.checkOut = async (req, res) => {
  try {
    const attendance = await Attendance.findOne({ user: req.user.id, checkOut: null });
    if (!attendance) {
      return res.status(400).json({ msg: 'No active check-in found.' });
    }

    if (!req.body.checkOut) {
      return res.status(400).json({ msg: 'Device time is required for check-out' });
    }

    const deviceTime = new Date(req.body.checkOut);
    
    const now = new Date();
    const timeDiff = Math.abs(now - deviceTime);
    const maxDiff = 24 * 60 * 60 * 1000; 
    
    if (timeDiff > maxDiff) {
      return res.status(400).json({ msg: 'Device time seems incorrect. Please check your device clock.' });
    }

    if (deviceTime <= attendance.checkIn) {
      return res.status(400).json({ msg: 'Check-out time must be after check-in time' });
    }

    attendance.checkOut = deviceTime;
    attendance.checkOutTimezone = req.body.timezone || 'UTC';
    attendance.workingHours = (attendance.checkOut - attendance.checkIn) / (1000 * 60 * 60);
    
    await attendance.save();

    const workingHours = attendance.workingHours;
    let message = 'Check-out successful!';
    let additionalInfo = '';

    if (workingHours >= 8) {
      additionalInfo = 'Great job! You have completed a full working day.';
    } else if (workingHours >= 6) {
      additionalInfo = 'Good work! You have put in substantial hours today.';
    } else if (workingHours >= 4) {
      additionalInfo = 'You have completed a half-day of work.';
    } else {
      additionalInfo = 'Short working session completed.';
    }

    res.json({
      ...attendance.toObject(),
      message: message,
      additionalInfo: additionalInfo,
      workingHoursFormatted: `${Math.floor(workingHours)}h ${Math.round((workingHours % 1) * 60)}m`
    });
  } catch (err) {
    console.error(err);
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

exports.getAttendanceReports = async (req, res) => {
  try {
    let targetDate;
    if (req.query.date) {
      targetDate = new Date(req.query.date);
      targetDate.setHours(0, 0, 0, 0);
    } else {
      targetDate = new Date();
      targetDate.setHours(0, 0, 0, 0);
    }
    
    const nextDay = new Date(targetDate);
    nextDay.setDate(nextDay.getDate() + 1);
    
    const users = await User.find().select('name department role');
    
    const attendanceRecords = await Attendance.find({
      checkIn: { $gte: targetDate, $lt: nextDay }
    }).populate('user', 'name department role');
    
    const employees = users.filter(user => user.role === 'Employee');
    const managers = users.filter(user => user.role === 'Manager');
    
    const employeeDepartmentStats = {};
    const employeeTotalStats = { present: 0, absent: 0, total: employees.length };
    
    const managerDepartmentStats = {};
    const managerTotalStats = { present: 0, absent: 0, total: managers.length };
    
    employees.forEach(user => {
      if (user.department) {
        if (!employeeDepartmentStats[user.department]) {
          employeeDepartmentStats[user.department] = { present: 0, absent: 0, total: 0 };
        }
        employeeDepartmentStats[user.department].total++;
      }
    });
    
    managers.forEach(user => {
      if (user.department) {
        if (!managerDepartmentStats[user.department]) {
          managerDepartmentStats[user.department] = { present: 0, absent: 0, total: 0 };
        }
        managerDepartmentStats[user.department].total++;
      }
    });
    
    attendanceRecords.forEach(attendance => {
      if (attendance.user && attendance.user.department) {
        if (attendance.user.role === 'Employee') {
          if (!employeeDepartmentStats[attendance.user.department]) {
            employeeDepartmentStats[attendance.user.department] = { present: 0, absent: 0, total: 0 };
          }
          employeeDepartmentStats[attendance.user.department].present++;
          employeeTotalStats.present++;
        } else if (attendance.user.role === 'Manager') {
          if (!managerDepartmentStats[attendance.user.department]) {
            managerDepartmentStats[attendance.user.department] = { present: 0, absent: 0, total: 0 };
          }
          managerDepartmentStats[attendance.user.department].present++;
          managerTotalStats.present++;
        }
      }
    });
    
    Object.keys(employeeDepartmentStats).forEach(dept => {
      employeeDepartmentStats[dept].absent = employeeDepartmentStats[dept].total - employeeDepartmentStats[dept].present;
    });
    employeeTotalStats.absent = employeeTotalStats.total - employeeTotalStats.present;
    
    Object.keys(managerDepartmentStats).forEach(dept => {
      managerDepartmentStats[dept].absent = managerDepartmentStats[dept].total - managerDepartmentStats[dept].present;
    });
    managerTotalStats.absent = managerTotalStats.total - managerTotalStats.present;
    
    const employeeReports = Object.keys(employeeDepartmentStats).map(dept => ({
      department: dept,
      present: employeeDepartmentStats[dept].present.toString(),
      absent: employeeDepartmentStats[dept].absent.toString(),
      total: employeeDepartmentStats[dept].total.toString(),
      percentage: employeeDepartmentStats[dept].total > 0 
        ? ((employeeDepartmentStats[dept].present / employeeDepartmentStats[dept].total) * 100).toFixed(1)
        : '0.0'
    }));
    
    const managerReports = Object.keys(managerDepartmentStats).map(dept => ({
      department: dept,
      present: managerDepartmentStats[dept].present.toString(),
      absent: managerDepartmentStats[dept].absent.toString(),
      total: managerDepartmentStats[dept].total.toString(),
      percentage: managerDepartmentStats[dept].total > 0 
        ? ((managerDepartmentStats[dept].present / managerDepartmentStats[dept].total) * 100).toFixed(1)
        : '0.0'
    }));
    
    const response = {
      employeeReports,
      managerReports,
      employeeTotalStats: {
        present: employeeTotalStats.present.toString(),
        absent: employeeTotalStats.absent.toString(),
        total: employeeTotalStats.total.toString(),
        percentage: employeeTotalStats.total > 0 
          ? ((employeeTotalStats.present / employeeTotalStats.total) * 100).toFixed(1)
          : '0.0'
      },
      managerTotalStats: {
        present: managerTotalStats.present.toString(),
        absent: managerTotalStats.absent.toString(),
        total: managerTotalStats.total.toString(),
        percentage: managerTotalStats.total > 0 
          ? ((managerTotalStats.present / managerTotalStats.total) * 100).toFixed(1)
          : '0.0'
      },
      date: targetDate.toISOString().split('T')[0],
      selectedDate: targetDate.toISOString().split('T')[0],
      hasData: attendanceRecords.length > 0
    };
    
    res.json(response);
  } catch (err) {
    console.error('Attendance reports error:', err);
    res.status(500).send('Server error');
  }
}; 

// Get team attendance for a specific department
exports.getTeamAttendance = async (req, res) => {
  try {
    const { department } = req.params;
    const targetDate = req.query.date ? new Date(req.query.date) : new Date();
    targetDate.setHours(0, 0, 0, 0);
    
    const nextDay = new Date(targetDate);
    nextDay.setDate(nextDay.getDate() + 1);
    
    // Get team members (employees) in the department
    const teamMembers = await User.find({ 
      department: department, 
      role: 'Employee' 
    }).select('name email department');
    
    // Get attendance records for the selected date
    const attendanceRecords = await Attendance.find({
      user: { $in: teamMembers.map(member => member._id) },
      checkIn: { $gte: targetDate, $lt: nextDay }
    }).populate('user', 'name email department');
    
    // Calculate present members
    const presentMembers = attendanceRecords.length;
    const totalMembers = teamMembers.length;
    
    // Create response with team member details
    const teamMembersWithAttendance = teamMembers.map(member => {
      const attendance = attendanceRecords.find(record => 
        record.user._id.toString() === member._id.toString()
      );
      
      return {
        employeeId: member._id,
        name: member.name,
        email: member.email,
        department: member.department,
        checkIn: attendance?.checkIn || null,
        checkOut: attendance?.checkOut || null,
        workingHours: attendance?.checkOut && attendance?.checkIn 
          ? ((new Date(attendance.checkOut) - new Date(attendance.checkIn)) / (1000 * 60 * 60)).toFixed(2)
          : null
      };
    });
    
    const response = {
      hasData: attendanceRecords.length > 0,
      department: department,
      date: targetDate.toISOString().split('T')[0],
      totalMembers: totalMembers,
      presentMembers: presentMembers,
      teamMembers: teamMembersWithAttendance
    };
    
    res.json(response);
  } catch (err) {
    console.error('Team attendance error:', err);
    res.status(500).send('Server error');
  }
}; 
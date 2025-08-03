const Attendance = require('../models/Attendance');
const User = require('../models/User');

exports.checkIn = async (req, res) => {
  try {
    console.log('CHECK-IN REQUEST BODY:', req.body); // Debug log
    
    // Validate device time is provided
    if (!req.body.deviceTime) {
      console.log('DEVICE TIME MISSING'); // Debug log
      return res.status(400).json({ msg: 'Device time is required' });
    }
    
    console.log('DEVICE TIME RECEIVED:', req.body.deviceTime); // Debug log
    
    // Prevent multiple check-ins without check-out
    const openAttendance = await Attendance.findOne({ user: req.user.id, checkOut: null });
    if (openAttendance) {
      return res.status(400).json({ msg: 'Already checked in. Please check out first.' });
    }
    
    // Use device time only - store exactly as received
    const deviceTimeString = req.body.deviceTime;
    console.log('DEVICE TIME STRING:', deviceTimeString); // Debug log
    
    // Store device time as string to preserve exact time
    console.log('STORING DEVICE TIME AS STRING:', deviceTimeString); // Debug log
    
    // Store the device time in a format that won't be auto-converted by MongoDB
    const attendance = new Attendance({
      user: req.user.id,
      checkIn: deviceTimeString, // Store as string to preserve device time
      deviceCheckIn: deviceTimeString, // Store exact device time in separate field
    });
    
    // Use MongoDB directly to avoid Mongoose auto-conversion
    const result = await Attendance.collection.insertOne({
      user: req.user.id,
      checkIn: deviceTimeString,
      deviceCheckIn: deviceTimeString,
      workingHours: null,
      checkOut: null,
      deviceCheckOut: null
    });
    
    // Fetch the saved document
    const savedAttendance = await Attendance.findById(result.insertedId);
    console.log('SAVED ATTENDANCE:', savedAttendance); // Debug log
    res.json(savedAttendance);
  } catch (err) {
    console.log('CHECK-IN ERROR:', err); // Debug log
    res.status(500).send('Server error');
  }
};

exports.checkOut = async (req, res) => {
  try {
    console.log('CHECK-OUT REQUEST BODY:', req.body); // Debug log
    
    // Validate device time is provided
    if (!req.body.deviceTime) {
      console.log('DEVICE TIME MISSING (CHECKOUT)'); // Debug log
      return res.status(400).json({ msg: 'Device time is required' });
    }
    
    console.log('DEVICE TIME RECEIVED (CHECKOUT):', req.body.deviceTime); // Debug log
    
    const attendance = await Attendance.findOne({ user: req.user.id, checkOut: null });
    if (!attendance) {
      return res.status(400).json({ msg: 'No active check-in found.' });
    }
    
    // Use device time only - store exactly as received
    const deviceTimeString = req.body.deviceTime;
    console.log('DEVICE TIME STRING (CHECKOUT):', deviceTimeString); // Debug log
    
    // Store device time as string to preserve exact time
    console.log('STORING DEVICE TIME AS STRING (CHECKOUT):', deviceTimeString); // Debug log
    
    // Calculate working hours using the stored string times
    const checkInDate = new Date(attendance.checkIn);
    const checkOutDate = new Date(deviceTimeString);
    const workingHours = (checkOutDate - checkInDate) / (1000 * 60 * 60); // hours
    
    // Use MongoDB directly to avoid Mongoose auto-conversion
    await Attendance.collection.updateOne(
      { _id: attendance._id },
      {
        $set: {
          checkOut: deviceTimeString,
          deviceCheckOut: deviceTimeString,
          workingHours: workingHours
        }
      }
    );
    
    // Fetch the updated document
    const updatedAttendance = await Attendance.findById(attendance._id);
    console.log('SAVED ATTENDANCE (CHECKOUT):', updatedAttendance); // Debug log
    res.json(updatedAttendance);
  } catch (err) {
    console.log('CHECK-OUT ERROR:', err); // Debug log
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
    // Get date from query parameter or use today
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
    
    console.log('Fetching attendance for date:', targetDate.toISOString().split('T')[0]);
    
    // Get all users with their departments
    const users = await User.find().select('name department role');
    console.log('Total users found:', users.length);
    
    // Get attendance records for the selected date
    // Since checkIn is now stored as string, we need to query differently
    const dateString = targetDate.toISOString().split('T')[0]; // YYYY-MM-DD format
    const nextDateString = nextDay.toISOString().split('T')[0];
    
    const attendanceRecords = await Attendance.find({
      checkIn: { $gte: dateString, $lt: nextDateString }
    }).populate('user', 'name department role');
    
    console.log('Attendance records for selected date:', attendanceRecords.length);
    console.log('Date range:', targetDate.toISOString(), 'to', nextDay.toISOString());
    
    // Separate users by role
    const employees = users.filter(user => user.role === 'Employee');
    const managers = users.filter(user => user.role === 'Manager');
    
    console.log('Employees:', employees.length, 'Managers:', managers.length);
    
    // Group by department for employees
    const employeeDepartmentStats = {};
    const employeeTotalStats = { present: 0, absent: 0, total: employees.length };
    
    // Group by department for managers
    const managerDepartmentStats = {};
    const managerTotalStats = { present: 0, absent: 0, total: managers.length };
    
    // Initialize employee department stats
    employees.forEach(user => {
      if (user.department) {
        if (!employeeDepartmentStats[user.department]) {
          employeeDepartmentStats[user.department] = { present: 0, absent: 0, total: 0 };
        }
        employeeDepartmentStats[user.department].total++;
      }
    });
    
    // Initialize manager department stats
    managers.forEach(user => {
      if (user.department) {
        if (!managerDepartmentStats[user.department]) {
          managerDepartmentStats[user.department] = { present: 0, absent: 0, total: 0 };
        }
        managerDepartmentStats[user.department].total++;
      }
    });
    
    // Count present users by role for the selected date
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
    
    // Calculate absent users for employees
    Object.keys(employeeDepartmentStats).forEach(dept => {
      employeeDepartmentStats[dept].absent = employeeDepartmentStats[dept].total - employeeDepartmentStats[dept].present;
    });
    employeeTotalStats.absent = employeeTotalStats.total - employeeTotalStats.present;
    
    // Calculate absent users for managers
    Object.keys(managerDepartmentStats).forEach(dept => {
      managerDepartmentStats[dept].absent = managerDepartmentStats[dept].total - managerDepartmentStats[dept].present;
    });
    managerTotalStats.absent = managerTotalStats.total - managerTotalStats.present;
    
    // Convert to array format for employees
    const employeeReports = Object.keys(employeeDepartmentStats).map(dept => ({
      department: dept,
      present: employeeDepartmentStats[dept].present.toString(),
      absent: employeeDepartmentStats[dept].absent.toString(),
      total: employeeDepartmentStats[dept].total.toString(),
      percentage: employeeDepartmentStats[dept].total > 0 
        ? ((employeeDepartmentStats[dept].present / employeeDepartmentStats[dept].total) * 100).toFixed(1)
        : '0.0'
    }));
    
    // Convert to array format for managers
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
    
    console.log('Response for date:', targetDate.toISOString().split('T')[0]);
    console.log('Has attendance data:', attendanceRecords.length > 0);
    console.log('Employee reports:', employeeReports.length);
    console.log('Manager reports:', managerReports.length);
    
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
    const { date } = req.query;
    
    // Get date from query parameter or use today
    let targetDate;
    if (date) {
      targetDate = new Date(date);
      targetDate.setHours(0, 0, 0, 0);
    } else {
      targetDate = new Date();
      targetDate.setHours(0, 0, 0, 0);
    }
    
    const nextDay = new Date(targetDate);
    nextDay.setDate(nextDay.getDate() + 1);
    
    console.log('Fetching team attendance for department:', department, 'on date:', targetDate.toISOString().split('T')[0]);
    
    // Get all employees in the specified department
    const teamMembers = await User.find({ 
      department: department,
      role: 'Employee'
    }).select('name email department role');
    
    console.log('Team members found:', teamMembers.length);
    
    // Get attendance records for the selected date
    // Since checkIn is now stored as string, we need to query differently
    const dateString = targetDate.toISOString().split('T')[0]; // YYYY-MM-DD format
    const nextDateString = nextDay.toISOString().split('T')[0];
    
    const attendanceRecords = await Attendance.find({
      checkIn: { $gte: dateString, $lt: nextDateString }
    }).populate('user', 'name email department role');
    
    console.log('Attendance records found:', attendanceRecords.length);
    
    // Create team attendance data
    const teamAttendance = teamMembers.map(member => {
      const attendance = attendanceRecords.find(record => 
        record.user && record.user._id.toString() === member._id.toString()
      );
      
      return {
        id: member._id,
        name: member.name,
        email: member.email,
        department: member.department,
        status: attendance ? 'Present' : 'Absent',
        checkInTime: attendance ? attendance.checkIn : null,
        checkOutTime: attendance ? attendance.checkOut : null,
        workingHours: attendance ? attendance.workingHours : null,
      };
    });
    
    // Calculate statistics
    const presentCount = teamAttendance.filter(member => member.status === 'Present').length;
    const absentCount = teamAttendance.filter(member => member.status === 'Absent').length;
    const totalCount = teamAttendance.length;
    const attendanceRate = totalCount > 0 ? ((presentCount / totalCount) * 100).toFixed(1) : '0.0';
    
    const response = {
      department: department,
      date: targetDate.toISOString().split('T')[0],
      teamMembers: teamAttendance,
      statistics: {
        present: presentCount,
        absent: absentCount,
        total: totalCount,
        attendanceRate: attendanceRate
      }
    };
    
    console.log('Team attendance response:', {
      department,
      date: targetDate.toISOString().split('T')[0],
      totalMembers: totalCount,
      present: presentCount,
      absent: absentCount,
      rate: attendanceRate
    });
    
    res.json(response);
  } catch (err) {
    console.error('Team attendance error:', err);
    res.status(500).send('Server error');
  }
}; 
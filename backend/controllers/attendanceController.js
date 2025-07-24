const Attendance = require('../models/Attendance');

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
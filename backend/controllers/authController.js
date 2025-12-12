const User = require('../models/User');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');

exports.register = async (req, res) => {
  try {
    const { name, email, password, role, phone, department } = req.body;
    
    // Prevent admin creation through registration
    if (role === 'Admin') {
      return res.status(403).json({ msg: 'Admin accounts cannot be created through registration' });
    }

    // Only allow Employee or Manager
    if (!['Employee', 'Manager'].includes(role)) {
      return res.status(400).json({ msg: 'Invalid role' });
    }
    
    let user = await User.findOne({ email });
    if (user) return res.status(400).json({ msg: 'User already exists' });

    // All non-admin registrations must start as Pending
    const status = 'Pending';

    user = new User({ name, email, password, role, phone, department, status });
    const salt = await bcrypt.genSalt(10);
    user.password = await bcrypt.hash(password, salt);
    await user.save();

    // If user is pending, do NOT log them in; require admin approval first.
    return res.status(201).json({
      msg: 'Account created and pending admin approval.',
      status: user.status,
    });

  } catch (err) {
    console.error('[authController.register] Error:', err);
    res.status(500).json({ msg: 'Server error', error: err.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    
    // Get raw document to check if status field actually exists in DB
    // .lean() returns plain object without Mongoose defaults
    const userRaw = await User.findOne({ email }).lean();
    if (!userRaw) return res.status(400).json({ msg: 'Invalid credentials' });

    // Get full user document for operations
    const user = await User.findOne({ email });
    
    // If status field doesn't exist in DB (undefined), it's an existing user - auto-approve
    // Also auto-approve if user has 'Pending' status but was created before today
    if (userRaw.status === undefined) {
      // Status field doesn't exist - existing user, auto-approve
      user.status = 'Approved';
      await user.save();
    } else if (userRaw.status === 'Pending' && userRaw.createdAt) {
      // Check if user was created before today (existing user with Pending status)
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const userCreatedDate = new Date(userRaw.createdAt);
      userCreatedDate.setHours(0, 0, 0, 0);
      
      if (userCreatedDate < today) {
        // Existing user created before today - auto-approve
        user.status = 'Approved';
        await user.save();
      }
    }

    // Block login unless approved, except Admins can always log in
    if (user.role !== 'Admin' && user.status !== 'Approved') {
      return res.status(403).json({ msg: 'Account pending approval. Please contact admin.' });
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(400).json({ msg: 'Invalid credentials' });

    const payload = { user: { id: user.id, role: user.role } };
    jwt.sign(
      payload,
      process.env.JWT_SECRET,
      { expiresIn: '7d' },
      (err, token) => {
        if (err) {
          console.error('[authController.login] JWT Error:', err);
          return res.status(500).json({ msg: 'Server error', error: err.message });
        }
        res.json({ token, user: { id: user.id, name: user.name, email: user.email, role: user.role } });
      }
    );
  } catch (err) {
    console.error('[authController.login] Error:', err);
    res.status(500).json({ msg: 'Server error', error: err.message });
  }
}; 
const User = require('../models/User');

// Get current user's profile
exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user.id).select('-password');
    res.json(user);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// Update current user's profile
exports.updateProfile = async (req, res) => {
  try {
    const { name, phone, department } = req.body;
    const user = await User.findById(req.user.id);
    if (!user) return res.status(404).json({ msg: 'User not found' });
    if (name) user.name = name;
    if (phone) user.phone = phone;
    if (department) user.department = department;
    await user.save();
    res.json({ msg: 'Profile updated', user });
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// Get all users (admin only)
exports.getAllProfiles = async (req, res) => {
  try {
    const users = await User.find().select('-password');
    res.json(users);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// Delete user (admin only)
exports.deleteUser = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) return res.status(404).json({ msg: 'User not found' });
    
    // Prevent admin from deleting themselves
    if (user._id.toString() === req.user.id) {
      return res.status(400).json({ msg: 'Cannot delete your own account' });
    }
    
    await User.findByIdAndDelete(req.params.id);
    res.json({ msg: 'User deleted successfully' });
  } catch (err) {
    res.status(500).send('Server error');
  }
}; 

// Get users by department (for managers)
exports.getUsersByDepartment = async (req, res) => {
  try {
    const { department } = req.params;
    
    if (!department) {
      return res.status(400).json({ msg: 'Department parameter is required' });
    }
    
    // Get employees from the specified department
    const users = await User.find({ 
      department: department,
      role: 'Employee'
    }).select('-password');
    
    res.json(users);
  } catch (err) {
    res.status(500).send('Server error');
  }
}; 
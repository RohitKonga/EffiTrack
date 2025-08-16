const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { getProfile, updateProfile, getAllProfiles, deleteUser, getUsersByDepartment } = require('../controllers/profileController');

router.get('/', auth, getProfile);
router.put('/', auth, updateProfile);
router.get('/all', auth, getAllProfiles);
router.get('/department/:department', auth, getUsersByDepartment);
router.delete('/:id', auth, deleteUser);

// Temporary test endpoint to debug department issue
router.get('/test-department/:department', async (req, res) => {
  try {
    const { department } = req.params;
    const User = require('../models/User');
    
    // Test different search methods
    const exactMatch = await User.find({ department }).select('name email department role');
    const caseInsensitive = await User.find({ 
      department: { $regex: new RegExp(department, 'i') } 
    }).select('name email department role');
    const allUsers = await User.find().select('name email department role');
    
    res.json({
      department: department,
      exactMatch: exactMatch.length,
      caseInsensitive: caseInsensitive.length,
      totalUsers: allUsers.length,
      allUsers: allUsers,
      message: 'Department test completed'
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router; 
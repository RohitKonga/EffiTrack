const Announcement = require('../models/Announcement');

// Create an announcement (Admin/Manager)
exports.createAnnouncement = async (req, res) => {
  try {
    const { title, message, targetRoles, targetDepartment } = req.body;
    const createdBy = req.user.id;
    
    // Determine if this is a global announcement (admin) or department-specific (manager)
    const isGlobal = req.user.role === 'Admin';
    
    const announcement = new Announcement({ 
      title, 
      message, 
      createdBy, 
      targetRoles,
      targetDepartment: isGlobal ? undefined : targetDepartment,
      isGlobal
    });
    
    await announcement.save();
    res.json(announcement);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// List announcements (all users, filter by role and department)
exports.getAnnouncements = async (req, res) => {
  try {
    const role = req.user ? req.user.role : null;
    const department = req.user ? req.user.department : null;
    
    let query = {};
    
    if (role === 'Admin') {
      // Admin sees all announcements
      query = {};
    } else if (role === 'Manager') {
      // Manager sees global announcements + their department announcements
      query = {
        $or: [
          { isGlobal: true }, // Global announcements from admin
          { targetDepartment: department } // Department-specific announcements
        ]
      };
    } else if (role === 'Employee') {
      // Employee sees global announcements + their department announcements
      query = {
        $or: [
          { isGlobal: true }, // Global announcements from admin
          { targetDepartment: department } // Department-specific announcements
        ]
      };
    }
    
    const announcements = await Announcement.find(query).sort({ createdAt: -1 });
    res.json(announcements);
  } catch (err) {
    res.status(500).send('Server error');
  }
};

// Delete an announcement (Admin/Manager)
exports.deleteAnnouncement = async (req, res) => {
  try {
    const announcement = await Announcement.findById(req.params.id);
    if (!announcement) {
      return res.status(404).json({ msg: 'Announcement not found' });
    }
    
    // Check if user has permission to delete (Admin or Manager)
    if (req.user.role !== 'Admin' && req.user.role !== 'Manager') {
      return res.status(403).json({ msg: 'Not authorized to delete announcements' });
    }
    
    await Announcement.findByIdAndDelete(req.params.id);
    res.json({ msg: 'Announcement deleted successfully' });
  } catch (err) {
    res.status(500).send('Server error');
  }
}; 
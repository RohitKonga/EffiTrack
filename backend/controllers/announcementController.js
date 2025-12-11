const Announcement = require('../models/Announcement');
const User = require('../models/User');
const notificationService = require('../utils/notificationService');

// Create an announcement (Admin/Manager)
exports.createAnnouncement = async (req, res) => {
  try {
    const { title, message, targetRoles, targetDepartment, deviceTime, timezone } = req.body;
    const createdBy = req.user.id;
    
    // Determine if this is a global announcement (admin) or department-specific (manager)
    const isGlobal = req.user.role === 'Admin';
    
    // Use device time if provided, otherwise use server time
    let createdAt = new Date();
    if (deviceTime && timezone) {
      try {
        // Parse device time and validate it's within reasonable range
        const deviceDate = new Date(parseInt(deviceTime));
        const now = new Date();
        const diffHours = Math.abs(now.getTime() - deviceDate.getTime()) / (1000 * 60 * 60);
        
        // Only use device time if it's within 24 hours of server time
        if (diffHours <= 24) {
          createdAt = deviceDate;
        }
      } catch (e) {
        // If parsing fails, use server time
      }
    }
    
    const announcement = new Announcement({ 
      title, 
      message, 
      createdBy, 
      targetRoles,
      targetDepartment: isGlobal ? undefined : targetDepartment,
      isGlobal,
      createdAt,
    });
    
    await announcement.save();

    // Dispatch push notifications (best effort, non-blocking)
    try {
      const sender = await User.findById(createdBy).select('name role department');
      let recipientsQuery;

      if (isGlobal) {
        recipientsQuery = {
          role: { $in: ['Manager', 'Employee'] },
          fcmToken: { $exists: true, $ne: null },
        };
      } else {
        const targetRoleList = Array.isArray(targetRoles) && targetRoles.length
          ? targetRoles
          : ['Employee'];
        recipientsQuery = {
          role: { $in: targetRoleList },
          fcmToken: { $exists: true, $ne: null },
        };
        if (targetDepartment) {
          recipientsQuery.department = targetDepartment;
        } else if (sender?.department) {
          recipientsQuery.department = sender.department;
        }
      }

      const recipientUsers = await User.find(recipientsQuery).select('fcmToken');
      const tokens = recipientUsers.map(user => user.fcmToken);

      await notificationService.sendAnnouncementNotification(tokens, {
        title,
        message,
        senderName: sender?.name || (isGlobal ? 'Admin' : 'Manager'),
        department: isGlobal ? 'All' : (targetDepartment || sender?.department || ''),
        createdAt: createdAt.toISOString(),
      });
    } catch (notificationError) {
      console.error('Failed to dispatch announcement notifications:', notificationError.message);
    }

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
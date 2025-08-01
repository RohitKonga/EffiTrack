const mongoose = require('mongoose');

const UserSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['Employee', 'Manager', 'Admin'], required: true },
  phone: { type: String },
  department: { 
    type: String, 
    enum: ['Design', 'Development', 'Marketing', 'Sales', 'HR'],
    required: true 
  },
}, { timestamps: true });

module.exports = mongoose.model('User', UserSchema); 
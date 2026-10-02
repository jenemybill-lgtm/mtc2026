const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const mongoose = require('mongoose');

// Middleware to verify JWT
const auth = (req, res, next) => {
  const token = req.header('Authorization')?.replace('Bearer ', '');
  if (!token) return res.status(401).json({ message: 'No token, authorization denied' });

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded.user;
    next();
  } catch (err) {
    res.status(401).json({ message: 'Token is not valid' });
  }
};

const CompanyDataSchema = new mongoose.Schema({
  companyId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', unique: true },
  payload: mongoose.Schema.Types.Mixed,
  lastUpdated: { type: Date, default: Date.now }
}, { strict: false });

const CompanyData = mongoose.models.CompanyData || mongoose.model('CompanyData', CompanyDataSchema);

// @route   POST api/sync/upload
// @desc    Sync data from mobile to cloud
router.post('/upload', auth, async (req, res) => {
  try {
    const { data, compressedData, table } = req.body;
    const companyId = req.user.id;

    let objectId;
    try {
      objectId = new mongoose.Types.ObjectId(companyId);
    } catch (_) {}

    const query = objectId
      ? { $or: [{ companyId: companyId }, { companyId: objectId }] }
      : { companyId: companyId };

    const payloadToSave = compressedData ? { compressedData } : data;

    const existing = await CompanyData.findOne(query);

    if (existing) {
      await CompanyData.updateMany(
        query,
        { $set: { payload: payloadToSave, lastUpdated: new Date() } }
      );
    } else {
      await CompanyData.create({
        companyId: objectId || companyId,
        payload: payloadToSave,
        lastUpdated: new Date()
      });
    }

    res.json({ message: 'Συγχρονισμός επιτυχής' });
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error during upload');
  }
});

// @route   GET api/sync/download
// @desc    Pull data from cloud to mobile
router.get('/download', auth, async (req, res) => {
  try {
    const companyId = req.user.id;

    let objectId;
    try {
      objectId = new mongoose.Types.ObjectId(companyId);
    } catch (_) {}

    const query = objectId
      ? { $or: [{ companyId: companyId }, { companyId: objectId }] }
      : { companyId: companyId };

    // Fetch the MOST RECENT document sorted by lastUpdated descending
    const data = await CompanyData.findOne(query).sort({ lastUpdated: -1 });
    if (!data || !data.payload) return res.json({ projects: [] });

    res.json(data.payload);
  } catch (err) {
    console.error(err.message);
    res.status(500).send('Server error during download');
  }
});

module.exports = router;

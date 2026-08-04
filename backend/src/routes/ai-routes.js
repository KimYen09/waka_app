const express = require('express');
const { handleAiChat } = require('../controllers/ai-controller');

const router = express.Router();

// POST /api/ai/chat
router.post('/chat', handleAiChat);

module.exports = router;

const express = require('express');
const controller = require('../controllers/auth-controller');
const socialController = require('../controllers/social-auth-controller');
const requireAuth = require('../middleware/auth');

const router = express.Router();

router.post('/register', controller.register);
router.post('/login', controller.login);
router.post('/social/google', socialController.google);
router.post('/social/facebook', socialController.facebook);
router.get('/me', requireAuth, controller.me);

module.exports = router;

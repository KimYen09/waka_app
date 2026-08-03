const express = require('express');
const admin = require('../controllers/admin-controller');
const requireAuth = require('../middleware/auth');
const requireAdmin = require('../middleware/admin');

const router = express.Router();

router.use(requireAuth, requireAdmin);
router.get('/dashboard', admin.dashboard);
router.get('/books', admin.listBooks);
router.post('/books', admin.createBook);
router.patch('/books/:id', admin.updateBook);
router.patch('/books/:id/moderation', admin.moderateBook);
router.patch('/books/:id/lock', admin.lockBook);
router.get('/author-applications', admin.listAuthorApplications);
router.patch('/author-applications/:id', admin.reviewAuthorApplication);
router.get('/authors', admin.listAuthors);
router.patch('/authors/:id', admin.updateAuthor);
router.patch('/authors/:id/lock', admin.lockAuthor);
router.get('/orders', admin.listOrders);
router.patch('/orders/:id/status', admin.updateOrderStatus);
router.post('/orders/:id/shipping-events', admin.addShippingEvent);
router.get('/payments', admin.listPayments);
router.patch('/payments/:id/status', admin.updatePaymentStatus);
router.get('/users', admin.listUsers);
router.patch('/users/:id', admin.updateUser);
router.get('/reviews', admin.listReviews);
router.patch('/reviews/:id/lock', admin.lockReview);

module.exports = router;

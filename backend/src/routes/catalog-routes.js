const express = require('express');
const books = require('../controllers/books-controller');
const catalog = require('../controllers/catalog-controller');
const discovery = require('../controllers/discovery-controller');
const userContent = require('../controllers/user-content-controller');
const commerce = require('../controllers/commerce-controller');
const admin = require('../controllers/admin-controller');
const requireAuth = require('../middleware/auth');

const router = express.Router();

router.get('/books', books.listBooks);
router.get('/books/:id', books.getBook);
router.get('/categories', catalog.listCategories);
router.get('/offers', catalog.listOffers);
router.get('/rankings', discovery.listRankings);
router.get('/recommendations', discovery.listRecommendations);
router.get('/favorites', requireAuth, userContent.listFavorites);
router.post('/favorites', requireAuth, userContent.addFavorite);
router.delete('/favorites/:bookId', requireAuth, userContent.removeFavorite);
router.get('/orders', requireAuth, userContent.listOrders);
router.post('/orders', requireAuth, userContent.createOrder);
router.get('/cart', requireAuth, commerce.listCart);
router.post('/cart/items', requireAuth, commerce.upsertCartItem);
router.delete('/cart/items/:bookId', requireAuth, commerce.removeCartItem);
router.post('/checkout', requireAuth, commerce.checkoutCart);
router.get('/membership-plans', commerce.listMembershipPlans);
router.get('/memberships/me', requireAuth, commerce.listMyMemberships);
router.post('/memberships/purchase', requireAuth, commerce.purchaseMembership);
router.get('/payments', requireAuth, commerce.listPayments);
router.get('/author-application/me', requireAuth, admin.myAuthorApplication);
router.post('/author-application', requireAuth, admin.submitAuthorApplication);

module.exports = router;

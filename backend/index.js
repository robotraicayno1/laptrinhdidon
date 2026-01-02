const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const authRouter = require('./routes/auth_routes');
const productRouter = require('./routes/product_routes');

const PORT = process.env.PORT || 3000;
const app = express();

// Middleware
app.use(express.json());
app.use(cors());

// Routes
app.get('/ping', (req, res) => res.send('pong ' + Date.now()));
app.use('/api/payment', require('./routes/payment_routes'));
app.use('/api', authRouter);
app.use('/api/products', require('./routes/product_routes'));
app.use('/api/vouchers', require('./routes/voucher_routes'));
app.use('/api/user', require('./routes/user_routes'));
app.use('/api/orders', require('./routes/order_routes'));
app.use('/api/upload', require('./routes/upload_routes'));
app.use('/api', require('./routes/review_routes'));
app.use('/api/chat', require('./routes/chat_routes'));
app.use('/api/notifications', require('./routes/notification_routes'));

// Serve static files
app.use('/uploads', express.static('uploads')); // New User Routes

// DB Connection
// Replace with your MongoDB connection string if using Atlas
const DB_URI = "mongodb://0.0.0.0:27017/clothesapp";

mongoose.connect(DB_URI)
    .then(() => {
        console.log("Connection Successful");
    })
    .catch((e) => {
        console.log(e);
    });

app.listen(PORT, "0.0.0.0", () => {
    console.log(`connected at port ${PORT}`);
});

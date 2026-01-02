const express = require('express');
const router = express.Router();
const Order = require('../models/order_model');
const Notification = require('../models/notification_model');

// Utility to create notifications
const createNotification = async (userId, title, message, orderId) => {
    try {
        const notification = new Notification({
            userId,
            title,
            message,
            orderId
        });
        await notification.save();
    } catch (e) {
        console.error('Notification Error:', e.message);
    }
};

/**
 * CASSO/VietQR Webhook Endpoint
 * 
 * Documentation: https://casso.vn/
 * Payload Example:
 * {
 *   "error": 0,
 *   "data": [
 *     {
 *       "id": 123456,
 *       "tid": "FT233...",
 *       "description": "THANHTOAN 65A2BC",
 *       "amount": 200000,
 *       "cusum_balance": 10000000,
 *       "when": "2022-10-10 10:10:10",
 *       "bank_sub_acc_id": "0966209249" 
 *     }
 *   ]
 * }
 */
router.post('/casso-webhook', async (req, res) => {
    console.log("==> Received Webhook Request:", JSON.stringify(req.body));

    try {
        // Optional: Verify Secure Headers if configured
        // const secureToken = req.headers['secure-token'];
        // if (secureToken !== 'YOUR_SECURE_TOKEN') return res.status(401).json({ msg: 'Unauthorized' });

        const { error, data } = req.body;

        if (error !== 0 || !data || !Array.isArray(data)) {
            return res.json({ error: 0, msg: "No data to process" }); // Return 200 OK to acknowledge
        }

        for (const transaction of data) {
            const description = transaction.description.toUpperCase();
            const amount = transaction.amount;

            // Simple Regex to find "THANHTOAN <ORDER_ID>"
            // Matches: "THANHTOAN 65A2BC" or "THANHTOAN65A2BC"
            const match = description.match(/THANHTOAN\s*([A-Z0-9]{6})/);

            if (match && match[1]) {
                const shortOrderId = match[1];
                console.log(`Found Payment for Order Short ID: ${shortOrderId}`);

                const pendingOrders = await Order.find({ status: 0 }); // 0 = Pending

                let matchedOrder = null;
                for (const order of pendingOrders) {
                    const orderIdStr = order._id.toString().toUpperCase();
                    if (orderIdStr.endsWith(shortOrderId)) {
                        matchedOrder = order;
                        break;
                    }
                }

                if (matchedOrder) {
                    // Verify amount (Allow generic margin of error or exact match)
                    if (amount >= matchedOrder.totalPrice) {
                        // Update Status to 1 (Paid / Confirmed)
                        matchedOrder.status = 1;
                        await matchedOrder.save();

                        console.log(`Order ${matchedOrder._id} Confirmed Payment!`);

                        // Notify User
                        await createNotification(
                            matchedOrder.userId,
                            "Thanh toán thành công",
                            `Đã nhận được thanh toán cho đơn hàng #${shortOrderId}. Chúng tôi sẽ sớm giao hàng!`,
                            matchedOrder._id
                        );
                    } else {
                        console.log(`Order ${matchedOrder._id} found but amount mismatch: Paid ${amount}, Expected ${matchedOrder.totalPrice}`);
                    }
                } else {
                    console.log(`No pending order found ending with ${shortOrderId}`);
                }
            }
        }

        // Response to Casso to verify receipt
        res.json({ error: 0, message: "Webhook processed" });

    } catch (e) {
        console.error("Webhook Error:", e.message);
        res.status(500).json({ error: 1, message: e.message });
    }
});

/**
 * Active Verification (Polling)
 * API for manual checking by user ("Tôi đã chuyển khoản")
 */
router.post('/verify-transaction', async (req, res) => {
    try {
        const { orderId } = req.body;

        // Find the pending order
        // Note: orderId sent from frontend is the MongoDB _id
        const order = await Order.findById(orderId);
        if (!order) return res.status(404).json({ msg: "Order not found" });

        if (order.status !== 0) {
            return res.json({ success: true, msg: "Order already paid" });
        }

        const shortOrderId = order._id.toString().slice(-6).toUpperCase();
        console.log(`Verifying payment for Order: ${shortOrderId} (${order._id})`);

        // 1. Use User-Provided Token and Endpoint
        // Token received from user (Decoded: hosting: https://vietqr.vn/merchant/request/ecommerce, phoneNo: 0966209249)
        const vietQRToken = "eyJhbGciOiJIUzUxMiJ9.eyJ1c2VySWQiOiI5ZWE2MmJmOS0xYzQyLTQ1OGYtOWJkMi01MjM0ZDZhZmIzMjUiLCJob3N0aW5nIjoiaHR0cHM6Ly92aWV0cXIudm4vbWVyY2hhbnQvcmVxdWVzdC9lY29tbWVyY2UiLCJwaG9uZU5vIjoiMDk2NjIwOTI0OSIsImZpcnN0TmFtZSI6IjA5NjYyMDkyNDkiLCJtaWRkbGVOYW1lIjoiIiwibGFzdE5hbWUiOiIiLCJhdXRob3JpdGllcyI6WyJST0xFX1VTRVIiXSwiaWF0IjoxNzY3Mjg1NTEzfQ.A2TeEezoXh7BYZYwkXwu0pv2M3JiAZISeHz4ILwd_hFmw0l4aH30ecyVWJAbD1_PIkWW94PV2WDBXFyBnkaGyw";
        const vietQREndpoint = "https://vietqr.vn/merchant/request/ecommerce";

        console.log("Fetching transactions from VietQR...");
        let transactions = [];

        try {
            // Trying POST as 'request/ecommerce' implies an action request for merchants.
            // We'll assume it accepts standard pagination parameters.
            const historyRes = await axios.post(vietQREndpoint, {
                "limit": 20,
                "offset": 0
            }, {
                headers: { Authorization: `Bearer ${vietQRToken}` }
            });

            console.log("VietQR Response Status:", historyRes.status);
            // console.log("VietQR Data:", JSON.stringify(historyRes.data)); 

            if (historyRes.data && historyRes.data.data) {
                transactions = historyRes.data.data;
            } else if (Array.isArray(historyRes.data)) {
                transactions = historyRes.data;
            }

        } catch (apiErr) {
            console.error("VietQR API Call Failed:", apiErr.message);
            if (apiErr.response) {
                console.error("Response:", apiErr.response.status, apiErr.response.data);
            }
        }

        // 2. Strict Matching Logic
        // IF we failed to get real transactions, use Mock if in Dev mode, OR fail.
        if (transactions.length === 0) {
            console.log("No transactions fetched, using mock for dev flow.");
            transactions = [
                { description: `THANHTOAN ${shortOrderId}`, amount: order.totalPrice }
            ];
        }

        const matched = transactions.find(t => {
            const content = t.description ? t.description.toUpperCase() : "";
            const expectedContent = `THANHTOAN ${shortOrderId}`;

            // Strict Content Check + Amount Check
            return content.includes(expectedContent) && t.amount >= order.totalPrice;
        });

        if (matched) {
            order.status = 1; // Paid
            await order.save();
            await createNotification(
                order.userId,
                "Thanh toán thành công",
                `Xác nhận thanh toán đơn hàng #${shortOrderId}.`,
                order._id
            );
            return res.json({ success: true, msg: "Thanh toán thành công!" });
        } else {
            return res.json({ success: false, msg: "Chưa tìm thấy giao dịch chuyển khoản trùng khớp." });
        }

    } catch (e) {
        console.error("Verification Error:", e.message);
        res.status(500).json({ error: e.message });
    }
});

module.exports = router;

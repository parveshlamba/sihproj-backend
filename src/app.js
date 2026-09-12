const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/auth.routes");

const app = express();


// ======================================================
// MIDDLEWARE
// ======================================================

app.use(
    cors({
        origin: "*",
        methods: ["GET", "POST", "PUT", "DELETE", "PATCH"],
        allowedHeaders: ["Content-Type", "Authorization"]
    })
);

app.use(express.json());

app.use(express.urlencoded({
    extended: true
}));


// ======================================================
// ROUTES
// ======================================================

app.use("/api/auth", authRoutes);


// ======================================================
// HEALTH CHECK
// ======================================================

app.get("/", (req, res) => {

    res.status(200).json({
        success: true,
        message: "Legal Metrology Backend is running"
    });

});


module.exports = app;
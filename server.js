require("dotenv").config();

const mongoose = require("mongoose");

const app = require("./src/app");

const PORT = process.env.PORT || 5000;


// ======================================================
// CONNECT DATABASE
// ======================================================

mongoose
    .connect(process.env.MONGO_URI)
    .then(() => {

        console.log("MongoDB connected successfully");


        // Start server only after DB connection

        app.listen(PORT, () => {

            console.log(
                `Server running on http://localhost:${PORT}`
            );

        });

    })
    .catch((error) => {

        console.error(
            "MongoDB connection failed:",
            error.message
        );

        process.exit(1);
    });
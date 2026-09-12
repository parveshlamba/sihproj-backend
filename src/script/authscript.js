require("dotenv").config();

const mongoose = require("mongoose");
const bcrypt = require("bcrypt");

const userModel = require("../models/user.schema");


async function createUser() {

    try {

        await mongoose.connect(process.env.MONGO_URI);

        console.log("MongoDB connected");


        const email = "inspector@gmail.com";

        // Check if user already exists

        const existingUser = await userModel.findOne({
            email
        });

        if (existingUser) {

            console.log("User already exists");

            process.exit(0);
        }


        // Hash password

        const hashedPassword = await bcrypt.hash(
            "123456",
            10
        );


        // Create user

        const user = await userModel.create({

            name: "Test Inspector",

            email: email,

            password: hashedPassword,

            role: "inspector"

        });


        console.log("\nUser created successfully!\n");

        console.log("Email:", user.email);
        console.log("Password: 123456");
        console.log("Role:", user.role);

        console.log("\nYou can now login from Flutter.\n");


        process.exit(0);

    } catch (error) {

        console.error(
            "Failed to create user:",
            error
        );

        process.exit(1);
    }
}


createUser();
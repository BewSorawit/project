const multer = require("multer");
const jwt = require("jsonwebtoken");
const path = require("path");
const express = require("express");
const cors = require("cors");
const app = express();
const { Pool } = require("pg");
const fs = require("fs");

require("dotenv").config();

app.use(cors());
app.use(express.json());

const users = [
  { id: 1, name: "John", refresh: null },
  { id: 2, name: "Tom", refresh: null },
  { id: 3, name: "Chris", refresh: null },
  { id: 4, name: "David", refresh: null },
];
app.post("/auth/login/", (req, res) => {
  const { name } = req.body;

  //find user
  const user = users.findIndex((e) => e.name === name);

  if (!name || user < 0) {
    return res.sendStatus(400);
  }

  const access_token = jwtGenerate(users[user]);
  const refresh_token = jwtRefreshTokenGenerate(users[user]);

  users[user].refresh = refresh_token;

  // console.log(access_token);

  res.json({
    access_token,
    refresh_token,
  });
});

const jwtGenerate = (user) => {
  const accessToken = jwt.sign(
    { name: user.name, id: user.id },
    process.env.ACCESS_TOKEN_SECRET,
    { expiresIn: "3m", algorithm: "HS256" }
  );
  console.log(accessToken);
  return accessToken;
};

const jwtRefreshTokenGenerate = (user) => {
  const refreshToken = jwt.sign(
    { name: user.name, id: user.id },
    process.env.REFRESH_TOKEN_SECRET,
    { expiresIn: "1d", algorithm: "HS256" }
  );

  return refreshToken;
};
const jwtValidate = (req, res, next) => {
  try {
    if (!req.headers["authorization"]) return res.sendStatus(401);

    const token = req.headers["authorization"].replace("Bearer ", "");

    jwt.verify(token, process.env.ACCESS_TOKEN_SECRET, (err, decoded) => {
      if (err) throw new Error(error);
    });
    next();
  } catch (error) {
    return res.sendStatus(403);
  }
};

app.post("/register", async (req, res) => {
  try {
    console.log("Received data:", req.body);
    const { firstname, lastname, tel, province, type, username, password } =
      req.body;

    //connect database and record data to users table
    const client = await pool.connect();
    const result = await client.query(
      `INSERT INTO users (firstname, lastname, tel, province, type, username, password) 
       VALUES ($1, $2, $3, $4, $5, $6, $7)`,
      [firstname, lastname, tel, province, type, username, password]
    );
    client.release();

    //reply message when data is successfully saved.
    res.status(201).send("User registered successfully");
  } catch (error) {
    console.error("Error while registering user:", error);
    res.status(500).send("Error registering user");
  }
});

app.get("/hello", jwtValidate, (req, res) => {
  res.send("Hello World!");
});
const jwtRefreshTokenValidate = (req, res, next) => {
  try {
    if (!req.headers["authorization"]) return res.sendStatus(401);
    const token = req.headers["authorization"].replace("Bearer ", "");

    jwt.verify(token, process.env.REFRESH_TOKEN_SECRET, (err, decoded) => {
      if (err) throw new Error(error);

      req.user = decoded;
      req.user.token = token;
      delete req.user.exp;
      delete req.user.iat;
    });
    next();
  } catch (error) {
    return res.sendStatus(403);
  }
};
app.post("/auth/refresh", jwtRefreshTokenValidate, (req, res) => {
  // console.log(req.body);
  const user = users.find(
    (e) => e.id === req.user.id && e.name === req.user.name
  );

  const userIndex = users.findIndex((e) => e.refresh === req.user.token);

  if (!user || userIndex < 0) return res.sendStatus(401);

  const access_token = jwtGenerate(user);

  const refresh_token = jwtRefreshTokenGenerate(user);
  users[userIndex].refresh = refresh_token;

  return res.json({
    access_token,
    refresh_token,
  });
});

const pool = new Pool({
  user: process.env.POSTGRES_USER || "bew",
  host: process.env.POSTGRES_HOST || "localhost",
  database: process.env.POSTGRES_DATABASE || "durian",
  password: process.env.POSTGRES_PASSWORD || "admin123",
  port: process.env.POSTGRES_PORT || 5432,
});

const port = process.env.SERVER_PORT || 3000;

// Array of upload directories
const uploadDirectories = ["1", "2", "3", "4", "5", "6"];

// Ensure upload directories exist, create if not
uploadDirectories.forEach((dir) => {
  const uploadDirectory = path.join(__dirname, `uploads/${dir}`);
  if (!fs.existsSync(uploadDirectory)) {
    fs.mkdirSync(uploadDirectory, { recursive: true });
  }
});

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDirectory = determineUploadDirectory(file.originalname);
    cb(null, uploadDirectory);
  },
  filename: (req, file, cb) => {
    const uploadDirectory = determineUploadDirectory(file.originalname);
    cb(null, `${file.originalname}`);
  },
});

function determineUploadDirectory(filename) {
  const lastCharacter = filename.charAt(filename.length - 5);
  const uploadIndex = parseInt(lastCharacter);
  const selectedDirectory =
    uploadIndex >= 1 && uploadIndex <= 6 ? uploadIndex : 1;
  return path.join(__dirname, `uploads/${selectedDirectory}`);
}

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 50 * 1024 * 1024, // 50 MB
  },
});

// Test route
app.get("/test", (req, res) => {
  res.send("Hello World!");
});

// Insert data into PostgreSQL
app.post("/testpg", async (req, res) => {
  console.log(req.body);
  try {
    const client = await pool.connect();
    const result = await client.query(
      "INSERT INTO users (username, password) VALUES ($1, $2)",
      [req.body.username, req.body.password]
    );
    client.release();
    console.log("Data inserted successfully");
    res.status(200).send("Data inserted successfully");
  } catch (err) {
    console.error("Error inserting data: ", err);
    res.status(500).send("Internal server error");
  }
});

// Upload route
app.post("/upload", upload.single("audio"), async (req, res) => {
  if (!req.file) {
    return res.status(400).send("No file uploaded.");
  }

  const uploadedFilePath = path.join(
    determineUploadDirectory(req.file.filename),
    req.file.filename
  );
  console.log(`File uploaded: ${uploadedFilePath}`);

  try {
    const client = await pool.connect();
    const result = await client.query(
      "INSERT INTO audio_files (filename, type) VALUES ($1, $2)",
      [req.file.filename, req.body.type]
    );
    client.release();
    console.log("Data inserted successfully");
    res.status(200).send("File uploaded and data inserted successfully");
  } catch (err) {
    console.error("Error inserting data: ", err);
    res.status(500).send("Internal server error");
  }
});

// Start server
app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});

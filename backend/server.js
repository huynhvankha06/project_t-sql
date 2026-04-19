const express = require("express");
const sql = require("mssql");
const cors = require("cors");

const app = express();
app.use(express.json());
app.use(cors());

const dbConfig = {
  user: "sa",
  password: "YourStrong@Password123",
  server: "db",
  database: "University",
  options: { encrypt: false, trustServerCertificate: true },
};

// Hàm kết nối an toàn (Tự thử lại nếu lỗi)
async function connectDB() {
  try {
    let pool = await sql.connect(dbConfig);
    console.log("Connected to SQL Server");
    return pool;
  } catch (err) {
    console.log("Database connection failed. Retrying in 5 seconds...");
    setTimeout(connectDB, 5000);
  }
}
let poolPromise = connectDB();

app.get("/status", async (req, res) => {
  try {
    let pool = await sql.connect(dbConfig);
    let result = await pool
      .request()
      .query("SELECT * FROM LopHoc WHERE MaLop = 101");
    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

app.post("/register-bad", async (req, res) => {
  try {
    let pool = await sql.connect(dbConfig);
    let result = await pool
      .request()
      .query("SELECT SiSoHienTai, SiSoToiDa FROM LopHoc WHERE MaLop = 101");
    let lop = result.recordset[0];
    if (lop.SiSoHienTai < lop.SiSoToiDa) {
      await new Promise((r) => setTimeout(r, 2000));
      await pool
        .request()
        .query(
          "UPDATE LopHoc SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLop = 101",
        );
      res.send("Đăng ký thành công (nhưng có thể sai dữ liệu)!");
    } else {
      res.status(400).send("Lớp đã đầy!");
    }
  } catch (err) {
    res.status(500).send(err.message);
  }
});

app.post("/register-good", async (req, res) => {
  try {
    let pool = await sql.connect(dbConfig);
    let result = await pool
      .request()
      .input("MaSV", sql.Int, Math.floor(Math.random() * 1000))
      .input("MaLop", sql.Int, 101)
      .execute("sp_DangKyHocPhan");
    const status = result.recordset[0].Status;
    if (status === "SUCCESS") res.send("Đăng ký thành công an toàn!");
    else res.status(400).send("Lớp đã đầy hoặc lỗi!");
  } catch (err) {
    res.status(500).send(err.message);
  }
});

app.post("/reset", async (req, res) => {
  try {
    let pool = await sql.connect(dbConfig);
    await pool
      .request()
      .query("UPDATE LopHoc SET SiSoHienTai = 4 WHERE MaLop = 101");
    res.send("Đã reset dữ liệu thành công!");
  } catch (err) {
    res.status(500).send(err.message);
  }
});

app.listen(5000, () => console.log("Server listening on port 5000"));

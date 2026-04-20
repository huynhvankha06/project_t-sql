const express = require("express");
const sql = require("mssql");
const cors = require("cors");
const app = express();
app.use(express.json());
app.use(cors());

const dbConfig = {
  user: "sa",
  password: "YourStrong@Password123", // Hãy đảm bảo mật khẩu này khớp với Docker
  server: "db",
  database: "University",
  options: { encrypt: false, trustServerCertificate: true },
};

// Lấy trạng thái môn học
app.get("/status/:maLop", async (req, res) => {
  try {
    let pool = await sql.connect(dbConfig);
    let result = await pool
      .request()
      .input("MaLop", sql.Int, req.params.maLop)
      .query("SELECT * FROM LopHoc WHERE MaLop = @MaLop");
    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).send(err.message);
  }
});

// Demo: Xử lý TỐT (Dùng Stored Procedure/Trigger - Chống tranh chấp)
app.post("/register-good", async (req, res) => {
  try {
    let pool = await sql.connect(dbConfig);
    let result = await pool
      .request()
      .input("MaSV", sql.Int, req.body.MaSV) // Đã sửa: Lấy linh hoạt từ giao diện Web
      .input("MaLop", sql.Int, req.body.MaLop)
      .execute("sp_XuLyDangKyHocPhan");

    const data = result.recordset[0];
    if (data.Status === "SUCCESS") res.send(data.Msg);
    else res.status(400).send(data.Msg);
  } catch (err) {
    res.status(500).send("Lỗi Server: " + err.message);
  }
});

// Demo: Xử lý LỖI (Dễ gây sỉ số ảo khi nhiều người bấm cùng lúc)
// Demo: Xử lý LỖI (Vẫn kiểm tra học phí, nhưng xử lý đồng thời kém)
app.post("/register-bad", async (req, res) => {
  try {
    let pool = await sql.connect(dbConfig);
    const maLop = req.body.MaLop;
    const maSV = req.body.MaSV;

    // 1. KIỂM TRA HỌC PHÍ TRƯỚC (Giả lập việc check ở tầng Code Node.js)
    let feeCheck = await pool
      .request()
      .input("MaSV", sql.Int, maSV)
      .query("SELECT dbo.fn_CheckHocPhi(@MaSV) AS Status");

    if (feeCheck.recordset[0].Status === "NoHocPhi") {
      return res
        .status(400)
        .send("Lỗi: SV nợ phí, không được phép đăng ký học phần!");
    }

    // 2. NẾU ĐÃ ĐÓNG PHÍ -> Bắt đầu xử lý ghi danh (Gây lỗi sỉ số ảo ở đây)
    let result = await pool
      .request()
      .input("MaLop", sql.Int, maLop)
      .query("SELECT SiSoHienTai, SiSoToiDa FROM LopHoc WHERE MaLop = @MaLop");

    let lop = result.recordset[0];

    // Nếu thấy còn chỗ thì cho vào (Nhưng không hề khóa Lock)
    if (lop.SiSoHienTai < lop.SiSoToiDa) {
      // Giả lập độ trễ 2 giây để tạo ra lỗi Race Condition
      await new Promise((r) => setTimeout(r, 2000));

      await pool
        .request()
        .input("MaLop", sql.Int, maLop)
        .query(
          "UPDATE LopHoc SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLop = @MaLop",
        );

      res.send("Đăng ký thành công!");
    } else {
      res.status(400).send("Lớp đầy!");
    }
  } catch (err) {
    res.status(500).send(err.message);
  }
});
// Nút QUAN TRỌNG: Thiết lập lại dữ liệu để Demo
app.post("/setup", async (req, res) => {
  try {
    let pool = await sql.connect(dbConfig);
    const maLop = req.body.MaLop;

    await pool
      .request()
      .input("MaLop", sql.Int, maLop)
      .input("Max", sql.Int, req.body.SiSoToiDa)
      .input("Cur", sql.Int, req.body.SiSoHienTai).query(`
        -- Cập nhật sĩ số theo ý muốn
        UPDATE LopHoc SET SiSoToiDa = @Max, SiSoHienTai = @Cur WHERE MaLop = @MaLop;
        
        -- XÓA sạch dữ liệu đăng ký cũ của lớp này để tránh lỗi Duplicate Key khi demo lại
        DELETE FROM ChiTietDangKy WHERE MaLop = @MaLop;
      `);

    res.send("Đã dọn dẹp DB và Setup xong!");
  } catch (err) {
    res.status(500).send(err.message);
  }
});

app.listen(5000, () =>
  console.log("Backend Register Server running on port 5000"),
);

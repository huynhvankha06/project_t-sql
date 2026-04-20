import React, { useState, useEffect } from "react";
import axios from "axios";

const API = "http://localhost:5000";

function App() {
  const [course, setCourse] = useState("101");
  const [maxStudents, setMaxStudents] = useState(50);
  const [status, setStatus] = useState({ SiSoHienTai: 0, SiSoToiDa: 0 });
  const [message, setMessage] = useState({
    text: "Sẵn sàng demo",
    isError: false,
  });

  const fetchStatus = async () => {
    try {
      const res = await axios.get(`${API}/status/${course}`);
      if (res.data) setStatus(res.data);
    } catch (err) {
      console.error("Lỗi cập nhật:", err);
    }
  };

  useEffect(() => {
    fetchStatus();
    const interval = setInterval(fetchStatus, 1000);
    return () => clearInterval(interval);
  }, [course]);

  const setupDemo = async () => {
    setMessage({ text: "Đang dọn dẹp và thiết lập...", isError: false });
    const current = maxStudents - 1;
    try {
      await axios.post(`${API}/setup`, {
        MaLop: course,
        SiSoToiDa: maxStudents,
        SiSoHienTai: current,
      });
      setMessage({
        text: `Reset thành công! Hiện tại: ${current}/${maxStudents}`,
        isError: false,
      });
      fetchStatus();
    } catch (err) {
      setMessage({ text: "Lỗi thiết lập hệ thống", isError: true });
    }
  };

  const registerCourse = async (path) => {
    setMessage({ text: "Đang gửi yêu cầu...", isError: false });
    try {
      const res = await axios.post(`${API}${path}`, { MaLop: course });
      setMessage({ text: res.data, isError: false });
    } catch (err) {
      setMessage({
        text: err.response ? err.response.data : "Lỗi kết nối",
        isError: true,
      });
    }
    fetchStatus();
  };

  const percent =
    status.SiSoToiDa > 0 ? (status.SiSoHienTai / status.SiSoToiDa) * 100 : 0;
  const isOverloaded = status.SiSoHienTai > status.SiSoToiDa;

  return (
    <div style={styles.container}>
      <h2 style={styles.header}>Giám Sát Đăng Ký Học Phần</h2>

      <div style={styles.setupCard}>
        <select
          style={styles.input}
          value={course}
          onChange={(e) => setCourse(e.target.value)}
        >
          <option value="101">Lập trình Backend chuyên sâu</option>
          <option value="102">Kiến trúc cơ sở dữ liệu</option>
        </select>
        <input
          style={styles.inputNum}
          type="number"
          value={maxStudents}
          onChange={(e) => setMaxStudents(parseInt(e.target.value))}
        />
        <button style={styles.btnSetup} onClick={setupDemo}>
          Thiết lập (Reset)
        </button>
      </div>

      <div style={styles.monitorCard}>
        <div
          style={{
            ...styles.counter,
            color: isOverloaded ? "#e63946" : "#1d3557",
          }}
        >
          {status.SiSoHienTai} <span style={styles.counterDivider}>/</span>{" "}
          {status.SiSoToiDa}
        </div>

        <div style={styles.progressBarBg}>
          <div
            style={{
              ...styles.progressBarFill,
              width: `${Math.min(percent, 100)}%`,
              backgroundColor: isOverloaded ? "#e63946" : "#2a9d8f",
            }}
          ></div>
        </div>

        <div
          style={{
            ...styles.message,
            color: message.isError ? "#e63946" : "#457b9d",
          }}
        >
          {message.text}
        </div>
      </div>

      <div style={styles.actionArea}>
        <button
          style={styles.btnActionBad}
          onClick={() => registerCourse("/register-bad")}
        >
          Thực thi (No T-SQL)
        </button>
        <button
          style={styles.btnActionGood}
          onClick={() => registerCourse("/register-good")}
        >
          Thực thi (With T-SQL)
        </button>
      </div>
    </div>
  );
}

// ... Giữ nguyên phần styles của bạn ...
export default App;

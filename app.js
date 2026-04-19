import React, { useState, useEffect } from "react";
import axios from "axios";

function App() {
  const [lop, setLop] = useState({ SiSoHienTai: 0, SiSoToiDa: 0 });
  const [msg, setMsg] = useState("");

  const refresh = () =>
    axios.get("http://localhost:5000/status").then((r) => setLop(r.data));
  useEffect(() => {
    refresh();
  }, []);

  const runTest = async (path) => {
    setMsg("Đang xử lý...");
    try {
      const res = await axios.post(`http://localhost:5000${path}`);
      setMsg(res.data);
    } catch (e) {
      setMsg(e.response?.data || "Lỗi kết nối");
    }
    refresh();
  };

  return (
    <div
      style={{
        padding: "50px",
        textAlign: "center",
        backgroundColor: "#1a202c",
        color: "white",
        minHeight: "100vh",
      }}
    >
      <h1>Demo T-SQL vs No T-SQL</h1>
      <div
        style={{
          fontSize: "4rem",
          margin: "20px",
          color: lop.SiSoHienTai > lop.SiSoToiDa ? "red" : "#4fd1c5",
        }}
      >
        {lop.SiSoHienTai} / {lop.SiSoToiDa}
      </div>
      <p>{msg}</p>
      <button
        onClick={() => runTest("/register-bad")}
        style={{
          background: "red",
          color: "white",
          padding: "15px",
          marginRight: "10px",
        }}
      >
        Đăng ký (No T-SQL - Dễ lỗi)
      </button>
      <button
        onClick={() => runTest("/register-good")}
        style={{ background: "green", color: "white", padding: "15px" }}
      >
        Đăng ký (With T-SQL - An toàn)
      </button>
      <div style={{ marginTop: "20px" }}>
        <button
          onClick={() => {
            axios.post("http://localhost:5000/reset");
            refresh();
          }}
        >
          Reset Dữ Liệu
        </button>
      </div>
    </div>
  );
}
export default App;

USE University;
GO

-- 1. Dọn dẹp cấu trúc cũ để tránh xung đột
IF OBJECT_ID('NhatKyHeThong', 'U') IS NOT NULL DROP TABLE NhatKyHeThong;
IF OBJECT_ID('ChiTietDangKy', 'U') IS NOT NULL DROP TABLE ChiTietDangKy;
IF OBJECT_ID('SinhVien', 'U') IS NOT NULL DROP TABLE SinhVien;
IF OBJECT_ID('LopHoc', 'U') IS NOT NULL DROP TABLE LopHoc;
GO

-- 2. Tạo bảng hệ thống
CREATE TABLE LopHoc (
    MaLop INT PRIMARY KEY,
    TenMonHoc NVARCHAR(100),
    SiToiDa INT,
    SiSoHienTai INT DEFAULT 0
);

CREATE TABLE SinhVien (
    MaSV INT PRIMARY KEY,
    TenSV NVARCHAR(50),
    TrangThai NVARCHAR(20) -- 'BinhThuong' hoặc 'NoHocPhi'
);

CREATE TABLE ChiTietDangKy (
    MaSV INT, MaLop INT,
    NgayDangKy DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (MaSV, MaLop)
);

CREATE TABLE NhatKyHeThong (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    NoiDung NVARCHAR(MAX),
    ThoiGian DATETIME DEFAULT GETDATE()
);
GO

-- 3. CHÈN DỮ LIỆU MẪU CHO TẤT CẢ 10 MÔN HỌC (Fix lỗi undefined)
INSERT INTO LopHoc (MaLop, TenMonHoc, SiToiDa, SiSoHienTai) VALUES 
(101, N'Lập trình Hướng đối tượng (OOP)', 50, 0),
(102, N'Cấu trúc dữ liệu & Giải thuật', 50, 0),
(103, N'Cơ sở dữ liệu (Database)', 50, 0),
(104, N'Mạng máy tính', 50, 0),
(105, N'Hệ điều hành', 50, 0),
(106, N'Lập trình Web Frontend', 50, 0),
(107, N'Lập trình Web Backend', 50, 0),
(108, N'Trí tuệ nhân tạo (AI)', 50, 0),
(109, N'An toàn thông tin', 50, 0),
(110, N'Phân tích thiết kế hệ thống', 50, 0);

-- Chèn sinh viên mẫu
INSERT INTO SinhVien VALUES (1, N'Văn Kha', 'BinhThuong'), (2, N'Học viên nợ phí', 'NoHocPhi');
GO

-- 4. [T-SQL] FUNCTION: Kiểm tra điều kiện học phí
CREATE OR ALTER FUNCTION fn_CheckHocPhi (@MaSV INT)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @Status NVARCHAR(20);
    SELECT @Status = TrangThai FROM SinhVien WHERE MaSV = @MaSV;
    RETURN ISNULL(@Status, 'BinhThuong');
END;
GO

-- 5. [T-SQL] TRIGGER: Tự động ghi nhật ký hệ thống
-- Tác dụng: Chứng minh tính tự động hóa ngầm của Database
CREATE OR ALTER TRIGGER trg_AfterRegistration
ON ChiTietDangKy AFTER INSERT AS
BEGIN
    INSERT INTO NhatKyHeThong (NoiDung)
    SELECT CONCAT(N'HỆ THỐNG: SV ', MaSV, N' ghi danh thành công môn học ', MaLop)
    FROM inserted;
END;
GO

-- 6. [T-SQL] STORED PROCEDURE: Bộ não xử lý nghiệp vụ
-- Tác dụng: Dùng Variable, Logic IF/ELSE và đặc biệt là TRANSACTION + LOCK
CREATE OR ALTER PROCEDURE sp_XuLyDangKyHocPhan
    @MaSV INT, @MaLop INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @CurrentStatus NVARCHAR(20);
    
    -- Dùng biến để lấy trạng thái từ hàm
    SET @CurrentStatus = dbo.fn_CheckHocPhi(@MaSV);

    -- IF/ELSE điều khiển luồng
    IF (@CurrentStatus = 'NoHocPhi')
    BEGIN
        SELECT 'LOCKED' AS Status, N'Lỗi: SV nợ phí, T-SQL chặn đăng ký!' AS Msg;
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Khóa dòng (UPDLOCK) để giải quyết tranh chấp (Race Condition)
        IF (SELECT SiSoHienTai FROM LopHoc WITH (UPDLOCK) WHERE MaLop = @MaLop) < 
           (SELECT SiToiDa FROM LopHoc WHERE MaLop = @MaLop)
        BEGIN
            WAITFOR DELAY '00:00:02'; -- Giả lập hệ thống xử lý nặng để demo
            
            UPDATE LopHoc SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLop = @MaLop;
            INSERT INTO ChiTietDangKy (MaSV, MaLop) VALUES (@MaSV, @MaLop);

            COMMIT TRANSACTION;
            SELECT 'SUCCESS' AS Status, N'Đăng ký môn học thành công!' AS Msg;
        END
        ELSE
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'FULL' AS Status, N'Lỗi: Lớp đã đầy sỉ số!' AS Msg;
        END
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'ERROR' AS Status, ERROR_MESSAGE() AS Msg;
    END CATCH
END;
-- 1. Tạo lại Database từ đầu
USE master;
GO
IF EXISTS (SELECT * FROM sys.databases WHERE name = 'University')
BEGIN
    ALTER DATABASE University SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE University;
END
GO
CREATE DATABASE University;
GO
USE University;
GO

-- 2. Tạo bảng Lớp Học (Chứa 10 môn IT)
CREATE TABLE LopHoc (
    MaLop INT PRIMARY KEY,
    TenMonHoc NVARCHAR(100),
    SiSoToiDa INT,
    SiSoHienTai INT DEFAULT 0
);

-- 3. Tạo bảng Sinh Viên (Demo Function/Variable)
CREATE TABLE SinhVien (
    MaSV INT PRIMARY KEY,
    TenSV NVARCHAR(50),
    TrangThai NVARCHAR(20) -- 'BinhThuong' hoặc 'NoHocPhi'
);

-- 4. Tạo bảng Chi Tiết Đăng Ký
CREATE TABLE ChiTietDangKy (
    MaSV INT,
    MaLop INT,
    NgayDangKy DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (MaSV, MaLop)
);

-- 5. Tạo bảng Nhật Ký Hệ Thống (Demo Trigger)
CREATE TABLE NhatKyHeThong (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    NoiDung NVARCHAR(MAX),
    ThoiGian DATETIME DEFAULT GETDATE()
);
GO

-- 6. Chèn dữ liệu mẫu cho 10 môn IT
INSERT INTO LopHoc (MaLop, TenMonHoc, SiSoToiDa, SiSoHienTai) VALUES 
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

INSERT INTO SinhVien VALUES (1, N'Huỳnh Văn Kha', 'BinhThuong'), (2, N'Học viên nợ phí', 'NoHocPhi');
GO

-- 7. T-SQL FUNCTION: Kiểm tra học phí
CREATE OR ALTER FUNCTION fn_CheckHocPhi (@MaSV INT)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @Status NVARCHAR(20);
    SELECT @Status = TrangThai FROM SinhVien WHERE MaSV = @MaSV;
    RETURN ISNULL(@Status, 'BinhThuong');
END;
GO

-- 8. T-SQL TRIGGER: Tự động ghi nhật ký (Camera giám sát)
CREATE OR ALTER TRIGGER trg_AfterRegistration
ON ChiTietDangKy AFTER INSERT AS
BEGIN
    INSERT INTO NhatKyHeThong (NoiDung)
    SELECT CONCAT(N'HỆ THỐNG: SV ', MaSV, N' đã ghi danh môn ', MaLop, N' thành công qua T-SQL.')
    FROM inserted;
END;
GO

-- 9. T-SQL PROCEDURE: Xử lý đăng ký (Transaction + Lock + Variable)
CREATE OR ALTER PROCEDURE sp_XuLyDangKyHocPhan
    @MaSV INT, @MaLop INT
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @TinhTrang NVARCHAR(20);
    
    -- Dùng Variable và Function để check điều kiện
    SET @TinhTrang = dbo.fn_CheckHocPhi(@MaSV);

    IF (@TinhTrang = 'NoHocPhi')
    BEGIN
        SELECT 'LOCKED' AS Status, N'Lỗi: Sinh viên chưa hoàn thành học phí!' AS Msg;
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Khóa dòng dữ liệu (UPDLOCK) để chống Race Condition
        IF (SELECT SiSoHienTai FROM LopHoc WITH (UPDLOCK) WHERE MaLop = @MaLop) < 
           (SELECT SiSoToiDa FROM LopHoc WHERE MaLop = @MaLop)
        BEGIN
            WAITFOR DELAY '00:00:02'; -- Giả lập xử lý để demo tranh chấp
            UPDATE LopHoc SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLop = @MaLop;
            INSERT INTO ChiTietDangKy (MaSV, MaLop) VALUES (@MaSV, @MaLop);

            COMMIT TRANSACTION;
            SELECT 'SUCCESS' AS Status, N'Đăng ký thành công!' AS Msg;
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
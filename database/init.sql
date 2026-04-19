USE master;
GO
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'University')
BEGIN
    CREATE DATABASE University;
END
GO
USE University;
GO

-- Xóa bảng cũ nếu có để làm sạch dữ liệu
IF OBJECT_ID('LopHoc', 'U') IS NOT NULL DROP TABLE LopHoc;
GO

CREATE TABLE LopHoc (
    MaLop INT PRIMARY KEY,
    TenMonHoc NVARCHAR(100),
    SiSoToiDa INT,
    SiSoHienTai INT DEFAULT 0
);

-- Khởi tạo: Lớp có 5 chỗ, hiện tại đã có 4 người
INSERT INTO LopHoc (MaLop, TenMonHoc, SiSoToiDa, SiSoHienTai) 
VALUES (101, N'Lập trình Backend chuyên sâu', 5, 4);
GO

-- Procedure xử lý Đăng ký an toàn
CREATE OR ALTER PROCEDURE sp_DangKyHocPhan
    @MaSV INT,
    @MaLop INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Khóa dòng dữ liệu để tránh các request khác xen vào
        IF (SELECT SiSoHienTai FROM LopHoc WITH (UPDLOCK) WHERE MaLop = @MaLop) < 
           (SELECT SiSoToiDa FROM LopHoc WHERE MaLop = @MaLop)
        BEGIN
            WAITFOR DELAY '00:00:02'; -- Giả lập xử lý nặng để thấy sự xếp hàng
            UPDATE LopHoc SET SiSoHienTai = SiSoHienTai + 1 WHERE MaLop = @MaLop;
            COMMIT TRANSACTION;
            SELECT 'SUCCESS' AS Status;
        END
        ELSE
        BEGIN
            ROLLBACK TRANSACTION;
            SELECT 'FULL' AS Status;
        END
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT 'ERROR' AS Status;
    END CATCH
END;
GO
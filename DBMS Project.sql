

CREATE DATABASE StarFumesDB;
GO
USE StarFumesDB;
GO

-- =========================
-- TABLES
-- =========================

CREATE TABLE Customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    name VARCHAR(100),
    address VARCHAR(200)
);

CREATE TABLE Perfumes (
    perfume_id INT IDENTITY(1,1) PRIMARY KEY,
    perfume_name VARCHAR(100),
    price DECIMAL(10,2),
    stock INT
);

CREATE TABLE Orders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    order_date DATE,
    status VARCHAR(50),
    shipping_address VARCHAR(200),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);

CREATE TABLE OrderItems (
    item_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT,
    perfume_id INT,
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (perfume_id) REFERENCES Perfumes(perfume_id)
);

CREATE TABLE Payments (
    payment_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT,
    amount DECIMAL(10,2),
    payment_method VARCHAR(50),
    payment_status VARCHAR(50),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id)
);
GO

-- DATA INSERTION
INSERT INTO Customers (name, address) VALUES
('Faizan Punjwani', 'Karachi'),
('Yusra Habib', 'Islamabad'),
('Romesa Aleem', 'Lahore'),
('Hanzala Farooqi', 'Rawalpindi'),
('Shiza Hussain', 'Multan'),
('Anabiya Asif', 'Hyderabad'),
('Umm-e-Hani', 'Karachi'),
('Sufyan Safdar', 'Quetta'),
('Ahmed Aleem', 'Peshawar'),
('Ammar Javed', 'Faisalabad'),
('Sanadeed Khan', 'Sargodha'),
('Abdullah Malik', 'Gujranwala');

INSERT INTO Perfumes (perfume_name, price, stock) VALUES
('Sirius Essence', 3500, 20),
('Vega Bloom', 3200, 18),
('Polaris Mist', 4000, 15),
('Rigel Musk', 3700, 12),
('Betelgeuse Night', 4500, 10),
('Altair Breeze', 2800, 25),
('Aldebaran Rose', 3000, 22),
('Deneb Aura', 3300, 18),
('Capella Gold', 3600, 20),
('Antares Oud', 4000, 15);

INSERT INTO Orders (customer_id, order_date, status, shipping_address) VALUES
(1, '2025-11-01', 'Confirmed', 'Karachi'),
(2, '2025-11-02', 'Pending', 'Islamabad'),
(3, '2025-11-03', 'Shipped', 'Lahore'),
(4, '2025-11-04', 'Delivered', 'Rawalpindi'),
(5, '2025-11-05', 'Confirmed', 'Multan'),
(6, '2025-11-06', 'Pending', 'Hyderabad'),
(7, '2025-11-07', 'Shipped', 'Karachi'),
(8, '2025-11-08', 'Delivered', 'Quetta'),
(9, '2025-11-09', 'Confirmed', 'Peshawar'),
(10, '2025-11-10', 'Pending', 'Faisalabad'),
(11, '2025-11-11', 'Shipped', 'Sargodha'),
(12, '2025-11-12', 'Delivered', 'Gujranwala');

INSERT INTO OrderItems (order_id, perfume_id, quantity) VALUES
(1, 1, 2),
(1, 2, 1),
(2, 3, 1),
(2, 4, 2),
(3, 5, 1),
(4, 1, 1),
(5, 6, 2),
(6, 7, 1),
(7, 8, 1),
(8, 9, 1),
(9, 2, 2),
(10, 3, 1),
(11, 4, 2),
(12, 5, 1);

INSERT INTO Payments (order_id, amount, payment_method, payment_status) VALUES
(1, 7100, 'Bank Transfer', 'Completed'),
(2, 5000, 'Cash on Delivery', 'Pending'),
(3, 1500, 'Credit Card', 'Completed'),
(4, 3500, 'Bank Transfer', 'Completed'),
(5, 6400, 'Credit Card', 'Completed'),
(6, 2200, 'Cash on Delivery', 'Pending'),
(7, 3000, 'Bank Transfer', 'Completed'),
(8, 4500, 'Debit Card', 'Completed'),
(9, 3600, 'Cash on Delivery', 'Completed'),
(10, 2500, 'Bank Transfer', 'Pending'),
(11, 5000, 'Credit Card', 'Completed'),
(12, 1500, 'Cash on Delivery', 'Completed');
GO

-- TRIGGERS

-- Prevent insufficient stock
CREATE TRIGGER trg_CheckStock1
ON OrderItems
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Perfumes p ON i.perfume_id = p.perfume_id
        WHERE i.quantity > p.stock
    )
    BEGIN
        RAISERROR ('Insufficient stock available.',16,1);
        RETURN;
    END

    INSERT INTO OrderItems (order_id, perfume_id, quantity)
    SELECT order_id, perfume_id, quantity FROM inserted;
END;
GO

-- Reduce stock automatically
CREATE TRIGGER trg_ReduceStock
ON OrderItems
AFTER INSERT
AS
BEGIN
    UPDATE p
    SET p.stock = p.stock - i.quantity
    FROM Perfumes p
    JOIN inserted i ON p.perfume_id = i.perfume_id;
END;
GO

-- Auto update order status after payment
CREATE TRIGGER trg_UpdateOrderStatus
ON Payments
AFTER INSERT
AS
BEGIN
    UPDATE o
    SET o.status = 'Confirmed'
    FROM Orders o
    JOIN inserted i ON o.order_id = i.order_id
    WHERE i.payment_status = 'Completed';
END;
GO

-- =========================
-- VIEWS
-- =========================

CREATE VIEW vw_CustomerOrderHistory AS
SELECT 
    c.name AS CustomerName,
    o.order_id,
    o.order_date,
    o.status,
    p.perfume_name,
    oi.quantity
FROM Customers c
JOIN Orders o ON c.customer_id = o.customer_id
JOIN OrderItems oi ON o.order_id = oi.order_id
JOIN Perfumes p ON oi.perfume_id = p.perfume_id;
GO

CREATE VIEW vw_DailySales AS
SELECT 
    o.order_date,
    SUM(pm.amount) AS TotalSales
FROM Orders o
JOIN Payments pm ON o.order_id = pm.order_id
WHERE pm.payment_status = 'Completed'
GROUP BY o.order_date;
GO

CREATE VIEW vw_PendingPayments AS
SELECT 
    o.order_id,
    c.name AS CustomerName,
    pm.amount,
    pm.payment_method,
    pm.payment_status
FROM Orders o
JOIN Customers c ON o.customer_id = c.customer_id
JOIN Payments pm ON o.order_id = pm.order_id
WHERE pm.payment_status = 'Pending';
GO

CREATE VIEW vw_LowStockPerfumes AS
SELECT perfume_name, stock
FROM Perfumes
WHERE stock < 5;
GO

SELECT * FROM vw_CustomerOrderHistory;
SELECT * FROM vw_DailySales;
SELECT * FROM vw_PendingPayments;
SELECT * FROM vw_LowStockPerfumes;

UPDATE Perfumes
SET stock = 4
WHERE perfume_id = 1;

--Trigger 1 – Prevent Insufficient Stock
SELECT perfume_name, stock
FROM Perfumes
WHERE perfume_id = 1;

INSERT INTO OrderItems (order_id, perfume_id, quantity)
VALUES (1, 1, 10);

--Trigger 2 – Automatic Stock Reduction
SELECT perfume_name, stock
FROM Perfumes
WHERE perfume_id = 2;

INSERT INTO OrderItems (order_id, perfume_id, quantity)
VALUES (1, 2, 2);

SELECT perfume_name, stock
FROM Perfumes
WHERE perfume_id = 2;

--Trigger 3 – Auto Order Confirmation
SELECT order_id, status
FROM Orders
WHERE order_id = 2;

INSERT INTO Payments (order_id, amount, payment_method, payment_status)
VALUES (2, 5000, 'Credit Card', 'Completed');

SELECT order_id, status
FROM Orders
WHERE order_id = 2;


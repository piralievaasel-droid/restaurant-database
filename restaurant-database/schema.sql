SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS reviews, order_promos, deliveries, payments, order_items, orders,
menu_items, menu_categories, restaurant_addresses, promo_codes, restaurants, users;
SET FOREIGN_KEY_CHECKS = 1;

-- USERS
CREATE TABLE users (
    user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    role ENUM('client','courier','admin') NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    phone VARCHAR(20) UNIQUE,
    email VARCHAR(120)
);

-- RESTAURANTS
CREATE TABLE restaurants (
    restaurant_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(150) NOT NULL,
    rating_avg DECIMAL(3,2) DEFAULT 0
);

CREATE TABLE restaurant_addresses (
    address_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    restaurant_id BIGINT UNSIGNED,
    city VARCHAR(80),
    street VARCHAR(120),
    house VARCHAR(20),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE
);

CREATE TABLE menu_categories (
    category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    restaurant_id BIGINT UNSIGNED,
    name VARCHAR(120),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id) ON DELETE CASCADE
);

CREATE TABLE menu_items (
    item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT UNSIGNED,
    name VARCHAR(150),
    price DECIMAL(10,2),
    is_available TINYINT DEFAULT 1,
    FOREIGN KEY (category_id) REFERENCES menu_categories(category_id) ON DELETE CASCADE
);

CREATE TABLE orders (
    order_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    client_id BIGINT UNSIGNED,
    restaurant_id BIGINT UNSIGNED,
    status ENUM('created','paid','assigned','picked_up','delivered','cancelled'),
    delivery_address VARCHAR(255),
    subtotal_amount DECIMAL(10,2),
    discount_amount DECIMAL(10,2),
    total_amount DECIMAL(10,2),
    created_at DATETIME,
    FOREIGN KEY (client_id) REFERENCES users(user_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);

CREATE TABLE order_items (
    order_item_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED,
    item_id BIGINT UNSIGNED,
    qty INT,
    unit_price DECIMAL(10,2),
    line_total DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (item_id) REFERENCES menu_items(item_id)
);

CREATE TABLE payments (
    payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED UNIQUE,
    method ENUM('card','cash','wallet'),
    status ENUM('pending','succeeded','failed'),
    paid_at DATETIME,
    amount DECIMAL(10,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE deliveries (
    delivery_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    order_id BIGINT UNSIGNED UNIQUE,
    courier_id BIGINT UNSIGNED,
    status ENUM('assigned','picked_up','delivered'),
    assigned_at DATETIME,
    delivered_at DATETIME,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (courier_id) REFERENCES users(user_id)
);

CREATE TABLE promo_codes (
    promo_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(30),
    discount_value DECIMAL(10,2)
);

CREATE TABLE order_promos (
    order_id BIGINT UNSIGNED,
    promo_id BIGINT UNSIGNED,
    applied_discount DECIMAL(10,2),
    PRIMARY KEY(order_id,promo_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE CASCADE,
    FOREIGN KEY (promo_id) REFERENCES promo_codes(promo_id)
);

CREATE TABLE reviews (
    review_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    restaurant_id BIGINT UNSIGNED,
    client_id BIGINT UNSIGNED,
    order_id BIGINT UNSIGNED UNIQUE,
    rating INT,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id),
    FOREIGN KEY (client_id) REFERENCES users(user_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- DATA
INSERT INTO users (role,full_name,phone) VALUES
('client','Иван Петров','111'),
('client','Мария Сидорова','222'),
('courier','Курьер 1','333'),
('courier','Курьер 2','444');

INSERT INTO restaurants (name) VALUES ('Пиццерия'),('Суши Бар');

INSERT INTO restaurant_addresses (restaurant_id,city,street,house) VALUES
(1,'Москва','Ленина','1'),
(2,'Москва','Пушкина','2');

INSERT INTO menu_categories (restaurant_id,name) VALUES
(1,'Пицца'),(2,'Роллы');

INSERT INTO menu_items (category_id,name,price) VALUES
(1,'Маргарита',500),(1,'Пепперони',600),
(2,'Филадельфия',700),(2,'Калифорния',650);

-- ORDERS (суммы = реальным позициям)
INSERT INTO orders VALUES
(1,1,1,'delivered','Адрес 1',1100,100,1000,DATE_SUB(NOW(),INTERVAL 2 DAY)),
(2,2,2,'delivered','Адрес 2',700,0,700,DATE_SUB(NOW(),INTERVAL 1 DAY)),
(3,1,1,'created','Адрес 3',500,0,500,NOW());

INSERT INTO order_items (order_id,item_id,qty,unit_price,line_total) VALUES
(1,1,1,500,500),(1,2,1,600,600),
(2,3,1,700,700),
(3,1,1,500,500);

INSERT INTO payments VALUES
(1,1,'card','succeeded',DATE_SUB(NOW(),INTERVAL 2 DAY),1000),
(2,2,'cash','succeeded',DATE_SUB(NOW(),INTERVAL 1 DAY),700);

INSERT INTO deliveries VALUES
(1,1,3,'delivered',DATE_SUB(NOW(),INTERVAL 2 DAY),DATE_SUB(NOW(),INTERVAL 2 DAY)+INTERVAL 40 MINUTE),
(2,2,4,'delivered',DATE_SUB(NOW(),INTERVAL 1 DAY),DATE_SUB(NOW(),INTERVAL 1 DAY)+INTERVAL 50 MINUTE);

INSERT INTO promo_codes (code,discount_value) VALUES ('SALE100',100);
INSERT INTO order_promos VALUES (1,1,100);

INSERT INTO reviews (restaurant_id,client_id,order_id,rating) VALUES
(1,1,1,5),(2,2,2,4);

SET SQL_SAFE_UPDATES = 0;

UPDATE restaurants r SET rating_avg=(SELECT AVG(rating) FROM reviews WHERE restaurant_id=r.restaurant_id);

-- VIEW
CREATE OR REPLACE VIEW v_order_summary AS
SELECT o.order_id,o.status,o.total_amount,o.created_at,
u.full_name AS client,r.name AS restaurant,p.method,d.status AS delivery_status
FROM orders o
LEFT JOIN users u ON o.client_id=u.user_id
LEFT JOIN restaurants r ON o.restaurant_id=r.restaurant_id
LEFT JOIN payments p ON o.order_id=p.order_id
LEFT JOIN deliveries d ON o.order_id=d.order_id;

-- ===== ЗАПРОСЫ =====

SELECT * FROM restaurants ORDER BY rating_avg DESC;
SELECT * FROM v_order_summary;
SELECT * FROM orders WHERE client_id=1;
SELECT mi.name,SUM(oi.qty) total_sold FROM order_items oi JOIN menu_items mi USING(item_id) GROUP BY mi.name;
SELECT r.name,AVG(TIMESTAMPDIFF(MINUTE,p.paid_at,d.delivered_at)) avg_delivery FROM restaurants r JOIN orders o ON r.restaurant_id=o.restaurant_id JOIN payments p ON o.order_id=p.order_id JOIN deliveries d ON o.order_id=d.order_id GROUP BY r.name;
SELECT * FROM orders WHERE status='created';
SELECT u.full_name,COUNT(d.delivery_id) FROM users u LEFT JOIN deliveries d ON u.user_id=d.courier_id WHERE u.role='courier' GROUP BY u.full_name;
SELECT * FROM order_promos;
SELECT * FROM restaurants WHERE rating_avg<4.5;
SELECT restaurant_id,SUM(total_amount) revenue FROM orders WHERE status='delivered' GROUP BY restaurant_id;
SELECT o.order_id,SUM(oi.line_total) calc FROM orders o JOIN order_items oi USING(order_id) GROUP BY o.order_id;
SELECT * FROM users WHERE role='client';

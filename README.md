# Restaurant Database Schema

## Описание
Полная база данных для сервиса доставки еды. Включает:
- Пользователи (клиенты, курьеры, администраторы)
- Рестораны и их адреса
- Меню (категории и позиции)
- Заказы, позиции заказов
- Платежи
- Доставку
- Промокоды
- Отзывы с рейтингами

## ER-диаграмма (все таблицы)

```mermaid
erDiagram
    users {
        bigint user_id PK
        enum role "client/courier/admin"
        varchar full_name
        varchar phone UK
        varchar email
    }

    restaurants {
        bigint restaurant_id PK
        varchar name
        decimal rating_avg
    }

    restaurant_addresses {
        bigint address_id PK
        bigint restaurant_id FK
        varchar city
        varchar street
        varchar house
    }

    menu_categories {
        bigint category_id PK
        bigint restaurant_id FK
        varchar name
    }

    menu_items {
        bigint item_id PK
        bigint category_id FK
        varchar name
        decimal price
        tinyint is_available
    }

    orders {
        bigint order_id PK
        bigint client_id FK
        bigint restaurant_id FK
        enum status "created/paid/assigned/picked_up/delivered/cancelled"
        varchar delivery_address
        decimal subtotal_amount
        decimal discount_amount
        decimal total_amount
        datetime created_at
    }

    order_items {
        bigint order_item_id PK
        bigint order_id FK
        bigint item_id FK
        int qty
        decimal unit_price
        decimal line_total
    }

    payments {
        bigint payment_id PK
        bigint order_id FK
        enum method "card/cash/wallet"
        enum status "pending/succeeded/failed"
        datetime paid_at
        decimal amount
    }

    deliveries {
        bigint delivery_id PK
        bigint order_id FK
        bigint courier_id FK
        enum status "assigned/picked_up/delivered"
        datetime assigned_at
        datetime delivered_at
    }

    promo_codes {
        bigint promo_id PK
        varchar code
        decimal discount_value
    }

    order_promos {
        bigint order_id PK
        bigint promo_id PK
        decimal applied_discount
    }

    reviews {
        bigint review_id PK
        bigint restaurant_id FK
        bigint client_id FK
        bigint order_id FK
        int rating
    }

    %% Связи
    restaurants ||--o{ restaurant_addresses : "имеет"
    restaurants ||--o{ menu_categories : "содержит"
    menu_categories ||--o{ menu_items : "включает"
    users ||--o{ orders : "создаёт (client)"
    restaurants ||--o{ orders : "принимает"
    orders ||--|{ order_items : "состоит из"
    menu_items ||--o{ order_items : "ссылается"
    orders ||--|| payments : "имеет"
    orders ||--|| deliveries : "имеет"
    users ||--o{ deliveries : "выполняет (courier)"
    orders ||--o{ order_promos : "применяет"
    promo_codes ||--o{ order_promos : "используется в"
    restaurants ||--o{ reviews : "получает"
    users ||--o{ reviews : "пишет (client)"
    orders ||--|| reviews : "оценивается"

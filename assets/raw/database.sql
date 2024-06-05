create table if not exists Cart (
    cart_id integer primary key autoincrement,
    product_id integer,
    quantity integer default 1,
    sale_price real,
    notes text,
    customer_id integer,
    productData text
);

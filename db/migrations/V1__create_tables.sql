-- Order matters: a table must exist before another table can
-- add a FOREIGN KEY pointing at it.
-- Category -> Product -> User -> Customer -> Order -> Order_item

CREATE TABLE [Category](
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) UNIQUE NOT NULL,
    description NVARCHAR(100) NOT NULL
);

CREATE TABLE [Product](
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) UNIQUE NOT NULL,
    price DECIMAL NOT NULL,
    stock INT NOT NULL,
    description NVARCHAR(100) NOT NULL,
    image NVARCHAR(100) NOT NULL,
    category_id INT FOREIGN KEY REFERENCES [Category](id)
);

CREATE TABLE [User](
    id INT IDENTITY(1,1) PRIMARY KEY,
    username NVARCHAR(100) UNIQUE NOT NULL,
    password NVARCHAR(100) NOT NULL,
    role NVARCHAR(100) NOT NULL
);

CREATE TABLE [Customer](
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) UNIQUE NOT NULL,
    email NVARCHAR(100) NOT NULL,
    address NVARCHAR(100) NOT NULL,
    phone NVARCHAR(100) NOT NULL,
    user_id INT FOREIGN KEY REFERENCES [User](id)
);

CREATE TABLE [Order](
    id INT IDENTITY(1,1) PRIMARY KEY,
    status NVARCHAR(100) NOT NULL,
    order_date DATE NOT NULL,
    total_amount DECIMAL NOT NULL,
    customer_id INT FOREIGN KEY REFERENCES [Customer](id)
);

CREATE TABLE [Order_item](
    id INT IDENTITY(1,1) PRIMARY KEY,
    price DECIMAL NOT NULL,
    quantity INT NOT NULL,
    order_id INT FOREIGN KEY REFERENCES [Order](id),
    product_id INT FOREIGN KEY REFERENCES [Product](id)
);

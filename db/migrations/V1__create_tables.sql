Create table [User](
        id INT identity(1,1) primary key,
        username Nvarchar(100) unique not null,
        password Nvarchar(100) not null,
        role nvarchar(100) not null
);


Create table Customer(

        id INT identity(1,1) primary key,
        name Nvarchar(100) unique not null,
        email Nvarchar(100) not null,
        address nvarchar(100) not null,
        phone nvarchar(100) not null,
        user_id int foreign key references [User](id)



);

Create table [Order](


        id INT identity(1,1) primary key,
        status Nvarchar(100) unique not null,
        order_Date date not null,
        total_amount decimal not null,
        customer_id int foreign key references [customer](id)
)

Create table [Order_item](


        id INT identity(1,1) primary key,
        price decimal not null,
        quantity int  not null,
        order_id int foreign key references [Order](id),
        product_id int foreign key references [Product](id)
)



Create table [Product](

        id INT identity(1,1) primary key,
        name Nvarchar(100) unique not null,
        price decimal not null,
        stock int not null,
        description nvarchar(100) not null,
        image nvarchar(100) not null,
        category_id int foreign key references [Category](id)

)

Create table [Category](

        id INT identity(1,1) primary key,
        name Nvarchar(100) unique not null,
        description nvarchar(100) not null
)
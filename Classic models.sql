use mintclassics;
show tables;

-- 1.How many orders have been placed till now?
select count(*) as total_orders from orders;
-- 326 orders have been placed.

-- 2.Distinct status in orders
select distinct(status) from orders;

-- 3.Total order amount groupby y by order no.
select * from orderdetails; 
select ordernumber,sum(quantityordered*priceeach) as total_amount from orderdetails
group by ordernumber
order by total_amount desc;
-- Order number 10165 is the most valued order at 67,392.85

-- 4.What are the different productlines available?
select count(distinct(productline)) from products;
select distinct(productline) from products;

-- 5.Quantity in each warehouse
select warehousecode,sum(quantityinstock) as quantityinstock from products
group by warehousecode
order by quantityinstock desc;
-- Warehouse b has the highest quantity available.

-- 6.Distinct productlines kept in different warehouses
select distinct(productline) from products
where warehousecode="a";

-- 7.Is there a relationship between product prices and their sales levels?
select p.productcode,p.productname,p.buyprice,sum(od.quantityordered) as totalordered
from products as p
left join orderdetails as od
on p.productcode=od.productcode
group by p.productcode,p.productname,p.buyprice
order by totalordered desc;

-- 8.Which customers are contributing the most to sales?
select c.customernumber,c.customername,count(o.ordernumber) as total_sales
from customers as c
inner join orders as o
on c.customernumber=o.customernumber
group by c.customernumber,c.customername
order by total_sales desc;
-- Euro+Shopping Channel us the most contributing customer to mints model company.

-- 9.List out the sales performance of employees? 
select e.employeenumber,e.firstname,e.lastname,e.jobtitle,sum(od.quantityordered*priceeach) as total_sales
from employees as e
left join customers as c on e.employeenumber=c.salesrepemployeenumber
left join orders as o on c.customernumber=o.customernumber
left join orderdetails as od on o.ordernumber=od.ordernumber
where e.jobtitle="Sales Rep"
group by e.employeenumber,e.firstname,e.lastname,e.jobtitle
order by total_sales desc;
-- Gerard Hernandez is the best salesperson till date. 

-- 10.How can the performance of various product lines be compared?
select p.productline,sum(p.quantityinstock) as totalinventory,
sum(od.quantityordered) as totalsales,
sum(od.priceeach*od.quantityordered) as totalrevenue,
(sum(od.quantityordered)/sum(p.quantityinstock))*100 as salesinventorypercentage
from products as p
left join orderdetails as od
on p.productcode=od.productcode
group by p.productline
order by salesinventorypercentage desc;

-- 11.How many products does the company have?
select count(*)
from products;

select count(distinct(productcode))
from products;
-- The company currently holds a diverse inventory of 110 distinct products.

-- 12.Identify unique product count and their total stock in each warehouse
select p.warehouseCode, w.warehouseName,count(productCode) as total_product,sum(p.quantityInStock) as total_stock
from products as p 
join warehouses as w 
on p.warehouseCode = w.warehouseCode
group by w.warehouseCode, w.warehouseName
order by total_stock desc;
-- Warehouse B holds 38 different product having a total stock of 219,183, making it the most stocked warehouse.

-- 13.Identify what product line each warehouse stored
select p.warehouseCode, w.warehouseName,p.productLine,count(productCode) as total_product, sum(p.quantityInStock) as total_stock
from products as p 
join warehouses as w on p.warehouseCode = w.warehouseCode
group by w.warehouseCode, w.warehouseName, p.productLine;

-- Product and Inventory Analysis

-- Here we are creating a temporary table to identify Understocked,Well-stocked,Overstocked items.
create temporary table inventory_summary as(
 select p.warehouseCode as warehouseCode,p.productCode as productCode,p.productName as productName,p.quantityInStock as quantityInStock,
  sum(od.quantityOrdered) as total_ordered,
  p.quantityInStock - sum(od.quantityOrdered) as remaining_stock,
  case 
   when (p.quantityInStock - sum(od.quantityOrdered)) > (2 * SUM(od.quantityOrdered)) then 'Overstocked'
   when (p.quantityInStock - sum(od.quantityOrdered)) < 650 then 'Understocked'
   else 'Well-Stocked'
  end as inventory_status
 from products as p
 join orderdetails as od on p.productCode = od.productCode
 join orders o on od.orderNumber = o.orderNumber
 where o.status in ('Shipped', 'Resolved')
 group by p.warehouseCode,p.productCode,p.quantityInStock
 order by remaining_stock desc
);

select * from inventory_summary;

-- This table now shows us which items are Overstocked,Wellstocked or Understocked.

select count(*) from inventory_summary;
-- The new table only contains 109 products whereas our actual table contains 110 products which means 1 product has never been ordered.

-- 14.Find out which product has never been ordered?
select p.productCode,p.productName,p.quantityInStock,p.warehouseCode
from products as p
left join inventory_summary as isum 
on p.productCode = isum.productCode
where isum.productCode is null;
-- Toyota supra model stored in Warehouse B has never been ordered.Therefore it must be dropped from the product list.


-- 15.Which warehouse is most overstocked?
select warehouseCode,inventory_status,count(*) as product_count
from inventory_summary
where inventory_status="Overstocked"
group by warehouseCode, inventory_status
order by product_count desc;
-- Warehouse B is the most overstocked

-- 16.How many products are overstocked in total? 
select count(*) as product_overstocked
from (select productCode,productName,remaining_stock,warehouseCode
from inventory_summary
where inventory_status = 'Overstocked'
order by warehouseCode, remaining_stock desc) as os;
-- In total, 78 products are overstocked in the company. 

-- 17.Which warehouse is most understocked?
select warehouseCode,inventory_status,count(*) as product_count
from inventory_summary
where inventory_status="understocked"
group by warehouseCode, inventory_status
order by product_count desc;
-- Warehouse A is the most understocked.

-- 18. How many products are understocked in total?
select count(*) as product_overstocked
from (select productCode,productName,remaining_stock,warehouseCode
from inventory_summary
where inventory_status = 'understocked'
order by warehouseCode, remaining_stock desc) as os;
-- In total, 16 products are understocked in the company.

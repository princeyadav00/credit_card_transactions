--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

with cte1 as
(
select city , sum( amount) as city_total_spend
from credit_card_transcations
group by city
),
total_spend as ( select sum(amount) as total_amount
from credit_card_transcations)
select top 5 city,city_total_spend,round((city_total_spend * 100/(select total_amount from total_spend)),0) as percentage_contribution
from cte1
order by city_total_spend desc

--2- write a query to print highest spend month and amount spent in that month for each card type

select card_type, months, total_spend
from
(
select card_type
,format(transaction_date,'yyyy-MM') as months
,sum(amount) as total_spend
,ROW_NUMBER() over (partition by card_type order by sum(amount) desc) as rn
from credit_card_transcations
group by card_type ,format(transaction_date,'yyyy-MM')
) as monthly_spend
where rn =1

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

select * 
from(
select * ,
rank() over (partition by card_type order by cumm_amount ) as rn
from
(
select * ,sum(amount) over ( partition by card_type order by transaction_date,transaction_id) as cumm_amount
from credit_card_transcations
) as A
where cumm_amount >= 1000000) as c
where rn=1

--4- write a query to find city which had lowest percentage spend for gold card type

with cte1 as
(
select city,card_type, sum(amount) as total_spend
from credit_card_transcations
where card_type='gold'
group by city,card_type
),
total_amount as 
(
select sum(amount) as total_amt 
from credit_card_transcations 
where card_type='gold'
)
select top 1 city, card_type, (total_spend*100/(select total_amt from total_amount) )as percent_contribution
from cte1
order by percent_contribution

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with cte1 as
(
select city,exp_type, sum(amount) as total_spend
from credit_card_transcations
group by city,exp_type
),
cte2 as 
(
select *,
rank() over ( partition by city order by total_spend desc) as desc_rn,
rank() over ( partition by city order by total_spend asc) as asc_rn
from cte1
)
select city,
max(case when desc_rn =1 then exp_type end) as highest_exp_type,
max( case when asc_rn =1 then exp_type end) as lowest_exp_type
from cte2
where desc_rn=1 or asc_rn=1
group by city


--6- write a query to find percentage contribution of spends by females for each expense type

select exp_type, sum(amount) as total_amount,
sum(case when gender='f' then amount else 0 end) as female_spend,
sum(case when gender='f' then amount else 0 end)*100/sum(amount) as female_contribution
from credit_card_transcations
group by exp_type
order by female_contribution

--7- which card and expense type combination saw highest month over month growth in Jan-2014

with cte1 as
(
select card_type,exp_type,format(transaction_date,'yyyy-MM') as year_month, sum(amount) as total_amount
from credit_card_transcations
group by card_type,exp_type,format(transaction_date,'yyyy-MM')
)
select top 1 *,(total_amount-prev_mnth_amt)as mom_growth
from(
select *,
lag(total_amount,1) over (partition by card_type,exp_type order by year_month) as prev_mnth_amt
from cte1) as A
where prev_mnth_amt is not null and year_month='2014-01'
order by mom_growth desc

--8- during weekends which city has highest total spend to total no of transcations ratio 

select top 1 city, sum(amount)/count(*) as ratio
from credit_card_transcations
where datepart(weekday,transaction_date) in(1,7)
group by city
order by ratio desc

--9- which city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as
(
select *,
ROW_NUMBER() over ( partition by city order by transaction_date,transaction_id) as rn
from credit_card_transcations
)
select city, max(transaction_date) as last_date, min(transaction_date) as first_date,
datediff(day,min(transaction_date),max(transaction_date)) as no_of_days
from cte
where rn in (1,500)
group by city
having count(*)=2
order by no_of_days asc

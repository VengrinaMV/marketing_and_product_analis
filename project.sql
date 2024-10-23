---task1
WITH first_visit AS 
  (SELECT COUNT(user_id) AS first_visit,
          date_trunc( 'month', date::date) AS year_month
   FROM df_action AS t1
   WHERE action = 'opened'
   GROUP BY date_trunc('month', date::date)
   ),
     add_product AS 
  (SELECT COUNT(DISTINCT user_id) AS add_product,
          date_trunc('month', date::date) AS year_month
   FROM df_action AS t1
   WHERE action = 'added'
   GROUP BY date_trunc('month', date::date)
   ),
     payment_order AS 
  (SELECT COUNT(DISTINCT user_id) AS payment_order,
          date_trunc('month', date::date) AS year_month
   FROM df_action AS t1
   WHERE action = 'purchased'
   GROUP BY date_trunc('month', date::date)
   ),
     all_step AS 
   (SELECT  year_month,
           'first_visit' AS step, 
           first_visit AS cnt
   FROM first_visit
   UNION ALL
   SELECT  year_month,
          'add_product' AS step, 
          add_product AS cnt
   FROM add_product
   UNION ALL
   SELECT  year_month,
          'payment_order' AS step, 
          payment_order AS cnt
   FROM payment_order)
   select year_month,
   		 sum(CASE WHEN step = 'first_visit' THEN cnt ELSE 0 END) AS first_visit,
  		 sum(CASE WHEN step = 'add_product' THEN cnt ELSE 0 END) AS add_product,
   		 sum(CASE WHEN step = 'payment_order' THEN cnt ELSE 0 END) AS payment_order,
   		 round( 100*sum(CASE WHEN step = 'add_product' THEN cnt ELSE 0 END)/sum(CASE WHEN step = 'first_visit' THEN cnt ELSE 0 END),2) as conversion_basket,
   		 round(100*sum(CASE WHEN step = 'payment_order' THEN cnt ELSE 0 END)/sum(CASE WHEN step = 'add_product' THEN cnt ELSE 0 END),2) AS conversion_purchase
   from all_step
group by year_month
   
   
  ---task2
with add_purchase as (select user_id,
                             coalesce(sum(case when action = 'added' then 1 end), 0)     added,
                             coalesce(sum(case when action = 'purchased' then 1 end), 0) purchased
                      from first_class.df_action
                      group by user_id)
select sum(case when added - purchased > 1 then 1 end)                          throwers,
       sum(case when added - purchased = 1 or added - purchased = 0 then 1 end) buyers,
       sum(case when added - purchased < 0 then 1 end)                          check_needed,
       round(sum(purchased) / sum(added) * 100,2)                               car
from add_purchase;


---task3
select channel,
	   round(100*registered/viewed, 2) as ctr
from (select channel,
             sum(CASE WHEN status='viewed' THEN 1 ELSE 0 END)  viewed,
	         sum(CASE WHEN status='registered' THEN 1 ELSE 0 END)  registered
       from df_user_viewed
       group by channel ) as channel_status

--task4
select channel,
		cost/registered as cpc
from (select t1.channel,
             sum(CASE WHEN t1.status='viewed' THEN 1 ELSE 0 END)  viewed,
	         sum(CASE WHEN t1.status='registered' THEN 1 ELSE 0 END)  registered,
	         t2.cost
      from df_user_viewed as t1
      join df_cost t2 on t1.channel =t2.channel 
      group by t1.channel, t2.cost) as channel_cost
 
      
--task5
with profit as
	(select id_transaction,
			amount*expenses as profit
	from first_class.df_transaction),
transaction_channel as 
	(select t1.id_transaction,
		t1.user_id,
		t2.channel
	from first_class.df_action as t1
	join first_class.df_user_viewed as t2 on t1.user_id =t2.user_id),
transaction_profit AS
	(select t3.id_transaction,
			t3.profit,
			t4.channel
	from profit as t3
	join transaction_channel as t4 on t3.id_transaction=t4.id_transaction),
profit_cost as
(select t5.channel,
		sum(profit) as sum_profit,
		t6.cost
from transaction_profit as t5
join first_class.df_cost as t6 on t5.channel=t6.channel
group by t5.channel, t6.cost)
select channel,
		ROUND(100*sum_profit/cost,2) as ROAS
from profit_cost

--task6

select t1.user_id,
		t3.product,
		t3.amount,
		t3.price,
		t3.expenses,
		t3.amount*t3.expenses as profit,
		t2.date,
		t1.country,
		t1.device ,
		t1.source
from  first_class.df_user_our as t1 
join  first_class.df_action as t2 on t1.user_id =t2.user_id 
join first_class.df_transaction as t3 on t2.id_transaction=t3.id_transaction 


date, country, product, device, source
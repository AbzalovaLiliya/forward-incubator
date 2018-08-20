--ДЗ по Лекции №1, Абзалова Лилия

--1.	
Select count(1) as number_of_attempts
From fw_process_log pl
Where pl.n_status = 500 and pl.v_message like '%2520123%';

--2.
Select to_char(DT_TIMESTAMP, 'dd.mon.yyyy'), '2520123' as order_number
From fw_process_log pl
Where pl.n_status = 500 and pl.v_message like '%2520123%';

--3.	
Select  substr(pl.v_message, 35) as order_number
From fw_process_log pl
Where pl.v_message like 'Загрузка порции заказов начиная с %';

--4.	
Select count(count(substr(pl.v_message, 35))) as number_of_orders
From fw_process_log pl
Where pl.v_message like 'Загрузка порции заказов начиная с %'
Group by substr(pl.v_message, 35)
having count(substr(pl.v_message, 35))=1;

--5.	
Select sum(substr(dt_timestamp,-9)) as continuance
From fw_process_log pl
Where pl.v_message like 'Процесс продвижения заказов завершен%'

--6.	
select count(*) as number_of_completed_processes
From fw_process_log pl
where to_char(dt_timestamp, 'mm.yy') = '03.18' and pl.v_message like ' Процесс продвижения заказов завершен%';

--7.	
Select count(count(sid)) as number_of_duplicate_identifiers
From fw_process_log pl
Group by pl.sid
Having count(pl.sid)>1;

--8.	
Select dt_timestamp, OS_USERNAME
From fw_process_log pl
Where pl.ID_USER=11136 and rownum = 1
order by pl.dt_timestamp DESC;


--9.	
Select to_char(dt_timestamp, 'month') as month, count(1)
From fw_process_log pl
group BY to_char(dt_timestamp, 'month');

--10.	
Select count(*) as records_by_conditions, 
    (select count(count(*)) 
    From fw_process_log pl
    Where pl.id_process = 5 and pl.n_status = 500 and pl.dt_timestamp > to_date('22.02.2018') and pl.dt_timestamp < to_date('02.03.2018')
    Group by pl.v_message
    Having count(*) =1 ) as records_by_unique_message
From fw_process_log pl
Where pl.id_process = 5 and pl.n_status = 500 and pl.dt_timestamp > to_date('22.02.2018') and pl.dt_timestamp < to_date('02.03.2018')
Group by pl.v_message;

--11.	
Select min(t.n_sum) as transfer_amount
From fw_transfers t
Where t.dt_incoming >= to_date('14.02.2017 10:00:00','dd.mm.yyyy hh24:mi:ss') and t.dt_incoming <= to_date('14.02.2017 12:00:00','dd.mm.yyyy hh24:mi:ss') and t. ID_CONTRACT_FROM != t. ID_CONTRACT_TO;

--12.	
Select  t.ID_CONTRACT_TO, t.DT_INCOMING, ((length(t. V_DESCRIPTION))-22) as number_of_characters
From fw_transfers t
Where length(t. V_DESCRIPTION)>22
Order by number_of_characters DESC;



13.	
Select to_char(t.DT_INCOMING, 'dd.mm.yyyy') as date_of_transfer, count(*)
From  fw_transfers t
Where t.ID_CONTRACT_FROM = t.ID_CONTRACT_TO
Group by to_char(t.DT_INCOMING, 'dd.mm.yyyy');



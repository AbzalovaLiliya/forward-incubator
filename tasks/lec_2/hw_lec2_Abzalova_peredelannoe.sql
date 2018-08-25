--1.

select d.v_name, table2.total_sum, table2.number_of_payments, table2.number_of_contracts
from fw_departments d
left join 
	(select f.id_department, sum(t.f_sum) as total_sum, count(t.id_trans) as number_of_payments, count(f.id_contract_inst) as number_of_contracts
	from fw_contracts f
	left join trans_external t
	on f.id_contract_inst = t.id_contract
   	and t.dt_event >= trunc(current_timestamp, 'month')
   --and t.dt_event >= TO_DATE('2018-03-01', 'YYYY-MM-DD') and t.dt_event <= TO_DATE('2018-03-31', 'YYYY-MM-DD')  /*для проверки запроса, т.к. в табл последние записи за март*/
   	and t.v_status = 'A' 
	where f.dt_start <= current_timestamp and f.dt_stop > current_timestamp
	group by f.id_department
) table2
on d.id_department = table2.id_department
where d.b_deleted = 0 


--2.

select f.v_ext_ident,f.id_contract_inst, f.v_status, table1.number_of_payments
    from fw_contracts f
    left join 
                (select t.id_contract, count(*) as number_of_payments 
                from trans_external t
                where t.dt_event >= to_date('01.01.2017', 'dd.mm.yyyy')
                and t.dt_event < to_date('01.01.2018', 'dd.mm.yyyy')
                and t.v_status = 'A'
                group by t.id_contract) table1
    on table1.id_contract = f.id_contract_inst            
    where f.dt_start <= current_timestamp and f.dt_stop > current_timestamp
    and 3 < (select count(*)
                from trans_external t
                where t.id_contract = f.id_contract_inst 
                and t.dt_event >= to_date('01.01.2017', 'dd.mm.yyyy')
                and t.dt_event < to_date('01.01.2018', 'dd.mm.yyyy')
		and t.v_status = 'A');


-------------------------------------------------------------------
select f.v_ext_ident, f.v_status, (select count(*)
                from trans_external t
                where t.id_contract = f.id_contract_inst 
                and t.dt_event >= to_date('01.01.2017', 'dd.mm.yyyy')
                and t.dt_event < to_date('01.01.2018', 'dd.mm.yyyy')
		and t.v_status = 'A') as number_of_payments

    from fw_contracts f
    where f.dt_start <= current_timestamp and f.dt_stop > current_timestamp
    and 3 < (select count(*)
                from trans_external t
                where t.id_contract = f.id_contract_inst 
                and t.dt_event >= to_date('01.01.2017', 'dd.mm.yyyy')
                and t.dt_event < to_date('01.01.2018', 'dd.mm.yyyy')
		and t.v_status = 'A') ;


--3.
select table1.v_name 
from (select d.v_name, count(c.id_contract_inst) as number_of_contracts
            from fw_departments d
            left join fw_contracts c
            on d.id_department = c.id_department
            and c.dt_start <= current_timestamp and c.dt_stop > current_timestamp
            where d.b_deleted = 0
            group by d.v_name)  table1
where number_of_contracts = 0;

--4. /*вывожу имя пользователя создавшего последний платеж*/

select fc.v_ext_ident, table2.number_of_payments, table2.date_of_last_payment, table2.v_description
from (select table1.id_contract_inst, table1.number_of_payments, table1.date_of_last_payment,te.id_trans as number_of_last_payment, te.id_manager, ci_users.v_description
            from (select  c.id_contract_inst, count(t.id_trans) as number_of_payments, max(t.dt_event) as date_of_last_payment 
                    from fw_contracts c
                    left join trans_external t
                    on t.id_contract = c.id_contract_inst 
                    and  t.v_status = 'A'
                    where c.dt_start <= current_timestamp and c.dt_stop > current_timestamp
                    group by c.id_contract_inst
                    order by count(t.id_trans) desc) table1
            left join trans_external te
            on te.id_contract = table1.id_contract_inst  and te.dt_event = date_of_last_payment and  te.v_status = 'A'
            left join ci_users 
            on ci_users.id_user = id_manager) table2
            
left join fw_contracts fc
on fc.id_contract_inst = table2.id_contract_inst and fc.dt_start <= current_timestamp and fc.dt_stop > current_timestamp

--5.

select c.id_contract_inst, c.v_ext_ident, c.v_status, currency.v_name   
from (select id_contract_inst,count(distinct id_currency) as currency_count /*ищем контракты у которых менялась валюта*/
        from fw_contracts c
        group by id_contract_inst
        having count(distinct id_currency)>1) table1
join fw_contracts c
on c.id_contract_inst = table1.id_contract_inst
join fw_currency currency
    on currency.id_currency=c.id_currency and currency.b_deleted=0
where c.dt_start <= current_timestamp and c.dt_stop > current_timestamp;


--6.

select c.id_contract_inst, table1.sum_of_activ_payments,  fd.v_name as department, table1.year
from fw_contracts c
left join 
            (select c.id_contract_inst, TO_CHAR(te.dt_event, 'yyyy') as year, sum(te.f_sum) as sum_of_activ_payments
            from fw_contracts c
            left join trans_external te
            on te.id_contract = c.id_contract_inst 
            and te.v_status = 'A'
            where c.dt_start <= current_timestamp and c.dt_stop > current_timestamp
            group by c.id_contract_inst, TO_CHAR(te.dt_event, 'yyyy')
            order by year asc) table1
            
    on c.id_contract_inst = table1.id_contract_inst
    and c.dt_start <= current_timestamp and c.dt_stop > current_timestamp
    left join fw_departments fd
    on fd.id_department = c.id_department
    and fd.b_deleted = 0
    order by table1.year


